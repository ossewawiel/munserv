# Backend Handoff: Issue State History

## Context

Implement audit trail for issue state changes. The database table already exists (`issue_state_history`), but the backend lacks the Kotlin domain/repository/service layer to use it.

## Files to Create

### 1. Domain Layer

**`backend/src/main/kotlin/com/munserv/issues/domain/IssueStateHistoryId.kt`**

```kotlin
package com.munserv.issues.domain

import java.util.UUID

@JvmInline
value class IssueStateHistoryId(val value: UUID) {
    companion object {
        fun generate(): IssueStateHistoryId = IssueStateHistoryId(UUID.randomUUID())
    }
}
```

**`backend/src/main/kotlin/com/munserv/issues/domain/IssueStateHistoryEntry.kt`**

```kotlin
package com.munserv.issues.domain

import com.munserv.shared.types.AdminId
import java.time.Instant

data class IssueStateHistoryEntry(
    val id: IssueStateHistoryId,
    val issueId: IssueId,
    val state: IssueState,
    val changedAt: Instant,
    val changedBy: AdminId?,
    val note: String?,
)
```

### 2. Repository Layer

**`backend/src/main/kotlin/com/munserv/issues/repository/IssueStateHistoryEntity.kt`**

```kotlin
package com.munserv.issues.repository

import com.munserv.issues.domain.IssueId
import com.munserv.issues.domain.IssueState
import com.munserv.issues.domain.IssueStateHistoryEntry
import com.munserv.issues.domain.IssueStateHistoryId
import com.munserv.shared.types.AdminId
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import org.hibernate.annotations.ColumnTransformer
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "issue_state_history")
class IssueStateHistoryEntity(
    @Id
    val id: UUID,
    @Column(name = "issue_id", nullable = false)
    val issueId: UUID,
    @Column(nullable = false, columnDefinition = "issue_state")
    @ColumnTransformer(write = "?::issue_state")
    val state: String,
    @Column(name = "changed_at", nullable = false)
    val changedAt: Instant,
    @Column(name = "changed_by")
    val changedBy: UUID?,
    @Column
    val note: String?,
) {
    fun toDomain(): IssueStateHistoryEntry =
        IssueStateHistoryEntry(
            id = IssueStateHistoryId(id),
            issueId = IssueId(issueId),
            state = IssueState.fromString(state),
            changedAt = changedAt,
            changedBy = changedBy?.let { AdminId(it) },
            note = note,
        )

    companion object {
        fun fromDomain(entry: IssueStateHistoryEntry): IssueStateHistoryEntity =
            IssueStateHistoryEntity(
                id = entry.id.value,
                issueId = entry.issueId.value,
                state = entry.state.toApiString(),
                changedAt = entry.changedAt,
                changedBy = entry.changedBy?.value,
                note = entry.note,
            )
    }
}
```

**`backend/src/main/kotlin/com/munserv/issues/repository/IssueStateHistoryRepository.kt`**

```kotlin
package com.munserv.issues.repository

import com.munserv.issues.domain.IssueId
import com.munserv.issues.domain.IssueStateHistoryEntry
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.util.UUID

interface IssueStateHistoryJpaRepository : JpaRepository<IssueStateHistoryEntity, UUID> {
    fun findByIssueIdOrderByChangedAtAsc(issueId: UUID): List<IssueStateHistoryEntity>
}

interface IssueStateHistoryRepository {
    fun save(entry: IssueStateHistoryEntry): IssueStateHistoryEntry
    fun findByIssueId(issueId: IssueId): List<IssueStateHistoryEntry>
}

@Repository
class JpaIssueStateHistoryRepository(
    private val jpa: IssueStateHistoryJpaRepository,
) : IssueStateHistoryRepository {
    override fun save(entry: IssueStateHistoryEntry): IssueStateHistoryEntry =
        jpa.save(IssueStateHistoryEntity.fromDomain(entry)).toDomain()

    override fun findByIssueId(issueId: IssueId): List<IssueStateHistoryEntry> =
        jpa.findByIssueIdOrderByChangedAtAsc(issueId.value).map { it.toDomain() }
}
```

### 3. API Layer Updates

**`backend/src/main/kotlin/com/munserv/issues/api/IssueResponse.kt`**

Add new DTO:
```kotlin
data class StateHistoryEntryResponse(
    val state: String,
    val changedAt: String,
    val changedBy: String?,
    val note: String?,
)
```

Update `IssueDetailResponse` to include:
```kotlin
val stateHistory: List<StateHistoryEntryResponse>
```

Update `toDetailResponse()` extension:
```kotlin
fun Issue.toDetailResponse(
    photoUrls: List<String> = emptyList(),
    stateHistory: List<StateHistoryEntryResponse> = emptyList()
) = IssueDetailResponse(
    // ... existing fields ...
    stateHistory = stateHistory,
)
```

Add extension for converting history entries:
```kotlin
fun IssueStateHistoryEntry.toResponse(adminName: String? = null) =
    StateHistoryEntryResponse(
        state = state.toApiString(),
        changedAt = changedAt.toString(),
        changedBy = adminName,
        note = note,
    )
```

## Files to Modify

### 1. IssueService.kt

Add dependency:
```kotlin
@Service
class IssueService(
    private val repository: IssueRepository,
    private val stateHistoryRepository: IssueStateHistoryRepository,
    private val clock: Clock,
)
```

Update `updateState()`:
```kotlin
@Transactional
fun updateState(
    id: IssueId,
    newState: IssueState,
    actorId: AdminId? = null,
    note: String? = null,
): IssueResult {
    val issue = repository.findByIdForUpdate(id)
        ?: return IssueResult.NotFound(id)

    if (!issue.canTransitionTo(newState)) {
        return IssueResult.InvalidTransition(issue.state, newState)
    }

    val now = Instant.now(clock)
    val updatedIssue = issue
        .withState(newState)
        .withUpdatedAt(now)

    val savedIssue = repository.save(updatedIssue)

    // Record state history
    val historyEntry = IssueStateHistoryEntry(
        id = IssueStateHistoryId.generate(),
        issueId = id,
        state = newState,
        changedAt = now,
        changedBy = actorId,
        note = note,
    )
    stateHistoryRepository.save(historyEntry)

    return IssueResult.Success(savedIssue)
}
```

Update `create()` to record initial "reported" state:
```kotlin
@Transactional
fun create(command: CreateIssueCommand): IssueResult {
    val now = Instant.now(clock)
    val issue = Issue(
        // ... existing code ...
    )

    val savedIssue = repository.save(issue)

    // Record initial state
    val historyEntry = IssueStateHistoryEntry(
        id = IssueStateHistoryId.generate(),
        issueId = savedIssue.id,
        state = IssueState.Reported,
        changedAt = now,
        changedBy = null,  // System-initiated
        note = null,
    )
    stateHistoryRepository.save(historyEntry)

    return IssueResult.Success(savedIssue)
}
```

Add method to get state history:
```kotlin
@Transactional(readOnly = true)
fun getStateHistory(issueId: IssueId): List<IssueStateHistoryEntry> =
    stateHistoryRepository.findByIssueId(issueId)
```

### 2. IssueController.kt

Add dependency on admin service for name lookup (or skip if just showing ID):
```kotlin
class IssueController(
    private val issueService: IssueService,
    private val photoService: IssuePhotoService,
)
```

Update `getIssue()`:
```kotlin
@GetMapping("/{id}")
fun getIssue(@PathVariable id: String): ResponseEntity<*> {
    val issueId = IssueId(UUID.fromString(id))

    return when (val result = issueService.findById(issueId)) {
        is IssueResult.Success -> {
            val photoUrls = photoService.getPhotoUrls(issueId)
            val stateHistory = issueService.getStateHistory(issueId)
                .map { it.toResponse() }  // Add admin name lookup if needed
            ResponseEntity.ok(result.issue.toDetailResponse(photoUrls, stateHistory))
        }
        // ... existing error handling ...
    }
}
```

Update `updateIssueState()` to extract admin ID and pass note:
```kotlin
@PatchMapping("/{id}/state")
fun updateIssueState(
    @PathVariable id: String,
    @RequestBody request: UpdateIssueStateRequest,
    @AuthenticationPrincipal adminIdStr: String?,
): ResponseEntity<*> {
    val issueId = IssueId(UUID.fromString(id))
    val newState = IssueState.fromString(request.state)
    val adminId = adminIdStr?.let { AdminId(UUID.fromString(it)) }

    return when (val result = issueService.updateState(
        id = issueId,
        newState = newState,
        actorId = adminId,
        note = request.note,
    )) {
        is IssueResult.Success -> {
            val photoUrls = photoService.getPhotoUrls(issueId)
            val stateHistory = issueService.getStateHistory(issueId)
                .map { it.toResponse() }
            ResponseEntity.ok(result.issue.toDetailResponse(photoUrls, stateHistory))
        }
        // ... existing error handling ...
    }
}
```

### 3. Verify AdminId Value Object Exists

Check if `AdminId` exists in `shared/types/`. If not, create it:

```kotlin
// backend/src/main/kotlin/com/munserv/shared/types/AdminId.kt
package com.munserv.shared.types

import java.util.UUID

@JvmInline
value class AdminId(val value: UUID)
```

## Tests Required

### Unit Tests

**`IssueStateHistoryEntryTest.kt`**
- Domain class creation and properties

**`IssueStateHistoryRepositoryTest.kt`**
- Save and retrieve by issue ID
- Ordering by changedAt

**Update `IssueServiceTest.kt`**
- Verify history entry created on issue creation
- Verify history entry created on state change
- Verify actor and note are recorded

### Integration Tests

**Update `IssueReportingScenarioTest.kt`**
- Full flow: create issue, change state, verify history

### Contract Tests

**Update `IssuesApiContractTest.kt`**
- GET /issues/{id} returns stateHistory array
- PATCH /issues/{id}/state records history entry

## Definition of Done

- [ ] All new files created
- [ ] IssueService records history on create and updateState
- [ ] IssueController returns stateHistory in detail response
- [ ] Unit tests passing
- [ ] Integration tests passing
- [ ] Contract tests passing
- [ ] ktlint check passing
- [ ] No SonarQube issues
