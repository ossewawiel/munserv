package com.munserv.groundadmin.domain

import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import java.time.Instant

class GroundAdminApplicationTest {
    private val memberId = MemberId.generate()
    private val sectorId = SectorId.generate()
    private val adminId = MemberId.generate()
    private val now = Instant.now()

    private fun createApplication(
        id: GroundAdminApplicationId = GroundAdminApplicationId.generate(),
        type: ApplicationType = ApplicationType.APPLICATION,
        status: ApplicationStatus = ApplicationStatus.PENDING,
        invitedBy: MemberId? = null,
        processedBy: MemberId? = null,
        processedAt: Instant? = null,
        declineReason: String? = null,
    ) = GroundAdminApplication(
        id = id,
        memberId = memberId,
        sectorId = sectorId,
        type = type,
        invitedBy = invitedBy,
        status = status,
        processedBy = processedBy,
        processedAt = processedAt,
        declineReason = declineReason,
        createdAt = now,
        updatedAt = now,
    )

    @Nested
    inner class CreationTests {
        @Test
        fun `should create application with default pending status`() {
            val application = createApplication()

            application.memberId shouldBe memberId
            application.sectorId shouldBe sectorId
            application.type shouldBe ApplicationType.APPLICATION
            application.status shouldBe ApplicationStatus.PENDING
            application.invitedBy shouldBe null
            application.processedBy shouldBe null
            application.processedAt shouldBe null
            application.declineReason shouldBe null
        }

        @Test
        fun `should create invitation with invitedBy set`() {
            val application =
                createApplication(
                    type = ApplicationType.INVITATION,
                    invitedBy = adminId,
                )

            application.type shouldBe ApplicationType.INVITATION
            application.invitedBy shouldBe adminId
        }
    }

    @Nested
    inner class TypeChecks {
        @Test
        fun `isApplication should return true for application type`() {
            val application = createApplication(type = ApplicationType.APPLICATION)

            application.isApplication shouldBe true
            application.isInvitation shouldBe false
        }

        @Test
        fun `isInvitation should return true for invitation type`() {
            val application = createApplication(type = ApplicationType.INVITATION)

            application.isApplication shouldBe false
            application.isInvitation shouldBe true
        }
    }

    @Nested
    inner class StatusChecks {
        @Test
        fun `isPending should return true only for pending status`() {
            createApplication(status = ApplicationStatus.PENDING).isPending shouldBe true
            createApplication(status = ApplicationStatus.APPROVED).isPending shouldBe false
            createApplication(status = ApplicationStatus.DECLINED).isPending shouldBe false
            createApplication(status = ApplicationStatus.ACCEPTED).isPending shouldBe false
            createApplication(status = ApplicationStatus.REJECTED).isPending shouldBe false
            createApplication(status = ApplicationStatus.WITHDRAWN).isPending shouldBe false
        }
    }

    @Nested
    inner class ApplicationApproval {
        @Test
        fun `approve should transition application to approved`() {
            val application = createApplication(type = ApplicationType.APPLICATION)

            val approved = application.approve(adminId)

            approved.status shouldBe ApplicationStatus.APPROVED
            approved.processedBy shouldBe adminId
            approved.processedAt shouldNotBe null
            approved.updatedAt shouldNotBe application.updatedAt
        }

        @Test
        fun `decline should transition application to declined with reason`() {
            val application = createApplication(type = ApplicationType.APPLICATION)
            val reason = "Insufficient activity"

            val declined = application.decline(adminId, reason)

            declined.status shouldBe ApplicationStatus.DECLINED
            declined.processedBy shouldBe adminId
            declined.declineReason shouldBe reason
            declined.processedAt shouldNotBe null
        }
    }

    @Nested
    inner class InvitationResponse {
        @Test
        fun `accept should transition invitation to accepted`() {
            val invitation =
                createApplication(
                    type = ApplicationType.INVITATION,
                    invitedBy = adminId,
                )

            val accepted = invitation.accept()

            accepted.status shouldBe ApplicationStatus.ACCEPTED
            accepted.processedAt shouldNotBe null
        }

        @Test
        fun `reject should transition invitation to rejected with reason`() {
            val invitation =
                createApplication(
                    type = ApplicationType.INVITATION,
                    invitedBy = adminId,
                )
            val reason = "Not interested"

            val rejected = invitation.reject(reason)

            rejected.status shouldBe ApplicationStatus.REJECTED
            rejected.declineReason shouldBe reason
            rejected.processedAt shouldNotBe null
        }
    }

    @Nested
    inner class Withdrawal {
        @Test
        fun `withdraw should transition to withdrawn`() {
            val application = createApplication()

            val withdrawn = application.withdraw()

            withdrawn.status shouldBe ApplicationStatus.WITHDRAWN
            withdrawn.updatedAt shouldNotBe application.updatedAt
        }
    }

    @Nested
    inner class Immutability {
        @Test
        fun `approve should not mutate original`() {
            val original = createApplication()
            val approved = original.approve(adminId)

            original.status shouldBe ApplicationStatus.PENDING
            approved.status shouldBe ApplicationStatus.APPROVED
        }

        @Test
        fun `decline should not mutate original`() {
            val original = createApplication()
            val declined = original.decline(adminId, "reason")

            original.status shouldBe ApplicationStatus.PENDING
            declined.status shouldBe ApplicationStatus.DECLINED
        }
    }
}
