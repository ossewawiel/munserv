package com.munserv.groundadmin.domain

import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import java.time.Instant

/**
 * Domain entity representing a Ground Admin application or invitation.
 *
 * Applications are member-initiated requests to become a Ground Admin.
 * Invitations are admin-initiated offers to become a Ground Admin.
 *
 * This is a pure domain class with no framework dependencies.
 */
data class GroundAdminApplication(
    val id: GroundAdminApplicationId,
    val memberId: MemberId,
    val sectorId: SectorId,
    val type: ApplicationType,
    val invitedBy: MemberId? = null,
    val status: ApplicationStatus = ApplicationStatus.PENDING,
    val processedBy: MemberId? = null,
    val processedAt: Instant? = null,
    val declineReason: String? = null,
    val createdAt: Instant = Instant.now(),
    val updatedAt: Instant = Instant.now(),
) {
    /**
     * True if this is a member-initiated application.
     */
    val isApplication: Boolean
        get() = type == ApplicationType.APPLICATION

    /**
     * True if this is an admin-initiated invitation.
     */
    val isInvitation: Boolean
        get() = type == ApplicationType.INVITATION

    /**
     * True if this application/invitation is still pending.
     */
    val isPending: Boolean
        get() = status == ApplicationStatus.PENDING

    /**
     * Admin approves a member's application.
     * Transitions status from PENDING to APPROVED.
     */
    fun approve(processedBy: MemberId): GroundAdminApplication =
        copy(
            status = ApplicationStatus.APPROVED,
            processedBy = processedBy,
            processedAt = Instant.now(),
            updatedAt = Instant.now(),
        )

    /**
     * Admin declines a member's application.
     * Transitions status from PENDING to DECLINED.
     */
    fun decline(
        processedBy: MemberId,
        reason: String?,
    ): GroundAdminApplication =
        copy(
            status = ApplicationStatus.DECLINED,
            processedBy = processedBy,
            processedAt = Instant.now(),
            declineReason = reason,
            updatedAt = Instant.now(),
        )

    /**
     * Member accepts an invitation.
     * Transitions status from PENDING to ACCEPTED.
     */
    fun accept(): GroundAdminApplication =
        copy(
            status = ApplicationStatus.ACCEPTED,
            processedAt = Instant.now(),
            updatedAt = Instant.now(),
        )

    /**
     * Member rejects an invitation.
     * Transitions status from PENDING to REJECTED.
     */
    fun reject(reason: String?): GroundAdminApplication =
        copy(
            status = ApplicationStatus.REJECTED,
            processedAt = Instant.now(),
            declineReason = reason,
            updatedAt = Instant.now(),
        )

    /**
     * Member withdraws their application.
     * Transitions status from PENDING to WITHDRAWN.
     */
    fun withdraw(): GroundAdminApplication =
        copy(
            status = ApplicationStatus.WITHDRAWN,
            updatedAt = Instant.now(),
        )

    companion object {
        /**
         * Creates a new application (member-initiated).
         */
        fun createApplication(
            memberId: MemberId,
            sectorId: SectorId,
        ): GroundAdminApplication =
            GroundAdminApplication(
                id = GroundAdminApplicationId.generate(),
                memberId = memberId,
                sectorId = sectorId,
                type = ApplicationType.APPLICATION,
            )

        /**
         * Creates a new invitation (admin-initiated).
         */
        fun createInvitation(
            memberId: MemberId,
            sectorId: SectorId,
            invitedBy: MemberId,
        ): GroundAdminApplication =
            GroundAdminApplication(
                id = GroundAdminApplicationId.generate(),
                memberId = memberId,
                sectorId = sectorId,
                type = ApplicationType.INVITATION,
                invitedBy = invitedBy,
            )
    }
}
