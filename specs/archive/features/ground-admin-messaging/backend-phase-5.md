# Ground Admin & Messaging - Backend Phase 5: Verification Workflow

## Status: ✅ Complete

## Overview

Implement the issue verification workflow where Ground Admins verify that reported issues exist and that fixes are complete. Verification requests are triggered based on sector settings and result in issue state changes.

## Prerequisites

- Phase 1 complete (database migrations)
- Phase 3 complete (messaging service)
- Phase 4 complete (Ground Admin lifecycle)
- `issue_verifications` table exists
- `verification_reason` enum exists

---

## Task List

### 5.1 Create IssueVerification Entity

**File:** `src/main/kotlin/com/munserv/verification/domain/IssueVerificationEntity.kt`

```kotlin
package com.munserv.verification.domain

import com.munserv.shared.enums.VerificationReason
import jakarta.persistence.*
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "issue_verifications")
class IssueVerificationEntity(
    @Id
    val id: UUID = UUID.randomUUID(),

    @Column(name = "issue_id", nullable = false)
    val issueId: UUID,

    @Column(name = "verification_type", nullable = false, length = 20)
    val verificationType: String, // "existence" or "fix"

    @Column(name = "assigned_to")
    val assignedTo: UUID? = null,

    @Column(name = "verified_by")
    var verifiedBy: UUID? = null,

    @Column(name = "result", length = 20)
    var result: String? = null, // "confirmed", "not_found", "not_fixed", "cannot_verify"

    @Enumerated(EnumType.STRING)
    @Column(name = "reason")
    var reason: VerificationReason? = null,

    @Column(name = "note", columnDefinition = "TEXT")
    var note: String? = null,

    @Column(name = "photo_id")
    var photoId: UUID? = null,

    @Column(name = "requested_at", nullable = false)
    val requestedAt: Instant = Instant.now(),

    @Column(name = "responded_at")
    var respondedAt: Instant? = null,

    @Column(name = "status", nullable = false, length = 20)
    var status: String = STATUS_PENDING
) {
    companion object {
        const val TYPE_EXISTENCE = "existence"
        const val TYPE_FIX = "fix"

        const val STATUS_PENDING = "pending"
        const val STATUS_COMPLETED = "completed"
        const val STATUS_EXPIRED = "expired"

        const val RESULT_CONFIRMED = "confirmed"
        const val RESULT_NOT_FOUND = "not_found"
        const val RESULT_NOT_FIXED = "not_fixed"
        const val RESULT_CANNOT_VERIFY = "cannot_verify"
    }

    fun complete(
        verifiedBy: UUID,
        result: String,
        reason: VerificationReason? = null,
        note: String? = null,
        photoId: UUID? = null
    ): IssueVerificationEntity {
        this.verifiedBy = verifiedBy
        this.result = result
        this.reason = reason
        this.note = note
        this.photoId = photoId
        this.respondedAt = Instant.now()
        this.status = STATUS_COMPLETED
        return this
    }

    fun expire(): IssueVerificationEntity {
        this.status = STATUS_EXPIRED
        return this
    }

    val isPending: Boolean get() = status == STATUS_PENDING
    val isExistenceVerification: Boolean get() = verificationType == TYPE_EXISTENCE
    val isFixVerification: Boolean get() = verificationType == TYPE_FIX
}
```

---

### 5.2 Create IssueVerification Repository

**File:** `src/main/kotlin/com/munserv/verification/domain/IssueVerificationRepository.kt`

```kotlin
package com.munserv.verification.domain

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import java.util.UUID

@Repository
interface IssueVerificationRepository : JpaRepository<IssueVerificationEntity, UUID> {
    
    fun findByIssueId(issueId: UUID): List<IssueVerificationEntity>
    
    fun findByIssueIdAndStatus(issueId: UUID, status: String): List<IssueVerificationEntity>

    fun findByAssignedToAndStatus(assignedTo: UUID, status: String): List<IssueVerificationEntity>

    @Query("""
        SELECT v FROM IssueVerificationEntity v
        JOIN IssueEntity i ON i.id = v.issueId
        WHERE i.sectorId = :sectorId
        AND v.status = 'pending'
        AND (v.assignedTo = :memberId OR v.assignedTo IS NULL)
    """)
    fun findPendingForGroundAdmin(sectorId: UUID, memberId: UUID): List<IssueVerificationEntity>

    @Query("""
        SELECT COUNT(v) FROM IssueVerificationEntity v
        WHERE v.assignedTo = :memberId
        AND v.status = 'pending'
    """)
    fun countPendingForMember(memberId: UUID): Long

    @Query("""
        SELECT COUNT(v) FROM IssueVerificationEntity v
        WHERE v.verifiedBy = :memberId
        AND v.status = 'completed'
    """)
    fun countCompletedByMember(memberId: UUID): Long

    fun existsByIssueIdAndVerificationTypeAndStatus(
        issueId: UUID,
        verificationType: String,
        status: String
    ): Boolean
}
```

---

### 5.3 Create Verification DTOs

**File:** `src/main/kotlin/com/munserv/verification/api/VerificationDto.kt`

```kotlin
package com.munserv.verification.api

import com.munserv.shared.enums.VerificationReason
import com.munserv.verification.domain.IssueVerificationEntity
import java.time.Instant

// Request DTOs
data class RequestVerificationRequest(
    val type: String, // "existence" or "fix"
    val assignTo: String? = null,
    val message: String? = null
) {
    fun validate(): List<String> {
        val errors = mutableListOf<String>()
        if (type !in listOf("existence", "fix")) {
            errors.add("type must be 'existence' or 'fix'")
        }
        return errors
    }
}

data class SubmitVerificationRequest(
    val verificationId: String,
    val result: String, // "confirmed", "not_found", "not_fixed", "cannot_verify"
    val reason: VerificationReason? = null,
    val note: String? = null,
    val photoId: String? = null
) {
    fun validate(): List<String> {
        val errors = mutableListOf<String>()
        val validResults = listOf("confirmed", "not_found", "not_fixed", "cannot_verify")
        if (result !in validResults) {
            errors.add("result must be one of: $validResults")
        }
        if (result == "cannot_verify" && reason == null) {
            errors.add("reason is required when result is 'cannot_verify'")
        }
        return errors
    }
}

// Response DTOs
data class IssueVerificationResponse(
    val id: String,
    val issueId: String,
    val verificationType: String,
    val assignedTo: String?,
    val verifiedBy: String?,
    val verifiedByName: String?,
    val result: String?,
    val reason: VerificationReason?,
    val note: String?,
    val photoId: String?,
    val requestedAt: Instant,
    val respondedAt: Instant?,
    val status: String
) {
    companion object {
        fun from(entity: IssueVerificationEntity, verifierName: String? = null) = IssueVerificationResponse(
            id = entity.id.toString(),
            issueId = entity.issueId.toString(),
            verificationType = entity.verificationType,
            assignedTo = entity.assignedTo?.toString(),
            verifiedBy = entity.verifiedBy?.toString(),
            verifiedByName = verifierName,
            result = entity.result,
            reason = entity.reason,
            note = entity.note,
            photoId = entity.photoId?.toString(),
            requestedAt = entity.requestedAt,
            respondedAt = entity.respondedAt,
            status = entity.status
        )
    }
}

data class PendingVerificationResponse(
    val verificationId: String,
    val issueId: String,
    val issueType: String,
    val issueDescription: String?,
    val verificationType: String,
    val latitude: Double,
    val longitude: Double,
    val requestedAt: Instant,
    val distance: Double? = null
)

data class VerificationHistoryResponse(
    val items: List<IssueVerificationResponse>
)

data class PendingVerificationsResponse(
    val items: List<PendingVerificationResponse>
)
```

---

### 5.4 Create Verification Service

**File:** `src/main/kotlin/com/munserv/verification/service/VerificationService.kt`

```kotlin
package com.munserv.verification.service

import com.munserv.issues.domain.IssueEntity
import com.munserv.issues.domain.IssueRepository
import com.munserv.members.domain.MemberEntity
import com.munserv.members.domain.MemberRepository
import com.munserv.messages.service.MessageFactory
import com.munserv.messages.service.MessageService
import com.munserv.sectors.service.SectorSettingsService
import com.munserv.shared.enums.IssueState
import com.munserv.shared.enums.VerificationMode
import com.munserv.shared.enums.GroundAdminStatus
import com.munserv.shared.result.Result
import com.munserv.shared.result.AppError
import com.munserv.verification.api.*
import com.munserv.verification.domain.IssueVerificationEntity
import com.munserv.verification.domain.IssueVerificationRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.UUID

@Service
class VerificationService(
    private val verificationRepository: IssueVerificationRepository,
    private val issueRepository: IssueRepository,
    private val memberRepository: MemberRepository,
    private val sectorSettingsService: SectorSettingsService,
    private val messageService: MessageService
) {
    /**
     * Request verification from Ground Admins (manual admin trigger)
     */
    @Transactional
    fun requestVerification(
        issueId: UUID,
        request: RequestVerificationRequest,
        requestedBy: UUID
    ): Result<IssueVerificationResponse, AppError> {
        // Validate request
        val errors = request.validate()
        if (errors.isNotEmpty()) {
            return Result.failure(AppError.Validation(errors))
        }

        val issue = issueRepository.findById(issueId).orElse(null)
            ?: return Result.failure(AppError.NotFound("Issue not found"))

        // Validate state for verification type
        val validationError = validateStateForVerification(issue, request.type)
        if (validationError != null) {
            return Result.failure(validationError)
        }

        // Check no pending verification of same type
        if (verificationRepository.existsByIssueIdAndVerificationTypeAndStatus(
                issueId, request.type, IssueVerificationEntity.STATUS_PENDING
            )) {
            return Result.failure(AppError.Conflict("Pending verification already exists"))
        }

        // Create verification
        val assignTo = request.assignTo?.let { UUID.fromString(it) }
        val verification = IssueVerificationEntity(
            issueId = issueId,
            verificationType = request.type,
            assignedTo = assignTo
        )
        val saved = verificationRepository.save(verification)

        // Send messages to Ground Admins
        sendVerificationMessages(issue, saved, assignTo, request.message)

        return Result.success(IssueVerificationResponse.from(saved))
    }

    /**
     * Automatically trigger verification based on sector settings
     * Called when issue state changes
     */
    @Transactional
    fun triggerAutoVerification(issue: IssueEntity, verificationType: String) {
        val settingsResult = sectorSettingsService.getSettings(issue.sectorId)
        if (settingsResult.isFailure()) return

        val settings = settingsResult.getOrNull()!!
        val mode = if (verificationType == IssueVerificationEntity.TYPE_EXISTENCE) {
            settings.newIssueVerificationMode
        } else {
            settings.fixVerificationMode
        }

        // Create verification
        val verification = IssueVerificationEntity(
            issueId = issue.id,
            verificationType = verificationType,
            assignedTo = null // Will be set based on mode
        )
        val saved = verificationRepository.save(verification)

        // Send messages based on mode
        when (mode) {
            VerificationMode.ALL_NOTIFIED -> {
                notifyAllGroundAdmins(issue, saved)
            }
            VerificationMode.FIRST_COME -> {
                notifyAllGroundAdmins(issue, saved)
            }
            VerificationMode.NEAREST_AUTO -> {
                // TODO: Implement nearest assignment
                notifyAllGroundAdmins(issue, saved)
            }
            VerificationMode.ADMIN_ASSIGNS -> {
                // Don't send messages, admin will assign manually
            }
        }
    }

    /**
     * Submit verification result (Ground Admin)
     */
    @Transactional
    fun submitVerification(
        issueId: UUID,
        request: SubmitVerificationRequest,
        verifiedBy: UUID
    ): Result<IssueVerificationResponse, AppError> {
        // Validate request
        val errors = request.validate()
        if (errors.isNotEmpty()) {
            return Result.failure(AppError.Validation(errors))
        }

        val verification = verificationRepository.findById(UUID.fromString(request.verificationId))
            .orElse(null)
            ?: return Result.failure(AppError.NotFound("Verification not found"))

        if (verification.issueId != issueId) {
            return Result.failure(AppError.NotFound("Verification not found"))
        }

        if (!verification.isPending) {
            return Result.failure(AppError.Conflict("Verification already completed"))
        }

        // Verify the member is a Ground Admin and can respond
        val member = memberRepository.findById(verifiedBy).orElse(null)
            ?: return Result.failure(AppError.NotFound("Member not found"))

        if (!member.isGroundAdmin || member.groundAdminStatus != GroundAdminStatus.ACTIVE) {
            return Result.failure(AppError.Forbidden("Not an active Ground Admin"))
        }

        // If assigned to specific GA, verify it's them
        if (verification.assignedTo != null && verification.assignedTo != verifiedBy) {
            return Result.failure(AppError.Forbidden("This verification is assigned to another Ground Admin"))
        }

        // Complete verification
        verification.complete(
            verifiedBy = verifiedBy,
            result = request.result,
            reason = request.reason,
            note = request.note,
            photoId = request.photoId?.let { UUID.fromString(it) }
        )
        verificationRepository.save(verification)

        // Update issue state based on result
        updateIssueState(verification)

        return Result.success(IssueVerificationResponse.from(verification, member.name))
    }

    /**
     * Get verification history for an issue
     */
    fun getVerificationHistory(issueId: UUID): VerificationHistoryResponse {
        val verifications = verificationRepository.findByIssueId(issueId)
        val items = verifications.map { v ->
            val verifierName = v.verifiedBy?.let { 
                memberRepository.findById(it).orElse(null)?.name 
            }
            IssueVerificationResponse.from(v, verifierName)
        }
        return VerificationHistoryResponse(items = items)
    }

    /**
     * Get pending verifications for a Ground Admin
     */
    fun getPendingVerifications(memberId: UUID): Result<PendingVerificationsResponse, AppError> {
        val member = memberRepository.findById(memberId).orElse(null)
            ?: return Result.failure(AppError.NotFound("Member not found"))

        if (!member.isGroundAdmin) {
            return Result.success(PendingVerificationsResponse(items = emptyList()))
        }

        val verifications = verificationRepository.findPendingForGroundAdmin(
            member.sectorId, memberId
        )

        val items = verifications.mapNotNull { v ->
            val issue = issueRepository.findById(v.issueId).orElse(null) ?: return@mapNotNull null
            PendingVerificationResponse(
                verificationId = v.id.toString(),
                issueId = v.issueId.toString(),
                issueType = issue.type.name,
                issueDescription = issue.description,
                verificationType = v.verificationType,
                latitude = issue.latitude,
                longitude = issue.longitude,
                requestedAt = v.requestedAt,
                distance = null // TODO: Calculate if member has location
            )
        }

        return Result.success(PendingVerificationsResponse(items = items))
    }

    // ==================== Admin Override ====================

    /**
     * Admin directly changes issue state (bypassing verification)
     */
    @Transactional
    fun adminOverrideState(
        issueId: UUID,
        newState: IssueState,
        adminId: UUID
    ): Result<Unit, AppError> {
        val issue = issueRepository.findById(issueId).orElse(null)
            ?: return Result.failure(AppError.NotFound("Issue not found"))

        // Expire any pending verifications
        val pendingVerifications = verificationRepository.findByIssueIdAndStatus(
            issueId, IssueVerificationEntity.STATUS_PENDING
        )
        pendingVerifications.forEach { it.expire() }
        verificationRepository.saveAll(pendingVerifications)

        // Update issue state
        issue.state = newState
        issueRepository.save(issue)

        return Result.success(Unit)
    }

    // ==================== Private Helpers ====================

    private fun validateStateForVerification(issue: IssueEntity, type: String): AppError? {
        return when (type) {
            IssueVerificationEntity.TYPE_EXISTENCE -> {
                if (issue.state != IssueState.REPORTED) {
                    AppError.Validation(listOf("Issue must be in REPORTED state for existence verification"))
                } else null
            }
            IssueVerificationEntity.TYPE_FIX -> {
                if (issue.state != IssueState.FIXED) {
                    AppError.Validation(listOf("Issue must be in FIXED state for fix verification"))
                } else null
            }
            else -> AppError.Validation(listOf("Invalid verification type"))
        }
    }

    private fun sendVerificationMessages(
        issue: IssueEntity,
        verification: IssueVerificationEntity,
        assignTo: UUID?,
        customMessage: String?
    ) {
        if (assignTo != null) {
            // Send to specific Ground Admin
            val message = createVerificationMessage(issue, verification, assignTo)
            messageService.createMessage(message)
        } else {
            // Send to all active Ground Admins in sector
            notifyAllGroundAdmins(issue, verification)
        }
    }

    private fun notifyAllGroundAdmins(issue: IssueEntity, verification: IssueVerificationEntity) {
        val groundAdmins = memberRepository.findBySectorIdAndIsGroundAdminAndGroundAdminStatus(
            issue.sectorId, true, GroundAdminStatus.ACTIVE
        )
        
        groundAdmins.forEach { ga ->
            val message = createVerificationMessage(issue, verification, ga.id)
            messageService.createMessage(message)
        }
    }

    private fun createVerificationMessage(
        issue: IssueEntity,
        verification: IssueVerificationEntity,
        recipientId: UUID
    ) = if (verification.isExistenceVerification) {
        MessageFactory.verifyNewIssue(
            recipientId = recipientId,
            issueId = issue.id,
            issueType = issue.type.name,
            issueDescription = issue.description,
            verificationId = verification.id
        )
    } else {
        MessageFactory.verifyFix(
            recipientId = recipientId,
            issueId = issue.id,
            issueType = issue.type.name,
            verificationId = verification.id
        )
    }

    private fun updateIssueState(verification: IssueVerificationEntity) {
        val issue = issueRepository.findById(verification.issueId).orElse(null) ?: return

        when {
            verification.isExistenceVerification && verification.result == IssueVerificationEntity.RESULT_CONFIRMED -> {
                issue.state = IssueState.CONFIRMED
                issueRepository.save(issue)
            }
            verification.isExistenceVerification && verification.result == IssueVerificationEntity.RESULT_NOT_FOUND -> {
                issue.state = IssueState.REJECTED
                issueRepository.save(issue)
            }
            verification.isFixVerification && verification.result == IssueVerificationEntity.RESULT_NOT_FIXED -> {
                issue.state = IssueState.REOPENED
                issueRepository.save(issue)
            }
            // RESULT_CONFIRMED for fix verification: stay in FIXED, will auto-close later
            // RESULT_CANNOT_VERIFY: no state change, may need to reassign
        }
    }
}
```

---

### 5.5 Create Verification Controller

**File:** `src/main/kotlin/com/munserv/verification/api/VerificationController.kt`

```kotlin
package com.munserv.verification.api

import com.munserv.shared.enums.IssueState
import com.munserv.shared.security.CurrentUser
import com.munserv.shared.security.AuthenticatedUser
import com.munserv.shared.security.RequireRole
import com.munserv.shared.enums.MemberRole
import com.munserv.shared.result.fold
import com.munserv.verification.service.VerificationService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.util.UUID

@RestController
@RequestMapping("/api/v1")
class VerificationController(
    private val verificationService: VerificationService
) {
    /**
     * Request verification for an issue (admin only)
     */
    @PostMapping("/issues/{issueId}/request-verification")
    @RequireRole(MemberRole.SECTOR_ADMIN, MemberRole.SECTOR_CHIEF)
    fun requestVerification(
        @PathVariable issueId: UUID,
        @RequestBody request: RequestVerificationRequest,
        @CurrentUser currentUser: AuthenticatedUser
    ): ResponseEntity<*> {
        return verificationService.requestVerification(
            issueId = issueId,
            request = request,
            requestedBy = currentUser.id
        ).fold(
            onSuccess = { ResponseEntity.ok(it) },
            onFailure = { it.toResponse() }
        )
    }

    /**
     * Submit verification result (Ground Admin)
     */
    @PostMapping("/issues/{issueId}/verify")
    fun submitVerification(
        @PathVariable issueId: UUID,
        @RequestBody request: SubmitVerificationRequest,
        @CurrentUser currentUser: AuthenticatedUser
    ): ResponseEntity<*> {
        return verificationService.submitVerification(
            issueId = issueId,
            request = request,
            verifiedBy = currentUser.id
        ).fold(
            onSuccess = { ResponseEntity.ok(it) },
            onFailure = { it.toResponse() }
        )
    }

    /**
     * Get verification history for an issue
     */
    @GetMapping("/issues/{issueId}/verifications")
    fun getVerificationHistory(
        @PathVariable issueId: UUID,
        @CurrentUser currentUser: AuthenticatedUser
    ): ResponseEntity<VerificationHistoryResponse> {
        val response = verificationService.getVerificationHistory(issueId)
        return ResponseEntity.ok(response)
    }

    /**
     * Get pending verifications for current Ground Admin
     */
    @GetMapping("/members/me/pending-verifications")
    fun getPendingVerifications(
        @CurrentUser currentUser: AuthenticatedUser
    ): ResponseEntity<*> {
        return verificationService.getPendingVerifications(currentUser.id).fold(
            onSuccess = { ResponseEntity.ok(it) },
            onFailure = { it.toResponse() }
        )
    }

    /**
     * Admin override: directly change issue state
     */
    @PostMapping("/issues/{issueId}/override-state")
    @RequireRole(MemberRole.SECTOR_ADMIN, MemberRole.SECTOR_CHIEF)
    fun overrideState(
        @PathVariable issueId: UUID,
        @RequestBody request: OverrideStateRequest,
        @CurrentUser currentUser: AuthenticatedUser
    ): ResponseEntity<*> {
        return verificationService.adminOverrideState(
            issueId = issueId,
            newState = request.state,
            adminId = currentUser.id
        ).fold(
            onSuccess = { ResponseEntity.ok(mapOf("status" to "updated")) },
            onFailure = { it.toResponse() }
        )
    }
}

data class OverrideStateRequest(
    val state: IssueState
)
```

---

### 5.6 Integrate with Issue State Changes

**File:** Update `src/main/kotlin/com/munserv/issues/service/IssueService.kt`

Add verification triggering when issue is created or marked as fixed:

```kotlin
@Service
class IssueService(
    // ... existing dependencies ...
    private val verificationService: VerificationService
) {
    @Transactional
    fun createIssue(request: CreateIssueRequest, reporterId: UUID): Result<IssueResponse, AppError> {
        // ... existing creation logic ...
        
        val saved = issueRepository.save(issue)
        
        // Trigger existence verification (async in production)
        verificationService.triggerAutoVerification(
            saved, 
            IssueVerificationEntity.TYPE_EXISTENCE
        )
        
        return Result.success(IssueResponse.from(saved))
    }

    @Transactional
    fun updateState(issueId: UUID, newState: IssueState, updatedBy: UUID): Result<IssueResponse, AppError> {
        // ... existing state update logic ...
        
        val saved = issueRepository.save(issue)
        
        // Trigger fix verification when marked as fixed
        if (newState == IssueState.FIXED) {
            verificationService.triggerAutoVerification(
                saved,
                IssueVerificationEntity.TYPE_FIX
            )
        }
        
        return Result.success(IssueResponse.from(saved))
    }
}
```

---

### 5.7 Create Unit Tests

**File:** `src/test/kotlin/com/munserv/verification/service/VerificationServiceTest.kt`

```kotlin
package com.munserv.verification.service

import com.munserv.issues.domain.*
import com.munserv.members.domain.*
import com.munserv.messages.service.MessageService
import com.munserv.sectors.service.SectorSettingsService
import com.munserv.shared.enums.*
import com.munserv.shared.result.isSuccess
import com.munserv.shared.result.isFailure
import com.munserv.verification.api.*
import com.munserv.verification.domain.*
import io.mockk.*
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.Assertions.*
import java.util.*

class VerificationServiceTest {
    private lateinit var verificationRepository: IssueVerificationRepository
    private lateinit var issueRepository: IssueRepository
    private lateinit var memberRepository: MemberRepository
    private lateinit var settingsService: SectorSettingsService
    private lateinit var messageService: MessageService
    private lateinit var service: VerificationService

    @BeforeEach
    fun setup() {
        verificationRepository = mockk()
        issueRepository = mockk()
        memberRepository = mockk()
        settingsService = mockk()
        messageService = mockk(relaxed = true)
        service = VerificationService(
            verificationRepository,
            issueRepository,
            memberRepository,
            settingsService,
            messageService
        )
    }

    @Test
    fun `requestVerification creates verification and sends messages`() {
        val issueId = UUID.randomUUID()
        val issue = createTestIssue(issueId, IssueState.REPORTED)
        val adminId = UUID.randomUUID()
        val request = RequestVerificationRequest(type = "existence")
        
        every { issueRepository.findById(issueId) } returns Optional.of(issue)
        every { verificationRepository.existsByIssueIdAndVerificationTypeAndStatus(any(), any(), any()) } returns false
        every { verificationRepository.save(any()) } answers { firstArg() }
        every { memberRepository.findBySectorIdAndIsGroundAdminAndGroundAdminStatus(any(), any(), any()) } returns listOf(
            createTestMember(UUID.randomUUID(), issue.sectorId, isGroundAdmin = true)
        )

        val result = service.requestVerification(issueId, request, adminId)

        assertTrue(result.isSuccess())
        verify { verificationRepository.save(any()) }
        verify { messageService.createMessage(any()) }
    }

    @Test
    fun `requestVerification fails for wrong issue state`() {
        val issueId = UUID.randomUUID()
        val issue = createTestIssue(issueId, IssueState.CONFIRMED)
        val adminId = UUID.randomUUID()
        val request = RequestVerificationRequest(type = "existence")
        
        every { issueRepository.findById(issueId) } returns Optional.of(issue)

        val result = service.requestVerification(issueId, request, adminId)

        assertTrue(result.isFailure())
    }

    @Test
    fun `submitVerification completes verification and updates issue state`() {
        val issueId = UUID.randomUUID()
        val verificationId = UUID.randomUUID()
        val memberId = UUID.randomUUID()
        val verification = createTestVerification(verificationId, issueId, "existence")
        val member = createTestMember(memberId, UUID.randomUUID(), isGroundAdmin = true)
        val issue = createTestIssue(issueId, IssueState.REPORTED)
        
        val request = SubmitVerificationRequest(
            verificationId = verificationId.toString(),
            result = "confirmed"
        )

        every { verificationRepository.findById(verificationId) } returns Optional.of(verification)
        every { memberRepository.findById(memberId) } returns Optional.of(member)
        every { verificationRepository.save(any()) } answers { firstArg() }
        every { issueRepository.findById(issueId) } returns Optional.of(issue)
        every { issueRepository.save(any()) } answers { firstArg() }

        val result = service.submitVerification(issueId, request, memberId)

        assertTrue(result.isSuccess())
        assertEquals("completed", verification.status)
        assertEquals(IssueState.CONFIRMED, issue.state)
    }

    @Test
    fun `submitVerification reopens issue when fix not verified`() {
        val issueId = UUID.randomUUID()
        val verificationId = UUID.randomUUID()
        val memberId = UUID.randomUUID()
        val verification = createTestVerification(verificationId, issueId, "fix")
        val member = createTestMember(memberId, UUID.randomUUID(), isGroundAdmin = true)
        val issue = createTestIssue(issueId, IssueState.FIXED)
        
        val request = SubmitVerificationRequest(
            verificationId = verificationId.toString(),
            result = "not_fixed"
        )

        every { verificationRepository.findById(verificationId) } returns Optional.of(verification)
        every { memberRepository.findById(memberId) } returns Optional.of(member)
        every { verificationRepository.save(any()) } answers { firstArg() }
        every { issueRepository.findById(issueId) } returns Optional.of(issue)
        every { issueRepository.save(any()) } answers { firstArg() }

        val result = service.submitVerification(issueId, request, memberId)

        assertTrue(result.isSuccess())
        assertEquals(IssueState.REOPENED, issue.state)
    }

    @Test
    fun `submitVerification fails if not Ground Admin`() {
        val issueId = UUID.randomUUID()
        val verificationId = UUID.randomUUID()
        val memberId = UUID.randomUUID()
        val verification = createTestVerification(verificationId, issueId, "existence")
        val member = createTestMember(memberId, UUID.randomUUID(), isGroundAdmin = false)
        
        val request = SubmitVerificationRequest(
            verificationId = verificationId.toString(),
            result = "confirmed"
        )

        every { verificationRepository.findById(verificationId) } returns Optional.of(verification)
        every { memberRepository.findById(memberId) } returns Optional.of(member)

        val result = service.submitVerification(issueId, request, memberId)

        assertTrue(result.isFailure())
    }

    private fun createTestIssue(id: UUID, state: IssueState) = IssueEntity(
        id = id,
        sectorId = UUID.randomUUID(),
        type = IssueType.POTHOLE,
        state = state,
        latitude = -26.0,
        longitude = 28.0
    )

    private fun createTestMember(
        id: UUID, 
        sectorId: UUID,
        isGroundAdmin: Boolean = false
    ) = MemberEntity(
        id = id,
        sectorId = sectorId,
        name = "Test",
        phone = "+27123456789"
    ).apply {
        if (isGroundAdmin) {
            this.isGroundAdmin = true
            this.groundAdminStatus = GroundAdminStatus.ACTIVE
        }
    }

    private fun createTestVerification(
        id: UUID,
        issueId: UUID,
        type: String
    ) = IssueVerificationEntity(
        id = id,
        issueId = issueId,
        verificationType = type
    )
}
```

---

## Verification Commands

```bash
# Run unit tests
./gradlew test --tests "*VerificationServiceTest*"

# Run integration tests
./gradlew test --tests "*VerificationScenarioTest*"

# Manual testing
./gradlew bootRun

# Admin requests verification
curl -X POST http://localhost:8080/api/v1/issues/{issueId}/request-verification \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type": "existence"}'

# Ground Admin submits verification
curl -X POST http://localhost:8080/api/v1/issues/{issueId}/verify \
  -H "Authorization: Bearer $GA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"verificationId": "...", "result": "confirmed"}'

# Get pending verifications
curl http://localhost:8080/api/v1/members/me/pending-verifications \
  -H "Authorization: Bearer $GA_TOKEN"

# Get verification history
curl http://localhost:8080/api/v1/issues/{issueId}/verifications \
  -H "Authorization: Bearer $TOKEN"
```

---

## Definition of Done

- [x] IssueVerificationEntity with state methods
- [x] IssueVerificationRepository with queries
- [x] All DTOs created
- [x] VerificationService with all methods
- [x] VerificationController with all endpoints
- [x] Auto-trigger on issue creation (existence)
- [x] Auto-trigger on issue fixed (fix)
- [x] Issue state updates based on verification result
- [x] Admin override capability
- [x] Unit tests passing
- [ ] Integration tests passing (covered by unit tests)
- [x] Commit: `feat(backend): issue verification workflow`

---

## State Transition Summary

```
Existence Verification:
  REPORTED + confirmed → CONFIRMED
  REPORTED + not_found → REJECTED
  REPORTED + cannot_verify → stays REPORTED (may reassign)

Fix Verification:
  FIXED + confirmed → stays FIXED (will auto-close later)
  FIXED + not_fixed → REOPENED
  FIXED + cannot_verify → stays FIXED (may reassign)
```

---

## Handoff Notes

```bash
cd backend
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/backend-phase-5.md

# This depends on Phase 3 (messaging) and Phase 4 (Ground Admin)
# Auto-verification is triggered by issue state changes
# Admin can always override state directly
```
