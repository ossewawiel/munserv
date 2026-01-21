# Feature: Issue State History (Audit Log)

**Status:** 🟢 Done (Backend and Web complete)

## Summary

Implement a complete audit trail for issue state changes, enabling:
1. Tracking when issues transition between states
2. Recording who made each state change
3. Storing optional notes for each transition
4. Displaying timeline progression in the web admin portal
5. Future reporting on state duration and service improvement metrics

## Current State Analysis

### What Exists

| Component | Status | Notes |
|-----------|--------|-------|
| Database table | Done | `issue_state_history` exists with seed data (V010) |
| Web types | Done | `StateHistoryEntry` interface defined |
| Web component | Done | `HorizontalTimeline` component exists |
| Web page integration | Done | `IssueDetailPage` renders timeline (Card 4) |
| Backend entity | **Missing** | No Kotlin entity for state history |
| Backend repository | **Missing** | No JPA repository |
| Backend service | **Missing** | State changes don't persist history |
| Backend API response | **Missing** | `IssueDetailResponse` lacks `stateHistory` |

### Database Schema (V010)

```sql
CREATE TABLE issue_state_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id UUID NOT NULL REFERENCES issues(id) ON DELETE CASCADE,
    state issue_state NOT NULL,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    changed_by UUID REFERENCES admins(id) ON DELETE SET NULL,
    note TEXT
);
```

## Implementation Plan

### Backend Tasks

#### 1. Domain Model

Create `IssueStateHistoryEntry` domain class:
- `id: IssueStateHistoryId`
- `issueId: IssueId`
- `state: IssueState`
- `changedAt: Instant`
- `changedBy: AdminId?` (nullable - system changes have no actor)
- `note: String?`

#### 2. Repository Layer

**Files to create:**
- `backend/src/main/kotlin/com/munserv/issues/domain/IssueStateHistoryEntry.kt`
- `backend/src/main/kotlin/com/munserv/issues/domain/IssueStateHistoryId.kt`
- `backend/src/main/kotlin/com/munserv/issues/repository/IssueStateHistoryEntity.kt`
- `backend/src/main/kotlin/com/munserv/issues/repository/IssueStateHistoryRepository.kt`

**IssueStateHistoryRepository interface:**
```kotlin
interface IssueStateHistoryRepository {
    fun save(entry: IssueStateHistoryEntry): IssueStateHistoryEntry
    fun findByIssueId(issueId: IssueId): List<IssueStateHistoryEntry>
}
```

#### 3. Service Layer

**Modify `IssueService.kt`:**

Update `updateState()` to:
1. Accept `actorId: AdminId?` parameter
2. Accept `note: String?` parameter
3. After successful state transition, create and save `IssueStateHistoryEntry`

Update `create()` to:
1. After issue creation, create initial "reported" state history entry

**Signature change:**
```kotlin
fun updateState(
    id: IssueId,
    newState: IssueState,
    actorId: AdminId?,
    note: String?
): IssueResult
```

#### 4. API Layer

**Modify `IssueResponse.kt`:**

Add `StateHistoryEntryResponse`:
```kotlin
data class StateHistoryEntryResponse(
    val state: String,
    val changedAt: String,
    val changedBy: String?,  // Admin name or null
    val note: String?
)
```

Update `IssueDetailResponse` to include:
```kotlin
val stateHistory: List<StateHistoryEntryResponse>
```

Update `toDetailResponse()` extension to accept state history.

**Modify `IssueController.kt`:**

Update `getIssue()`:
- Fetch state history from repository
- Include in response

Update `updateIssueState()`:
- Extract admin ID from authentication principal
- Pass note from request to service

**Modify `IssueRequest.kt`:**

`UpdateIssueStateRequest` already has `note: String?` - verify it's being used.

#### 5. Tests

**Unit tests:**
- `IssueStateHistoryEntryTest.kt` - domain model tests
- `IssueStateHistoryRepositoryTest.kt` - repository tests
- Update `IssueServiceTest.kt` - verify history is created on state change

**Integration tests:**
- Update `IssueReportingScenarioTest.kt` - verify full flow with history

**Contract tests:**
- Update `IssuesApiContractTest.kt` - verify response includes stateHistory

### Web Tasks

#### 1. Types (Already Done)

`StateHistoryEntry` interface exists in `types.ts`:
```typescript
export interface StateHistoryEntry {
  state: IssueState;
  changedAt: string;
  changedBy: string | null;
  note?: string;
}
```

#### 2. API (Already Done)

`Issue` interface already has optional `stateHistory`:
```typescript
stateHistory?: StateHistoryEntry[];
```

#### 3. Component (Already Done)

`HorizontalTimeline` component exists and renders state history.

#### 4. Verification Required

Ensure the API client correctly receives and passes through `stateHistory` when backend starts returning it. No code changes expected - just verification.

## Implementation Order

```
1. [Backend] Create IssueStateHistoryId value object
2. [Backend] Create IssueStateHistoryEntry domain class
3. [Backend] Create IssueStateHistoryEntity JPA entity
4. [Backend] Create IssueStateHistoryRepository interface + implementation
5. [Backend] Update IssueService.updateState() to record history
6. [Backend] Update IssueService.create() to record initial state
7. [Backend] Add StateHistoryEntryResponse DTO
8. [Backend] Update IssueDetailResponse to include stateHistory
9. [Backend] Update IssueController.getIssue() to fetch and return history
10. [Backend] Update IssueController.updateIssueState() to pass actor and note
11. [Backend] Write unit tests
12. [Backend] Write integration tests
13. [Web] Verify timeline displays correctly (no code changes expected)
```

## Definition of Done

- [ ] State history is recorded when issues are created
- [ ] State history is recorded when issues change state
- [ ] State history includes actor ID (admin who made change)
- [ ] State history includes optional note
- [ ] GET /api/v1/issues/{id} returns stateHistory array
- [ ] Web timeline displays all state transitions
- [ ] All tests passing
- [ ] No lint errors
- [ ] SonarQube analysis clean

## Future Enhancements (Out of Scope)

- Reporting: Duration in each state by issue type
- Reporting: Service improvement metrics over time
- Mobile app: Display timeline on issue detail screen
- Search/filter by state change date ranges
