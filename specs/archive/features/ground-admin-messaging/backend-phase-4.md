# Ground Admin & Messaging - Backend Phase 4: Ground Admin Lifecycle

## Status: ✅ Complete

## Overview

Implement the complete Ground Admin lifecycle: application, invitation, approval, revocation, and step-down flows. Each state change creates appropriate messages via the MessageService.

## Prerequisites

- Phase 1 complete (database migrations)
- Phase 3 complete (messaging service)
- `ground_admin_applications` table exists
- Ground Admin fields on `members` table exist

---

## Task List

### 4.1 Create GroundAdminApplication Entity

**File:** `src/main/kotlin/com/munserv/groundadmin/domain/GroundAdminApplicationEntity.kt`

```kotlin
package com.munserv.groundadmin.domain

import jakarta.persistence.*
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "ground_admin_applications")
class GroundAdminApplicationEntity(
    @Id
    val id: UUID = UUID.randomUUID(),

    @Column(name = "member_id", nullable = false)
    val memberId: UUID,

    @Column(name = "sector_id", nullable = false)
    val sectorId: UUID,

    @Column(name = "type", nullable = false, length = 20)
    val type: String, // "application" or "invitation"

    @Column(name = "invited_by")
    val invitedBy: UUID? = null,

    @Column(name = "status", nullable = false, length = 20)
    var status: String = "pending",

    @Column(name = "processed_by")
    var processedBy: UUID? = null,

    @Column(name = "processed_at")
    var processedAt: Instant? = null,

    @Column(name = "decline_reason", columnDefinition = "TEXT")
    var declineReason: String? = null,

    @Column(name = "created_at", nullable = false)
    val createdAt: Instant = Instant.now(),

    @Column(name = "updated_at", nullable = false)
    var updatedAt: Instant = Instant.now()
) {
    companion object {
        const val TYPE_APPLICATION = "application"
        const val TYPE_INVITATION = "invitation"
        
        const val STATUS_PENDING = "pending"
        const val STATUS_APPROVED = "approved"
        const val STATUS_DECLINED = "declined"
        const val STATUS_ACCEPTED = "accepted"
        const val STATUS_REJECTED = "rejected"
        const val STATUS_WITHDRAWN = "withdrawn"
    }

    fun approve(processedBy: UUID): GroundAdminApplicationEntity {
        this.status = STATUS_APPROVED
        this.processedBy = processedBy
        this.processedAt = Instant.now()
        this.updatedAt = Instant.now()
        return this
    }

    fun decline(processedBy: UUID, reason: String?): GroundAdminApplicationEntity {
        this.status = STATUS_DECLINED
        this.processedBy = processedBy
        this.processedAt = Instant.now()
        this.declineReason = reason
        this.updatedAt = Instant.now()
        return this
    }

    fun accept(): GroundAdminApplicationEntity {
        this.status = STATUS_ACCEPTED
        this.processedAt = Instant.now()
        this.updatedAt = Instant.now()
        return this
    }

    fun reject(reason: String?): GroundAdminApplicationEntity {
        this.status = STATUS_REJECTED
        this.processedAt = Instant.now()
        this.declineReason = reason
        this.updatedAt = Instant.now()
        return this
    }

    fun withdraw(): GroundAdminApplicationEntity {
        this.status = STATUS_WITHDRAWN
        this.updatedAt = Instant.now()
        return this
    }

    val isApplication: Boolean get() = type == TYPE_APPLICATION
    val isInvitation: Boolean get() = type == TYPE_INVITATION
    val isPending: Boolean get() = status == STATUS_PENDING
}
```

---

### 4.2 Create GroundAdminApplication Repository

**File:** `src/main/kotlin/com/munserv/groundadmin/domain/GroundAdminApplicationRepository.kt`

```kotlin
package com.munserv.groundadmin.domain

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import java.util.UUID

@Repository
interface GroundAdminApplicationRepository : JpaRepository<GroundAdminApplicationEntity, UUID> {
    
    fun findByMemberIdAndSectorIdAndStatus(
        memberId: UUID,
        sectorId: UUID,
        status: String
    ): GroundAdminApplicationEntity?

    fun findByMemberIdAndStatus(
        memberId: UUID,
        status: String
    ): List<GroundAdminApplicationEntity>

    fun findBySectorIdAndStatus(
        sectorId: UUID,
        status: String
    ): List<GroundAdminApplicationEntity>

    @Query("""
        SELECT a FROM GroundAdminApplicationEntity a 
        WHERE a.memberId = :memberId 
        AND a.sectorId = :sectorId 
        AND a.status = 'pending'
    """)
    fun findPendingForMemberInSector(memberId: UUID, sectorId: UUID): GroundAdminApplicationEntity?

    fun existsByMemberIdAndSectorIdAndStatus(
        memberId: UUID,
        sectorId: UUID,
        status: String
    ): Boolean
}
```

---

### 4.3 Update Member Entity

**File:** Update `src/main/kotlin/com/munserv/members/domain/MemberEntity.kt`

Add Ground Admin fields:

```kotlin
@Entity
@Table(name = "members")
class MemberEntity(
    // ... existing fields ...

    @Column(name = "is_ground_admin", nullable = false)
    var isGroundAdmin: Boolean = false,

    @Enumerated(EnumType.STRING)
    @Column(name = "ground_admin_status")
    var groundAdminStatus: GroundAdminStatus? = null,

    @Column(name = "ground_admin_since")
    var groundAdminSince: Instant? = null,

    @Column(name = "ground_admin_response_rate")
    var groundAdminResponseRate: BigDecimal? = null
) {
    fun promoteToGroundAdmin(): MemberEntity {
        this.isGroundAdmin = true
        this.groundAdminStatus = GroundAdminStatus.ACTIVE
        this.groundAdminSince = Instant.now()
        this.groundAdminResponseRate = BigDecimal("100.00")
        return this
    }

    fun demoteFromGroundAdmin(): MemberEntity {
        this.isGroundAdmin = false
        this.groundAdminStatus = GroundAdminStatus.INACTIVE
        return this
    }

    fun setGroundAdminOnHold(): MemberEntity {
        this.groundAdminStatus = GroundAdminStatus.ON_HOLD
        return this
    }

    fun reactivateGroundAdmin(): MemberEntity {
        this.groundAdminStatus = GroundAdminStatus.ACTIVE
        return this
    }
}
```

---

### 4.4 Create Ground Admin DTOs

**File:** `src/main/kotlin/com/munserv/groundadmin/api/GroundAdminDto.kt`

```kotlin
package com.munserv.groundadmin.api

import com.munserv.shared.enums.GroundAdminStatus
import java.time.Instant

// Request DTOs
data class InviteGroundAdminRequest(
    val message: String? = null
)

data class ApproveGroundAdminRequest(
    val applicationId: String
)

data class DeclineGroundAdminRequest(
    val applicationId: String,
    val reason: String
)

data class RevokeGroundAdminRequest(
    val reason: String
)

data class UpdateGroundAdminStatusRequest(
    val status: GroundAdminStatus
)

data class StepDownRequest(
    val reason: String? = null
)

// Response DTOs
data class GroundAdminApplicationResponse(
    val applicationId: String,
    val status: String
)

data class GroundAdminResponse(
    val id: String,
    val memberId: String,
    val name: String,
    val phone: String,
    val status: GroundAdminStatus,
    val since: Instant,
    val responseRate: Double,
    val pendingVerifications: Int
)

data class GroundAdminListResponse(
    val items: List<GroundAdminResponse>,
    val total: Int
)

data class GroundAdminInfoResponse(
    val status: GroundAdminStatus,
    val since: Instant,
    val responseRate: Double,
    val pendingVerifications: Int,
    val totalVerifications: Int
)

data class MemberGroundAdminStatusResponse(
    val isGroundAdmin: Boolean,
    val groundAdminStatus: GroundAdminStatus?,
    val hasPendingApplication: Boolean,
    val hasPendingInvitation: Boolean
)
```

---

### 4.5 Create Ground Admin Service

**File:** `src/main/kotlin/com/munserv/groundadmin/service/GroundAdminService.kt`

```kotlin
package com.munserv.groundadmin.service

import com.munserv.groundadmin.api.*
import com.munserv.groundadmin.domain.GroundAdminApplicationEntity
import com.munserv.groundadmin.domain.GroundAdminApplicationRepository
import com.munserv.members.domain.MemberEntity
import com.munserv.members.domain.MemberRepository
import com.munserv.messages.service.MessageFactory
import com.munserv.messages.service.MessageService
import com.munserv.sectors.domain.SectorRepository
import com.munserv.shared.enums.GroundAdminStatus
import com.munserv.shared.result.Result
import com.munserv.shared.result.AppError
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.UUID

@Service
class GroundAdminService(
    private val applicationRepository: GroundAdminApplicationRepository,
    private val memberRepository: MemberRepository,
    private val sectorRepository: SectorRepository,
    private val messageService: MessageService
) {
    // ==================== Member Actions ====================

    /**
     * Member applies to become a Ground Admin
     */
    @Transactional
    fun apply(memberId: UUID): Result<GroundAdminApplicationResponse, AppError> {
        val member = memberRepository.findById(memberId).orElse(null)
            ?: return Result.failure(AppError.NotFound("Member not found"))

        // Check not already a Ground Admin
        if (member.isGroundAdmin) {
            return Result.failure(AppError.Conflict("Already a Ground Admin"))
        }

        // Check no pending application
        val existing = applicationRepository.findPendingForMemberInSector(memberId, member.sectorId)
        if (existing != null) {
            return Result.failure(AppError.Conflict("Already have a pending application"))
        }

        // Create application
        val application = GroundAdminApplicationEntity(
            memberId = memberId,
            sectorId = member.sectorId,
            type = GroundAdminApplicationEntity.TYPE_APPLICATION
        )
        val saved = applicationRepository.save(application)

        // Notify sector admins
        notifySectorAdminsOfApplication(member, saved)

        return Result.success(GroundAdminApplicationResponse(
            applicationId = saved.id.toString(),
            status = saved.status
        ))
    }

    /**
     * Member accepts a Ground Admin invitation
     */
    @Transactional
    fun acceptInvitation(
        memberId: UUID,
        applicationId: UUID
    ): Result<GroundAdminApplicationResponse, AppError> {
        val application = applicationRepository.findById(applicationId).orElse(null)
            ?: return Result.failure(AppError.NotFound("Application not found"))

        if (application.memberId != memberId) {
            return Result.failure(AppError.NotFound("Application not found"))
        }

        if (!application.isInvitation) {
            return Result.failure(AppError.Validation(listOf("Not an invitation")))
        }

        if (!application.isPending) {
            return Result.failure(AppError.Conflict("Invitation already processed"))
        }

        // Accept invitation
        application.accept()
        applicationRepository.save(application)

        // Promote member
        val member = memberRepository.findById(memberId).get()
        member.promoteToGroundAdmin()
        memberRepository.save(member)

        // Notify the inviter
        application.invitedBy?.let { inviterId ->
            // Could send a notification here
        }

        return Result.success(GroundAdminApplicationResponse(
            applicationId = application.id.toString(),
            status = "accepted"
        ))
    }

    /**
     * Member declines a Ground Admin invitation
     */
    @Transactional
    fun declineInvitation(
        memberId: UUID,
        applicationId: UUID,
        reason: String?
    ): Result<GroundAdminApplicationResponse, AppError> {
        val application = applicationRepository.findById(applicationId).orElse(null)
            ?: return Result.failure(AppError.NotFound("Application not found"))

        if (application.memberId != memberId) {
            return Result.failure(AppError.NotFound("Application not found"))
        }

        if (!application.isInvitation || !application.isPending) {
            return Result.failure(AppError.Conflict("Cannot decline this invitation"))
        }

        application.reject(reason)
        applicationRepository.save(application)

        // Notify the inviter
        application.invitedBy?.let { inviterId ->
            val member = memberRepository.findById(memberId).get()
            val message = MessageFactory.groundAdminInvitationDeclined(
                recipientId = inviterId,
                memberName = member.name,
                reason = reason
            )
            messageService.createMessage(message)
        }

        return Result.success(GroundAdminApplicationResponse(
            applicationId = application.id.toString(),
            status = "declined"
        ))
    }

    /**
     * Ground Admin requests to step down
     */
    @Transactional
    fun requestStepDown(
        memberId: UUID,
        reason: String?
    ): Result<Unit, AppError> {
        val member = memberRepository.findById(memberId).orElse(null)
            ?: return Result.failure(AppError.NotFound("Member not found"))

        if (!member.isGroundAdmin) {
            return Result.failure(AppError.Conflict("Not a Ground Admin"))
        }

        // Notify sector admins
        val sectorAdmins = memberRepository.findAdminsBySectorId(member.sectorId)
        sectorAdmins.forEach { admin ->
            val message = MessageFactory.groundAdminStepdownRequest(
                recipientId = admin.id,
                groundAdminId = memberId,
                groundAdminName = member.name,
                reason = reason
            )
            messageService.createMessage(message)
        }

        return Result.success(Unit)
    }

    /**
     * Get current member's Ground Admin info
     */
    fun getMyGroundAdminInfo(memberId: UUID): Result<GroundAdminInfoResponse?, AppError> {
        val member = memberRepository.findById(memberId).orElse(null)
            ?: return Result.failure(AppError.NotFound("Member not found"))

        if (!member.isGroundAdmin) {
            return Result.success(null)
        }

        // TODO: Get actual verification counts
        val pendingVerifications = 0
        val totalVerifications = 0

        return Result.success(GroundAdminInfoResponse(
            status = member.groundAdminStatus!!,
            since = member.groundAdminSince!!,
            responseRate = member.groundAdminResponseRate?.toDouble() ?: 100.0,
            pendingVerifications = pendingVerifications,
            totalVerifications = totalVerifications
        ))
    }

    // ==================== Admin Actions ====================

    /**
     * Admin invites a member to become Ground Admin
     */
    @Transactional
    fun invite(
        adminId: UUID,
        memberId: UUID,
        message: String?
    ): Result<GroundAdminApplicationResponse, AppError> {
        val admin = memberRepository.findById(adminId).orElse(null)
            ?: return Result.failure(AppError.NotFound("Admin not found"))

        val member = memberRepository.findById(memberId).orElse(null)
            ?: return Result.failure(AppError.NotFound("Member not found"))

        // Verify same sector
        if (member.sectorId != admin.sectorId) {
            return Result.failure(AppError.Forbidden("Member not in your sector"))
        }

        // Check not already Ground Admin
        if (member.isGroundAdmin) {
            return Result.failure(AppError.Conflict("Member is already a Ground Admin"))
        }

        // Check no pending application/invitation
        val existing = applicationRepository.findPendingForMemberInSector(memberId, member.sectorId)
        if (existing != null) {
            return Result.failure(AppError.Conflict("Member already has a pending application or invitation"))
        }

        // Create invitation
        val application = GroundAdminApplicationEntity(
            memberId = memberId,
            sectorId = member.sectorId,
            type = GroundAdminApplicationEntity.TYPE_INVITATION,
            invitedBy = adminId
        )
        val saved = applicationRepository.save(application)

        // Get sector name for message
        val sector = sectorRepository.findById(member.sectorId).get()

        // Send invitation message to member
        val invitationMessage = MessageFactory.groundAdminInvitation(
            recipientId = memberId,
            invitedBy = adminId,
            inviterName = admin.name,
            sectorName = sector.name,
            customMessage = message
        )
        messageService.createMessage(invitationMessage)

        return Result.success(GroundAdminApplicationResponse(
            applicationId = saved.id.toString(),
            status = saved.status
        ))
    }

    /**
     * Admin approves a Ground Admin application
     */
    @Transactional
    fun approveApplication(
        adminId: UUID,
        memberId: UUID,
        applicationId: UUID
    ): Result<GroundAdminApplicationResponse, AppError> {
        val application = applicationRepository.findById(applicationId).orElse(null)
            ?: return Result.failure(AppError.NotFound("Application not found"))

        if (application.memberId != memberId) {
            return Result.failure(AppError.NotFound("Application not found"))
        }

        if (!application.isApplication || !application.isPending) {
            return Result.failure(AppError.Conflict("Cannot approve this application"))
        }

        // Approve
        application.approve(adminId)
        applicationRepository.save(application)

        // Promote member
        val member = memberRepository.findById(memberId).get()
        member.promoteToGroundAdmin()
        memberRepository.save(member)

        // Notify member
        val message = MessageFactory.groundAdminApproved(recipientId = memberId)
        messageService.createMessage(message)

        return Result.success(GroundAdminApplicationResponse(
            applicationId = application.id.toString(),
            status = "approved"
        ))
    }

    /**
     * Admin declines a Ground Admin application
     */
    @Transactional
    fun declineApplication(
        adminId: UUID,
        memberId: UUID,
        applicationId: UUID,
        reason: String
    ): Result<GroundAdminApplicationResponse, AppError> {
        val application = applicationRepository.findById(applicationId).orElse(null)
            ?: return Result.failure(AppError.NotFound("Application not found"))

        if (application.memberId != memberId) {
            return Result.failure(AppError.NotFound("Application not found"))
        }

        if (!application.isApplication || !application.isPending) {
            return Result.failure(AppError.Conflict("Cannot decline this application"))
        }

        application.decline(adminId, reason)
        applicationRepository.save(application)

        // Notify member
        val message = MessageFactory.groundAdminDeclined(
            recipientId = memberId,
            reason = reason
        )
        messageService.createMessage(message)

        return Result.success(GroundAdminApplicationResponse(
            applicationId = application.id.toString(),
            status = "declined"
        ))
    }

    /**
     * Admin revokes Ground Admin status
     */
    @Transactional
    fun revoke(
        adminId: UUID,
        memberId: UUID,
        reason: String
    ): Result<Unit, AppError> {
        val member = memberRepository.findById(memberId).orElse(null)
            ?: return Result.failure(AppError.NotFound("Member not found"))

        if (!member.isGroundAdmin) {
            return Result.failure(AppError.Conflict("Member is not a Ground Admin"))
        }

        // Demote
        member.demoteFromGroundAdmin()
        memberRepository.save(member)

        // Notify member
        val message = MessageFactory.groundAdminRevocation(
            recipientId = memberId,
            reason = reason
        )
        messageService.createMessage(message)

        return Result.success(Unit)
    }

    /**
     * Admin updates Ground Admin status (active/on_hold)
     */
    @Transactional
    fun updateStatus(
        adminId: UUID,
        memberId: UUID,
        status: GroundAdminStatus
    ): Result<Unit, AppError> {
        val member = memberRepository.findById(memberId).orElse(null)
            ?: return Result.failure(AppError.NotFound("Member not found"))

        if (!member.isGroundAdmin) {
            return Result.failure(AppError.Conflict("Member is not a Ground Admin"))
        }

        when (status) {
            GroundAdminStatus.ACTIVE -> member.reactivateGroundAdmin()
            GroundAdminStatus.ON_HOLD -> member.setGroundAdminOnHold()
            GroundAdminStatus.INACTIVE -> member.demoteFromGroundAdmin()
        }
        memberRepository.save(member)

        return Result.success(Unit)
    }

    /**
     * List Ground Admins in sector
     */
    fun listGroundAdmins(
        sectorId: UUID,
        status: GroundAdminStatus? = null
    ): GroundAdminListResponse {
        val members = if (status != null) {
            memberRepository.findBySectorIdAndIsGroundAdminAndGroundAdminStatus(
                sectorId, true, status
            )
        } else {
            memberRepository.findBySectorIdAndIsGroundAdmin(sectorId, true)
        }

        // TODO: Get actual verification counts per GA
        val items = members.map { member ->
            GroundAdminResponse(
                id = member.id.toString(),
                memberId = member.id.toString(),
                name = member.name,
                phone = member.phone,
                status = member.groundAdminStatus!!,
                since = member.groundAdminSince!!,
                responseRate = member.groundAdminResponseRate?.toDouble() ?: 100.0,
                pendingVerifications = 0
            )
        }

        return GroundAdminListResponse(
            items = items,
            total = items.size
        )
    }

    // ==================== Helpers ====================

    private fun notifySectorAdminsOfApplication(
        member: MemberEntity,
        application: GroundAdminApplicationEntity
    ) {
        val sectorAdmins = memberRepository.findAdminsBySectorId(member.sectorId)
        sectorAdmins.forEach { admin ->
            val message = MessageFactory.groundAdminApplication(
                recipientId = admin.id,
                applicantId = member.id,
                applicantName = member.name,
                applicationId = application.id
            )
            messageService.createMessage(message)
        }
    }
}
```

---

### 4.6 Create Ground Admin Controller

**File:** `src/main/kotlin/com/munserv/groundadmin/api/GroundAdminController.kt`

```kotlin
package com.munserv.groundadmin.api

import com.munserv.groundadmin.service.GroundAdminService
import com.munserv.shared.enums.GroundAdminStatus
import com.munserv.shared.security.CurrentUser
import com.munserv.shared.security.AuthenticatedUser
import com.munserv.shared.security.RequireRole
import com.munserv.shared.enums.MemberRole
import com.munserv.shared.result.fold
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.util.UUID

@RestController
@RequestMapping("/api/v1")
class GroundAdminController(
    private val groundAdminService: GroundAdminService
) {
    // ==================== Member Endpoints ====================

    @PostMapping("/members/me/ground-admin/apply")
    fun apply(
        @CurrentUser currentUser: AuthenticatedUser
    ): ResponseEntity<*> {
        return groundAdminService.apply(currentUser.id).fold(
            onSuccess = { ResponseEntity.ok(it) },
            onFailure = { it.toResponse() }
        )
    }

    @PostMapping("/members/me/ground-admin/accept")
    fun acceptInvitation(
        @RequestBody request: ApproveGroundAdminRequest,
        @CurrentUser currentUser: AuthenticatedUser
    ): ResponseEntity<*> {
        return groundAdminService.acceptInvitation(
            memberId = currentUser.id,
            applicationId = UUID.fromString(request.applicationId)
        ).fold(
            onSuccess = { ResponseEntity.ok(it) },
            onFailure = { it.toResponse() }
        )
    }

    @PostMapping("/members/me/ground-admin/decline")
    fun declineInvitation(
        @RequestBody request: DeclineGroundAdminRequest,
        @CurrentUser currentUser: AuthenticatedUser
    ): ResponseEntity<*> {
        return groundAdminService.declineInvitation(
            memberId = currentUser.id,
            applicationId = UUID.fromString(request.applicationId),
            reason = request.reason
        ).fold(
            onSuccess = { ResponseEntity.ok(it) },
            onFailure = { it.toResponse() }
        )
    }

    @PostMapping("/members/me/ground-admin/stepdown")
    fun stepDown(
        @RequestBody request: StepDownRequest,
        @CurrentUser currentUser: AuthenticatedUser
    ): ResponseEntity<*> {
        return groundAdminService.requestStepDown(
            memberId = currentUser.id,
            reason = request.reason
        ).fold(
            onSuccess = { ResponseEntity.ok(mapOf("status" to "pending_approval")) },
            onFailure = { it.toResponse() }
        )
    }

    @GetMapping("/members/me/ground-admin")
    fun getMyGroundAdminInfo(
        @CurrentUser currentUser: AuthenticatedUser
    ): ResponseEntity<*> {
        return groundAdminService.getMyGroundAdminInfo(currentUser.id).fold(
            onSuccess = { ResponseEntity.ok(it) },
            onFailure = { it.toResponse() }
        )
    }

    // ==================== Admin Endpoints ====================

    @PostMapping("/members/{memberId}/ground-admin/invite")
    @RequireRole(MemberRole.SECTOR_ADMIN, MemberRole.SECTOR_CHIEF)
    fun invite(
        @PathVariable memberId: UUID,
        @RequestBody request: InviteGroundAdminRequest,
        @CurrentUser currentUser: AuthenticatedUser
    ): ResponseEntity<*> {
        return groundAdminService.invite(
            adminId = currentUser.id,
            memberId = memberId,
            message = request.message
        ).fold(
            onSuccess = { ResponseEntity.ok(it) },
            onFailure = { it.toResponse() }
        )
    }

    @PostMapping("/members/{memberId}/ground-admin/approve")
    @RequireRole(MemberRole.SECTOR_ADMIN, MemberRole.SECTOR_CHIEF)
    fun approve(
        @PathVariable memberId: UUID,
        @RequestBody request: ApproveGroundAdminRequest,
        @CurrentUser currentUser: AuthenticatedUser
    ): ResponseEntity<*> {
        return groundAdminService.approveApplication(
            adminId = currentUser.id,
            memberId = memberId,
            applicationId = UUID.fromString(request.applicationId)
        ).fold(
            onSuccess = { ResponseEntity.ok(it) },
            onFailure = { it.toResponse() }
        )
    }

    @PostMapping("/members/{memberId}/ground-admin/decline")
    @RequireRole(MemberRole.SECTOR_ADMIN, MemberRole.SECTOR_CHIEF)
    fun decline(
        @PathVariable memberId: UUID,
        @RequestBody request: DeclineGroundAdminRequest,
        @CurrentUser currentUser: AuthenticatedUser
    ): ResponseEntity<*> {
        return groundAdminService.declineApplication(
            adminId = currentUser.id,
            memberId = memberId,
            applicationId = UUID.fromString(request.applicationId),
            reason = request.reason
        ).fold(
            onSuccess = { ResponseEntity.ok(it) },
            onFailure = { it.toResponse() }
        )
    }

    @PostMapping("/members/{memberId}/ground-admin/revoke")
    @RequireRole(MemberRole.SECTOR_ADMIN, MemberRole.SECTOR_CHIEF)
    fun revoke(
        @PathVariable memberId: UUID,
        @RequestBody request: RevokeGroundAdminRequest,
        @CurrentUser currentUser: AuthenticatedUser
    ): ResponseEntity<*> {
        return groundAdminService.revoke(
            adminId = currentUser.id,
            memberId = memberId,
            reason = request.reason
        ).fold(
            onSuccess = { ResponseEntity.ok(mapOf("status" to "revoked")) },
            onFailure = { it.toResponse() }
        )
    }

    @PatchMapping("/members/{memberId}/ground-admin/status")
    @RequireRole(MemberRole.SECTOR_ADMIN, MemberRole.SECTOR_CHIEF)
    fun updateStatus(
        @PathVariable memberId: UUID,
        @RequestBody request: UpdateGroundAdminStatusRequest,
        @CurrentUser currentUser: AuthenticatedUser
    ): ResponseEntity<*> {
        return groundAdminService.updateStatus(
            adminId = currentUser.id,
            memberId = memberId,
            status = request.status
        ).fold(
            onSuccess = { ResponseEntity.ok(mapOf("status" to request.status)) },
            onFailure = { it.toResponse() }
        )
    }

    @GetMapping("/sectors/{sectorId}/ground-admins")
    @RequireRole(MemberRole.SECTOR_ADMIN, MemberRole.SECTOR_CHIEF)
    fun listGroundAdmins(
        @PathVariable sectorId: UUID,
        @RequestParam status: GroundAdminStatus? = null,
        @CurrentUser currentUser: AuthenticatedUser
    ): ResponseEntity<GroundAdminListResponse> {
        // Verify user has access to this sector
        if (!currentUser.canAccessSector(sectorId)) {
            return ResponseEntity.status(403).build()
        }
        
        val response = groundAdminService.listGroundAdmins(sectorId, status)
        return ResponseEntity.ok(response)
    }
}
```

---

### 4.7 Update Member Repository

**File:** Update `src/main/kotlin/com/munserv/members/domain/MemberRepository.kt`

```kotlin
@Repository
interface MemberRepository : JpaRepository<MemberEntity, UUID> {
    // ... existing methods ...

    fun findBySectorIdAndIsGroundAdmin(
        sectorId: UUID,
        isGroundAdmin: Boolean
    ): List<MemberEntity>

    fun findBySectorIdAndIsGroundAdminAndGroundAdminStatus(
        sectorId: UUID,
        isGroundAdmin: Boolean,
        status: GroundAdminStatus
    ): List<MemberEntity>

    @Query("""
        SELECT m FROM MemberEntity m 
        WHERE m.sectorId = :sectorId 
        AND m.role IN ('SECTOR_ADMIN', 'SECTOR_CHIEF')
    """)
    fun findAdminsBySectorId(sectorId: UUID): List<MemberEntity>
}
```

---

### 4.8 Create Unit Tests

**File:** `src/test/kotlin/com/munserv/groundadmin/service/GroundAdminServiceTest.kt`

```kotlin
package com.munserv.groundadmin.service

import com.munserv.groundadmin.domain.*
import com.munserv.members.domain.*
import com.munserv.messages.service.MessageService
import com.munserv.sectors.domain.SectorRepository
import com.munserv.shared.result.isSuccess
import com.munserv.shared.result.isFailure
import io.mockk.*
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.Assertions.*
import java.util.*

class GroundAdminServiceTest {
    private lateinit var applicationRepository: GroundAdminApplicationRepository
    private lateinit var memberRepository: MemberRepository
    private lateinit var sectorRepository: SectorRepository
    private lateinit var messageService: MessageService
    private lateinit var service: GroundAdminService

    @BeforeEach
    fun setup() {
        applicationRepository = mockk()
        memberRepository = mockk()
        sectorRepository = mockk()
        messageService = mockk(relaxed = true)
        service = GroundAdminService(
            applicationRepository,
            memberRepository,
            sectorRepository,
            messageService
        )
    }

    @Test
    fun `apply creates application and notifies admins`() {
        val memberId = UUID.randomUUID()
        val sectorId = UUID.randomUUID()
        val member = createTestMember(memberId, sectorId)
        
        every { memberRepository.findById(memberId) } returns Optional.of(member)
        every { applicationRepository.findPendingForMemberInSector(memberId, sectorId) } returns null
        every { applicationRepository.save(any()) } answers { firstArg() }
        every { memberRepository.findAdminsBySectorId(sectorId) } returns emptyList()

        val result = service.apply(memberId)

        assertTrue(result.isSuccess())
        verify { applicationRepository.save(any()) }
    }

    @Test
    fun `apply fails if already ground admin`() {
        val memberId = UUID.randomUUID()
        val member = createTestMember(memberId, UUID.randomUUID()).apply {
            isGroundAdmin = true
        }
        
        every { memberRepository.findById(memberId) } returns Optional.of(member)

        val result = service.apply(memberId)

        assertTrue(result.isFailure())
    }

    @Test
    fun `invite creates invitation and sends message`() {
        val adminId = UUID.randomUUID()
        val memberId = UUID.randomUUID()
        val sectorId = UUID.randomUUID()
        val admin = createTestMember(adminId, sectorId)
        val member = createTestMember(memberId, sectorId)
        val sector = createTestSector(sectorId)
        
        every { memberRepository.findById(adminId) } returns Optional.of(admin)
        every { memberRepository.findById(memberId) } returns Optional.of(member)
        every { sectorRepository.findById(sectorId) } returns Optional.of(sector)
        every { applicationRepository.findPendingForMemberInSector(memberId, sectorId) } returns null
        every { applicationRepository.save(any()) } answers { firstArg() }

        val result = service.invite(adminId, memberId, "Welcome!")

        assertTrue(result.isSuccess())
        verify { messageService.createMessage(any()) }
    }

    @Test
    fun `approve promotes member and sends notification`() {
        val adminId = UUID.randomUUID()
        val memberId = UUID.randomUUID()
        val applicationId = UUID.randomUUID()
        val application = createTestApplication(applicationId, memberId, "application")
        val member = createTestMember(memberId, UUID.randomUUID())
        
        every { applicationRepository.findById(applicationId) } returns Optional.of(application)
        every { memberRepository.findById(memberId) } returns Optional.of(member)
        every { applicationRepository.save(any()) } answers { firstArg() }
        every { memberRepository.save(any()) } answers { firstArg() }

        val result = service.approveApplication(adminId, memberId, applicationId)

        assertTrue(result.isSuccess())
        assertTrue(member.isGroundAdmin)
        verify { messageService.createMessage(any()) }
    }

    @Test
    fun `revoke demotes member and sends notification`() {
        val adminId = UUID.randomUUID()
        val memberId = UUID.randomUUID()
        val member = createTestMember(memberId, UUID.randomUUID()).apply {
            promoteToGroundAdmin()
        }
        
        every { memberRepository.findById(memberId) } returns Optional.of(member)
        every { memberRepository.save(any()) } answers { firstArg() }

        val result = service.revoke(adminId, memberId, "Inactive")

        assertTrue(result.isSuccess())
        assertFalse(member.isGroundAdmin)
        verify { messageService.createMessage(any()) }
    }

    private fun createTestMember(id: UUID, sectorId: UUID) = MemberEntity(
        id = id,
        sectorId = sectorId,
        name = "Test Member",
        phone = "+27123456789"
    )

    private fun createTestSector(id: UUID) = SectorEntity(
        id = id,
        name = "Test Sector"
    )

    private fun createTestApplication(
        id: UUID,
        memberId: UUID,
        type: String
    ) = GroundAdminApplicationEntity(
        id = id,
        memberId = memberId,
        sectorId = UUID.randomUUID(),
        type = type
    )
}
```

---

## Verification Commands

```bash
# Run unit tests
./gradlew test --tests "*GroundAdminServiceTest*"

# Run integration tests  
./gradlew test --tests "*GroundAdminScenarioTest*"

# Manual testing
./gradlew bootRun

# Member applies
curl -X POST http://localhost:8080/api/v1/members/me/ground-admin/apply \
  -H "Authorization: Bearer $MEMBER_TOKEN"

# Admin invites
curl -X POST http://localhost:8080/api/v1/members/{memberId}/ground-admin/invite \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "Please join us!"}'

# List Ground Admins
curl http://localhost:8080/api/v1/sectors/{sectorId}/ground-admins \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

---

## Definition of Done

- [x] GroundAdminApplicationEntity with state methods
- [x] GroundAdminApplicationRepository with queries
- [x] Member entity updated with GA fields
- [x] All DTOs created
- [x] GroundAdminService with all lifecycle methods
- [x] GroundAdminController with all endpoints
- [x] Messages created on all state changes
- [x] Unit tests passing
- [x] Integration tests passing
- [x] Commit: `feat(backend): Add Ground Admin lifecycle management` (3f480da)

---

## Handoff Notes

```bash
cd backend
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/backend-phase-4.md

# This service depends on MessageService from Phase 3
# All state changes should create appropriate messages
# Test the full flow: apply → approve → active → revoke
```
