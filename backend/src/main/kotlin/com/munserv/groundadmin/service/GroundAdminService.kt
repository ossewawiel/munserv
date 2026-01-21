package com.munserv.groundadmin.service

import com.munserv.admin.repository.AdminRepository
import com.munserv.auth.repository.MemberRepository
import com.munserv.groundadmin.api.GroundAdminInfoResponse
import com.munserv.groundadmin.api.GroundAdminListResponse
import com.munserv.groundadmin.api.GroundAdminResponse
import com.munserv.groundadmin.domain.GroundAdminApplication
import com.munserv.groundadmin.domain.GroundAdminApplicationId
import com.munserv.groundadmin.repository.GroundAdminApplicationRepository
import com.munserv.messages.domain.MessageEntity
import com.munserv.messages.service.MessageService
import com.munserv.sectors.repository.SectorRepository
import com.munserv.shared.enums.GroundAdminStatus
import com.munserv.shared.enums.MessageType
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

/**
 * Service for Ground Admin lifecycle management.
 *
 * Handles:
 * - Member applications to become Ground Admin
 * - Admin invitations to members
 * - Application approval/decline
 * - Invitation acceptance/rejection
 * - Ground Admin status management
 * - Step-down requests
 */
@Service
class GroundAdminService(
    private val applicationRepository: GroundAdminApplicationRepository,
    private val memberRepository: MemberRepository,
    private val adminRepository: AdminRepository,
    private val sectorRepository: SectorRepository,
    private val messageService: MessageService,
) {
    companion object {
        private const val ERROR_APPLICATION_NOT_FOUND = "Application not found"
        private const val ERROR_MEMBER_NOT_FOUND = "Member not found"
    }

    // ==================== Member Actions ====================

    /**
     * Member applies to become a Ground Admin.
     */
    @Transactional
    fun apply(memberId: MemberId): GroundAdminResult {
        val member =
            memberRepository.findById(memberId)
                ?: return GroundAdminResult.NotFound(ERROR_MEMBER_NOT_FOUND)

        if (member.isGroundAdmin) {
            return GroundAdminResult.Conflict("Already a Ground Admin")
        }

        val existing = applicationRepository.findPendingForMemberInSector(memberId, member.sectorId)
        if (existing != null) {
            return GroundAdminResult.Conflict("Already have a pending application")
        }

        val application = GroundAdminApplication.createApplication(memberId, member.sectorId)
        val saved = applicationRepository.save(application)

        // Notify sector admins
        notifySectorAdminsOfApplication(member.sectorId, memberId, member.fullName, saved.id)

        return GroundAdminResult.Success(mapOf("applicationId" to saved.id.toString(), "status" to "pending"))
    }

    /**
     * Member accepts a Ground Admin invitation.
     */
    @Transactional
    fun acceptInvitation(
        memberId: MemberId,
        applicationId: GroundAdminApplicationId,
    ): GroundAdminResult {
        val application =
            applicationRepository.findById(applicationId)
                ?: return GroundAdminResult.NotFound(ERROR_APPLICATION_NOT_FOUND)

        if (application.memberId != memberId) {
            return GroundAdminResult.NotFound(ERROR_APPLICATION_NOT_FOUND)
        }

        if (!application.isInvitation) {
            return GroundAdminResult.ValidationError(listOf("Not an invitation"))
        }

        if (!application.isPending) {
            return GroundAdminResult.Conflict("Invitation already processed")
        }

        // Accept invitation
        val accepted = application.accept()
        applicationRepository.save(accepted)

        // Promote member
        val member = memberRepository.findById(memberId)!!
        val promoted = member.promoteToGroundAdmin()
        memberRepository.save(promoted)

        // Notify the inviter
        application.invitedBy?.let { inviterId ->
            val message =
                MessageEntity(
                    type = MessageType.GROUND_ADMIN_INVITATION_ACCEPTED,
                    title = "Ground Admin Invitation Accepted",
                    body = "${member.fullName} has accepted your invitation to become a Ground Admin.",
                    recipientId = inviterId.value,
                    recipientType = "admin",
                    senderId = memberId.value,
                    senderType = "member",
                    relatedEntityId = memberId.value,
                    relatedEntityType = "member",
                    actionType = "view",
                )
            messageService.createMessage(message)
        }

        return GroundAdminResult.Success(mapOf("applicationId" to application.id.toString(), "status" to "accepted"))
    }

    /**
     * Member declines a Ground Admin invitation.
     */
    @Transactional
    fun declineInvitation(
        memberId: MemberId,
        applicationId: GroundAdminApplicationId,
        reason: String?,
    ): GroundAdminResult {
        val application =
            applicationRepository.findById(applicationId)
                ?: return GroundAdminResult.NotFound(ERROR_APPLICATION_NOT_FOUND)

        if (application.memberId != memberId) {
            return GroundAdminResult.NotFound(ERROR_APPLICATION_NOT_FOUND)
        }

        if (!application.isInvitation || !application.isPending) {
            return GroundAdminResult.Conflict("Cannot decline this invitation")
        }

        val rejected = application.reject(reason)
        applicationRepository.save(rejected)

        // Notify the inviter
        application.invitedBy?.let { inviterId ->
            val member = memberRepository.findById(memberId)!!
            val message =
                MessageEntity(
                    type = MessageType.GROUND_ADMIN_INVITATION_DECLINED,
                    title = "Ground Admin Invitation Declined",
                    body = "${member.fullName} has declined your Ground Admin invitation${reason?.let { ": $it" } ?: "."}",
                    recipientId = inviterId.value,
                    recipientType = "member",
                    senderId = memberId.value,
                    senderType = "member",
                    actionType = "acknowledge",
                )
            messageService.createMessage(message)
        }

        return GroundAdminResult.Success(mapOf("applicationId" to application.id.toString(), "status" to "declined"))
    }

    /**
     * Ground Admin requests to step down.
     */
    @Transactional
    fun requestStepDown(
        memberId: MemberId,
        reason: String?,
    ): GroundAdminResult {
        val member =
            memberRepository.findById(memberId)
                ?: return GroundAdminResult.NotFound(ERROR_MEMBER_NOT_FOUND)

        if (!member.isGroundAdmin) {
            return GroundAdminResult.Conflict("Not a Ground Admin")
        }

        // Notify sector admins
        val admins = memberRepository.findAdminsBySectorId(member.sectorId)
        admins.forEach { admin ->
            val message =
                MessageEntity(
                    type = MessageType.GROUND_ADMIN_STEPDOWN_REQUEST,
                    title = "Ground Admin Step Down Request",
                    body = "${member.fullName} has requested to step down as Ground Admin${reason?.let { ": $it" } ?: "."}",
                    recipientId = admin.id.value,
                    recipientType = "member",
                    senderId = memberId.value,
                    senderType = "member",
                    relatedEntityId = memberId.value,
                    relatedEntityType = "member",
                    actionType = "approve_reject",
                )
            messageService.createMessage(message)
        }

        return GroundAdminResult.Success(mapOf("status" to "pending_approval"))
    }

    /**
     * Get current member's Ground Admin info.
     */
    fun getMyGroundAdminInfo(memberId: MemberId): GroundAdminResult {
        val member =
            memberRepository.findById(memberId)
                ?: return GroundAdminResult.NotFound(ERROR_MEMBER_NOT_FOUND)

        if (!member.isGroundAdmin) {
            return GroundAdminResult.Success(null)
        }

        // TODO: Get actual verification counts from verification service
        val info =
            GroundAdminInfoResponse(
                status = member.groundAdminStatus!!,
                since = member.groundAdminSince!!,
                responseRate = member.groundAdminResponseRate?.toDouble() ?: 100.0,
                pendingVerifications = 0,
                totalVerifications = 0,
            )

        return GroundAdminResult.Success(info)
    }

    // ==================== Admin Actions ====================

    /**
     * Admin invites a member to become Ground Admin.
     */
    @Transactional
    fun invite(
        adminId: MemberId,
        memberId: MemberId,
        message: String?,
    ): GroundAdminResult {
        // Look up admin from admins table (not members table)
        val admin =
            adminRepository.findById(AdminId(adminId.value))
                ?: return GroundAdminResult.NotFound("Admin not found")

        val member =
            memberRepository.findById(memberId)
                ?: return GroundAdminResult.NotFound(ERROR_MEMBER_NOT_FOUND)

        if (member.sectorId != admin.sectorId) {
            return GroundAdminResult.Forbidden("Member not in your sector")
        }

        if (member.isGroundAdmin) {
            return GroundAdminResult.Conflict("Member is already a Ground Admin")
        }

        val existing = applicationRepository.findPendingForMemberInSector(memberId, member.sectorId)
        if (existing != null) {
            return GroundAdminResult.Conflict("Member already has a pending application or invitation")
        }

        val invitation = GroundAdminApplication.createInvitation(memberId, member.sectorId, adminId)
        val saved = applicationRepository.save(invitation)

        // Get sector name
        val sector = sectorRepository.findById(member.sectorId)!!

        // Send invitation message
        val invitationMessage =
            MessageEntity(
                type = MessageType.GROUND_ADMIN_INVITATION,
                title = "Ground Admin Invitation",
                body = "${admin.fullName} has invited you to become a Ground Admin for ${sector.name}${message?.let { ": $it" } ?: "."}",
                recipientId = memberId.value,
                recipientType = "member",
                senderId = adminId.value,
                senderType = "admin",
                relatedEntityId = saved.id.value,
                relatedEntityType = "ground_admin_application",
                actionType = "accept_decline",
            )
        messageService.createMessage(invitationMessage)

        return GroundAdminResult.Success(mapOf("applicationId" to saved.id.toString(), "status" to "pending"))
    }

    /**
     * Admin revokes/cancels a pending Ground Admin invitation.
     */
    @Transactional
    fun revokeInvitation(
        adminId: MemberId,
        memberId: MemberId,
        applicationId: GroundAdminApplicationId,
    ): GroundAdminResult {
        val application =
            applicationRepository.findById(applicationId)
                ?: return GroundAdminResult.NotFound(ERROR_APPLICATION_NOT_FOUND)

        if (application.memberId != memberId) {
            return GroundAdminResult.NotFound(ERROR_APPLICATION_NOT_FOUND)
        }

        if (!application.isInvitation) {
            return GroundAdminResult.ValidationError(listOf("Not an invitation"))
        }

        if (!application.isPending) {
            return GroundAdminResult.Conflict("Invitation already processed")
        }

        // Revoke the invitation
        val revoked = application.revokeByAdmin(adminId)
        applicationRepository.save(revoked)

        return GroundAdminResult.Success(mapOf("applicationId" to application.id.toString(), "status" to "revoked"))
    }

    /**
     * Admin approves a Ground Admin application.
     */
    @Transactional
    fun approveApplication(
        adminId: MemberId,
        memberId: MemberId,
        applicationId: GroundAdminApplicationId,
    ): GroundAdminResult {
        val application =
            applicationRepository.findById(applicationId)
                ?: return GroundAdminResult.NotFound(ERROR_APPLICATION_NOT_FOUND)

        if (application.memberId != memberId) {
            return GroundAdminResult.NotFound(ERROR_APPLICATION_NOT_FOUND)
        }

        if (!application.isApplication || !application.isPending) {
            return GroundAdminResult.Conflict("Cannot approve this application")
        }

        // Approve
        val approved = application.approve(adminId)
        applicationRepository.save(approved)

        // Promote member
        val member = memberRepository.findById(memberId)!!
        val promoted = member.promoteToGroundAdmin()
        memberRepository.save(promoted)

        // Notify member
        val message =
            MessageEntity(
                type = MessageType.GROUND_ADMIN_APPROVED,
                title = "Ground Admin Application Approved",
                body = "Congratulations! Your application to become a Ground Admin has been approved.",
                recipientId = memberId.value,
                recipientType = "member",
                senderId = adminId.value,
                senderType = "member",
                actionType = "acknowledge",
            )
        messageService.createMessage(message)

        return GroundAdminResult.Success(mapOf("applicationId" to application.id.toString(), "status" to "approved"))
    }

    /**
     * Admin declines a Ground Admin application.
     */
    @Transactional
    fun declineApplication(
        adminId: MemberId,
        memberId: MemberId,
        applicationId: GroundAdminApplicationId,
        reason: String,
    ): GroundAdminResult {
        val application =
            applicationRepository.findById(applicationId)
                ?: return GroundAdminResult.NotFound(ERROR_APPLICATION_NOT_FOUND)

        if (application.memberId != memberId) {
            return GroundAdminResult.NotFound(ERROR_APPLICATION_NOT_FOUND)
        }

        if (!application.isApplication || !application.isPending) {
            return GroundAdminResult.Conflict("Cannot decline this application")
        }

        val declined = application.decline(adminId, reason)
        applicationRepository.save(declined)

        // Notify member
        val message =
            MessageEntity(
                type = MessageType.GROUND_ADMIN_DECLINED,
                title = "Ground Admin Application Declined",
                body = "Your application to become a Ground Admin has been declined: $reason",
                recipientId = memberId.value,
                recipientType = "member",
                senderId = adminId.value,
                senderType = "member",
                actionType = "acknowledge",
            )
        messageService.createMessage(message)

        return GroundAdminResult.Success(mapOf("applicationId" to application.id.toString(), "status" to "declined"))
    }

    /**
     * Admin revokes Ground Admin status.
     */
    @Transactional
    fun revoke(
        adminId: MemberId,
        memberId: MemberId,
        reason: String,
    ): GroundAdminResult {
        val member =
            memberRepository.findById(memberId)
                ?: return GroundAdminResult.NotFound(ERROR_MEMBER_NOT_FOUND)

        if (!member.isGroundAdmin) {
            return GroundAdminResult.Conflict("Member is not a Ground Admin")
        }

        // Demote
        val demoted = member.demoteFromGroundAdmin()
        memberRepository.save(demoted)

        // Notify member
        val message =
            MessageEntity(
                type = MessageType.GROUND_ADMIN_REVOCATION,
                title = "Ground Admin Status Revoked",
                body = "Your Ground Admin status has been revoked: $reason",
                recipientId = memberId.value,
                recipientType = "member",
                senderId = adminId.value,
                senderType = "member",
                actionType = "acknowledge",
            )
        messageService.createMessage(message)

        return GroundAdminResult.Success(mapOf("status" to "revoked"))
    }

    /**
     * Admin updates Ground Admin status.
     */
    @Transactional
    fun updateStatus(
        adminId: MemberId,
        memberId: MemberId,
        status: GroundAdminStatus,
    ): GroundAdminResult {
        val member =
            memberRepository.findById(memberId)
                ?: return GroundAdminResult.NotFound(ERROR_MEMBER_NOT_FOUND)

        if (!member.isGroundAdmin) {
            return GroundAdminResult.Conflict("Member is not a Ground Admin")
        }

        val updated =
            when (status) {
                GroundAdminStatus.ACTIVE -> member.reactivateGroundAdmin()
                GroundAdminStatus.ON_HOLD -> member.setGroundAdminOnHold()
                GroundAdminStatus.INACTIVE -> member.demoteFromGroundAdmin()
            }
        memberRepository.save(updated)

        return GroundAdminResult.Success(mapOf("status" to status.toApiString()))
    }

    /**
     * List Ground Admins in sector.
     */
    fun listGroundAdmins(
        sectorId: SectorId,
        status: GroundAdminStatus? = null,
    ): GroundAdminListResponse {
        val members =
            if (status != null) {
                memberRepository.findBySectorIdAndIsGroundAdminAndGroundAdminStatus(sectorId, true, status)
            } else {
                memberRepository.findBySectorIdAndIsGroundAdmin(sectorId, true)
            }

        // TODO: Get actual pending verification counts from verification service
        val items =
            members.map { member ->
                GroundAdminResponse(
                    id = member.id.toString(),
                    memberId = member.id.toString(),
                    name = member.fullName,
                    phone = member.phone,
                    status = member.groundAdminStatus!!,
                    since = member.groundAdminSince!!,
                    responseRate = member.groundAdminResponseRate?.toDouble() ?: 100.0,
                    pendingVerifications = 0,
                )
            }

        return GroundAdminListResponse(
            items = items,
            total = items.size,
        )
    }

    // ==================== Helpers ====================

    private fun notifySectorAdminsOfApplication(
        sectorId: SectorId,
        applicantId: MemberId,
        applicantName: String,
        applicationId: GroundAdminApplicationId,
    ) {
        val admins = memberRepository.findAdminsBySectorId(sectorId)
        admins.forEach { admin ->
            val message =
                MessageEntity(
                    type = MessageType.GROUND_ADMIN_APPLICATION,
                    title = "New Ground Admin Application",
                    body = "$applicantName has applied to become a Ground Admin.",
                    recipientId = admin.id.value,
                    recipientType = "member",
                    senderId = applicantId.value,
                    senderType = "member",
                    relatedEntityId = applicationId.value,
                    relatedEntityType = "ground_admin_application",
                    actionType = "approve_reject",
                )
            messageService.createMessage(message)
        }
    }
}
