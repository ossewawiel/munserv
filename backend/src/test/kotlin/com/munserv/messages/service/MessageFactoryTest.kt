package com.munserv.messages.service

import com.munserv.shared.enums.MessageStatus
import com.munserv.shared.enums.MessageType
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import java.util.UUID

class MessageFactoryTest {
    private val recipientId = UUID.randomUUID()
    private val senderId = UUID.randomUUID()
    private val issueId = UUID.randomUUID()
    private val verificationId = UUID.randomUUID()

    @Nested
    inner class GroundAdminInvitation {
        @Test
        fun `should create ground admin invitation message`() {
            val message =
                MessageFactory.groundAdminInvitation(
                    recipientId = recipientId,
                    invitedBy = senderId,
                    inviterName = "John Admin",
                    sectorName = "Sector 7",
                    customMessage = "We need your help!",
                )

            message.type shouldBe MessageType.GROUND_ADMIN_INVITATION
            message.title shouldBe "Ground Admin Invitation"
            message.body shouldContain "John Admin"
            message.body shouldContain "Sector 7"
            message.body shouldContain "We need your help!"
            message.recipientId shouldBe recipientId
            message.recipientType shouldBe "member"
            message.senderId shouldBe senderId
            message.senderType shouldBe "admin"
            message.actionType shouldBe "accept_decline"
            message.status shouldBe MessageStatus.UNREAD
        }

        @Test
        fun `should create invitation without custom message`() {
            val message =
                MessageFactory.groundAdminInvitation(
                    recipientId = recipientId,
                    invitedBy = senderId,
                    inviterName = "John Admin",
                    sectorName = "Sector 7",
                )

            message.body shouldContain "John Admin"
            message.body shouldContain "Sector 7"
        }
    }

    @Nested
    inner class GroundAdminApplication {
        @Test
        fun `should create ground admin application message`() {
            val applicationId = UUID.randomUUID()

            val message =
                MessageFactory.groundAdminApplication(
                    recipientId = recipientId,
                    applicantId = senderId,
                    applicantName = "Jane Applicant",
                    applicationId = applicationId,
                )

            message.type shouldBe MessageType.GROUND_ADMIN_APPLICATION
            message.title shouldBe "Ground Admin Application"
            message.body shouldContain "Jane Applicant"
            message.recipientId shouldBe recipientId
            message.recipientType shouldBe "admin"
            message.senderId shouldBe senderId
            message.senderType shouldBe "member"
            message.actionType shouldBe "approve_reject"
            message.relatedEntityId shouldBe applicationId
            message.relatedEntityType shouldBe "ground_admin_application"
        }
    }

    @Nested
    inner class GroundAdminApproved {
        @Test
        fun `should create approval message`() {
            val message = MessageFactory.groundAdminApproved(recipientId)

            message.type shouldBe MessageType.GROUND_ADMIN_APPROVED
            message.title shouldBe "Application Approved!"
            message.body shouldContain "approved"
            message.recipientId shouldBe recipientId
            message.recipientType shouldBe "member"
            message.senderType shouldBe "system"
            message.actionType shouldBe "acknowledge"
        }
    }

    @Nested
    inner class GroundAdminDeclined {
        @Test
        fun `should create declined message with reason`() {
            val message =
                MessageFactory.groundAdminDeclined(
                    recipientId = recipientId,
                    reason = "Not enough experience",
                )

            message.type shouldBe MessageType.GROUND_ADMIN_DECLINED
            message.body shouldContain "Not enough experience"
            message.actionType shouldBe "acknowledge"
        }

        @Test
        fun `should create declined message without reason`() {
            val message =
                MessageFactory.groundAdminDeclined(
                    recipientId = recipientId,
                    reason = null,
                )

            message.type shouldBe MessageType.GROUND_ADMIN_DECLINED
            message.body shouldContain "not approved"
        }
    }

    @Nested
    inner class GroundAdminInvitationDeclined {
        @Test
        fun `should create invitation declined message`() {
            val message =
                MessageFactory.groundAdminInvitationDeclined(
                    recipientId = recipientId,
                    memberName = "Jane Member",
                    reason = "Too busy",
                )

            message.type shouldBe MessageType.GROUND_ADMIN_INVITATION_DECLINED
            message.title shouldBe "Invitation Declined"
            message.body shouldContain "Jane Member"
            message.body shouldContain "Too busy"
            message.recipientType shouldBe "admin"
            message.senderType shouldBe "system"
        }
    }

    @Nested
    inner class GroundAdminRevocation {
        @Test
        fun `should create revocation message`() {
            val message =
                MessageFactory.groundAdminRevocation(
                    recipientId = recipientId,
                    reason = "Policy violation",
                )

            message.type shouldBe MessageType.GROUND_ADMIN_REVOCATION
            message.body shouldContain "revoked"
            message.body shouldContain "Policy violation"
            message.actionType shouldBe "acknowledge"
        }
    }

    @Nested
    inner class GroundAdminStepdownRequest {
        @Test
        fun `should create step down request message`() {
            val groundAdminId = UUID.randomUUID()

            val message =
                MessageFactory.groundAdminStepdownRequest(
                    recipientId = recipientId,
                    groundAdminId = groundAdminId,
                    groundAdminName = "Bob Ground Admin",
                    reason = "Personal reasons",
                )

            message.type shouldBe MessageType.GROUND_ADMIN_STEPDOWN_REQUEST
            message.title shouldBe "Step Down Request"
            message.body shouldContain "Bob Ground Admin"
            message.body shouldContain "Personal reasons"
            message.recipientType shouldBe "admin"
            message.senderId shouldBe groundAdminId
            message.senderType shouldBe "member"
            message.actionType shouldBe "approve_reject"
            message.relatedEntityId shouldBe groundAdminId
            message.relatedEntityType shouldBe "member"
        }
    }

    @Nested
    inner class VerifyNewIssue {
        @Test
        fun `should create verify new issue message`() {
            val message =
                MessageFactory.verifyNewIssue(
                    recipientId = recipientId,
                    issueId = issueId,
                    issueType = "Pothole",
                    issueDescription = "Large pothole on Main St",
                    verificationId = verificationId,
                )

            message.type shouldBe MessageType.VERIFY_NEW_ISSUE
            message.title shouldBe "Verify Issue: Pothole"
            message.body shouldContain "Pothole"
            message.body shouldContain "Large pothole on Main St"
            message.recipientType shouldBe "member"
            message.senderType shouldBe "system"
            message.actionType shouldBe "confirm_verify"
            message.relatedEntityId shouldBe issueId
            message.relatedEntityType shouldBe "issue"
        }

        @Test
        fun `should create verify issue message without description`() {
            val message =
                MessageFactory.verifyNewIssue(
                    recipientId = recipientId,
                    issueId = issueId,
                    issueType = "Water Leak",
                    issueDescription = null,
                    verificationId = verificationId,
                )

            message.body shouldContain "Water Leak"
            message.body shouldContain "verification"
        }
    }

    @Nested
    inner class VerifyFix {
        @Test
        fun `should create verify fix message`() {
            val message =
                MessageFactory.verifyFix(
                    recipientId = recipientId,
                    issueId = issueId,
                    issueType = "Broken Streetlight",
                    verificationId = verificationId,
                )

            message.type shouldBe MessageType.VERIFY_FIX
            message.title shouldBe "Verify Fix: Broken Streetlight"
            message.body shouldContain "Broken Streetlight"
            message.body shouldContain "fixed"
            message.actionType shouldBe "confirm_verify"
            message.relatedEntityId shouldBe issueId
            message.relatedEntityType shouldBe "issue"
        }
    }

    @Nested
    inner class MemberRegistration {
        @Test
        fun `should create member registration message`() {
            val memberId = UUID.randomUUID()

            val message =
                MessageFactory.memberRegistration(
                    recipientId = recipientId,
                    memberId = memberId,
                    memberName = "New Member",
                    memberPhone = "+27821234567",
                )

            message.type shouldBe MessageType.MEMBER_REGISTRATION
            message.title shouldBe "New Member Registration"
            message.body shouldContain "New Member"
            message.body shouldContain "+27821234567"
            message.recipientType shouldBe "admin"
            message.senderType shouldBe "system"
            message.actionType shouldBe "approve_reject"
            message.relatedEntityId shouldBe memberId
            message.relatedEntityType shouldBe "member"
        }
    }

    @Nested
    inner class MonthlyReport {
        @Test
        fun `should create monthly report message`() {
            val message =
                MessageFactory.monthlyReport(
                    recipientId = recipientId,
                    reportMonth = "January 2025",
                    summary = "10 issues reported, 8 resolved",
                )

            message.type shouldBe MessageType.MONTHLY_REPORT
            message.title shouldBe "Monthly Report: January 2025"
            message.body shouldBe "10 issues reported, 8 resolved"
            message.recipientType shouldBe "member"
            message.senderType shouldBe "system"
            message.actionType shouldBe "view"
        }
    }
}
