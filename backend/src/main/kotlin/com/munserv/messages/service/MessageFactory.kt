package com.munserv.messages.service

import com.munserv.messages.domain.MessageEntity
import com.munserv.shared.enums.MessageType
import tools.jackson.module.kotlin.jacksonObjectMapper
import java.util.UUID

/**
 * Factory for creating different types of messages with appropriate
 * titles, bodies, and action types.
 */
object MessageFactory {
    private val mapper = jacksonObjectMapper()

    // ============ Ground Admin Messages ============

    /**
     * Creates a Ground Admin invitation message.
     */
    fun groundAdminInvitation(
        recipientId: UUID,
        invitedBy: UUID,
        inviterName: String,
        sectorName: String,
        customMessage: String? = null,
    ) = MessageEntity(
        type = MessageType.GROUND_ADMIN_INVITATION,
        title = "Ground Admin Invitation",
        body =
            buildString {
                append("$inviterName has invited you to become a Ground Admin for $sectorName.")
                customMessage?.let { append("\n\nMessage: $it") }
            },
        recipientId = recipientId,
        recipientType = "member",
        senderId = invitedBy,
        senderType = "admin",
        actionType = "accept_decline",
        metadata =
            mapper.writeValueAsString(
                mapOf(
                    "inviterName" to inviterName,
                    "sectorName" to sectorName,
                ),
            ),
    )

    /**
     * Creates a Ground Admin application message (sent to sector admin).
     */
    fun groundAdminApplication(
        recipientId: UUID,
        applicantId: UUID,
        applicantName: String,
        applicationId: UUID,
    ) = MessageEntity(
        type = MessageType.GROUND_ADMIN_APPLICATION,
        title = "Ground Admin Application",
        body = "$applicantName has applied to become a Ground Admin in your sector.",
        recipientId = recipientId,
        recipientType = "admin",
        senderId = applicantId,
        senderType = "member",
        actionType = "approve_reject",
        relatedEntityId = applicationId,
        relatedEntityType = "ground_admin_application",
        metadata =
            mapper.writeValueAsString(
                mapOf(
                    "applicantName" to applicantName,
                    "applicantId" to applicantId.toString(),
                ),
            ),
    )

    /**
     * Creates a Ground Admin approval message.
     */
    fun groundAdminApproved(recipientId: UUID) =
        MessageEntity(
            type = MessageType.GROUND_ADMIN_APPROVED,
            title = "Application Approved!",
            body =
                "Congratulations! Your application to become a Ground Admin has been approved. " +
                    "You can now verify issues in your sector.",
            recipientId = recipientId,
            recipientType = "member",
            senderType = "system",
            actionType = "acknowledge",
        )

    /**
     * Creates a Ground Admin decline message.
     */
    fun groundAdminDeclined(
        recipientId: UUID,
        reason: String?,
    ) = MessageEntity(
        type = MessageType.GROUND_ADMIN_DECLINED,
        title = "Application Status Update",
        body =
            buildString {
                append("Your Ground Admin application was not approved at this time.")
                reason?.let { append("\n\nReason: $it") }
            },
        recipientId = recipientId,
        recipientType = "member",
        senderType = "system",
        actionType = "acknowledge",
    )

    /**
     * Creates a message notifying an admin that their invitation was declined.
     */
    fun groundAdminInvitationDeclined(
        recipientId: UUID,
        memberName: String,
        reason: String?,
    ) = MessageEntity(
        type = MessageType.GROUND_ADMIN_INVITATION_DECLINED,
        title = "Invitation Declined",
        body =
            buildString {
                append("$memberName has declined your Ground Admin invitation.")
                reason?.let { append("\n\nReason: $it") }
            },
        recipientId = recipientId,
        recipientType = "admin",
        senderType = "system",
        actionType = "acknowledge",
    )

    /**
     * Creates a Ground Admin revocation message.
     */
    fun groundAdminRevocation(
        recipientId: UUID,
        reason: String,
    ) = MessageEntity(
        type = MessageType.GROUND_ADMIN_REVOCATION,
        title = "Ground Admin Status Update",
        body = "Your Ground Admin status has been revoked.\n\nReason: $reason",
        recipientId = recipientId,
        recipientType = "member",
        senderType = "system",
        actionType = "acknowledge",
    )

    /**
     * Creates a Ground Admin step down request message.
     */
    fun groundAdminStepdownRequest(
        recipientId: UUID,
        groundAdminId: UUID,
        groundAdminName: String,
        reason: String?,
    ) = MessageEntity(
        type = MessageType.GROUND_ADMIN_STEPDOWN_REQUEST,
        title = "Step Down Request",
        body =
            buildString {
                append("$groundAdminName has requested to step down from their Ground Admin role.")
                reason?.let { append("\n\nReason: $it") }
            },
        recipientId = recipientId,
        recipientType = "admin",
        senderId = groundAdminId,
        senderType = "member",
        actionType = "approve_reject",
        relatedEntityId = groundAdminId,
        relatedEntityType = "member",
    )

    // ============ Verification Messages ============

    /**
     * Creates a message requesting verification of a new issue.
     */
    fun verifyNewIssue(
        recipientId: UUID,
        issueId: UUID,
        issueType: String,
        issueDescription: String?,
        verificationId: UUID,
    ) = MessageEntity(
        type = MessageType.VERIFY_NEW_ISSUE,
        title = "Verify Issue: $issueType",
        body =
            buildString {
                append("A new $issueType has been reported and needs verification.")
                issueDescription?.let { append("\n\nDescription: $it") }
                append("\n\nPlease visit the location to confirm this issue exists.")
            },
        recipientId = recipientId,
        recipientType = "member",
        senderType = "system",
        actionType = "confirm_verify",
        relatedEntityId = issueId,
        relatedEntityType = "issue",
        metadata =
            mapper.writeValueAsString(
                mapOf(
                    "verificationId" to verificationId.toString(),
                    "issueType" to issueType,
                ),
            ),
    )

    /**
     * Creates a message requesting verification of a fix.
     */
    fun verifyFix(
        recipientId: UUID,
        issueId: UUID,
        issueType: String,
        verificationId: UUID,
    ) = MessageEntity(
        type = MessageType.VERIFY_FIX,
        title = "Verify Fix: $issueType",
        body = "A $issueType has been marked as fixed. Please visit the location to verify the fix is complete.",
        recipientId = recipientId,
        recipientType = "member",
        senderType = "system",
        actionType = "confirm_verify",
        relatedEntityId = issueId,
        relatedEntityType = "issue",
        metadata =
            mapper.writeValueAsString(
                mapOf(
                    "verificationId" to verificationId.toString(),
                    "issueType" to issueType,
                ),
            ),
    )

    // ============ System Messages ============

    /**
     * Creates a message notifying admin of a new member registration.
     */
    fun memberRegistration(
        recipientId: UUID,
        memberId: UUID,
        memberName: String,
        memberPhone: String,
    ) = MessageEntity(
        type = MessageType.MEMBER_REGISTRATION,
        title = "New Member Registration",
        body = "A new member has registered: $memberName ($memberPhone)",
        recipientId = recipientId,
        recipientType = "admin",
        senderType = "system",
        actionType = "approve_reject",
        relatedEntityId = memberId,
        relatedEntityType = "member",
    )

    /**
     * Creates a monthly report message.
     */
    fun monthlyReport(
        recipientId: UUID,
        reportMonth: String,
        summary: String,
    ) = MessageEntity(
        type = MessageType.MONTHLY_REPORT,
        title = "Monthly Report: $reportMonth",
        body = summary,
        recipientId = recipientId,
        recipientType = "member",
        senderType = "system",
        actionType = "view",
    )
}
