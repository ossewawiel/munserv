package com.munserv.groundadmin.service

import com.munserv.admin.domain.Admin
import com.munserv.admin.domain.AdminRole
import com.munserv.admin.repository.AdminRepository
import com.munserv.auth.domain.Member
import com.munserv.auth.domain.MemberStatus
import com.munserv.auth.repository.MemberRepository
import com.munserv.groundadmin.domain.ApplicationStatus
import com.munserv.groundadmin.domain.ApplicationType
import com.munserv.groundadmin.domain.GroundAdminApplication
import com.munserv.groundadmin.domain.GroundAdminApplicationId
import com.munserv.groundadmin.repository.GroundAdminApplicationRepository
import com.munserv.messages.domain.MessageEntity
import com.munserv.messages.service.MessageService
import com.munserv.sectors.domain.Sector
import com.munserv.sectors.repository.SectorRepository
import com.munserv.shared.enums.GroundAdminStatus
import com.munserv.shared.enums.MessageType
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.PodId
import com.munserv.shared.types.SectorId
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.clearAllMocks
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import java.time.Instant

class GroundAdminServiceTest {
    private lateinit var applicationRepository: GroundAdminApplicationRepository
    private lateinit var memberRepository: MemberRepository
    private lateinit var adminRepository: AdminRepository
    private lateinit var sectorRepository: SectorRepository
    private lateinit var messageService: MessageService
    private lateinit var service: GroundAdminService

    private val sectorId = SectorId.generate()
    private val memberId = MemberId.generate()
    private val adminId = MemberId.generate()

    @BeforeEach
    fun setup() {
        clearAllMocks()
        applicationRepository = mockk(relaxed = true)
        memberRepository = mockk(relaxed = true)
        adminRepository = mockk(relaxed = true)
        sectorRepository = mockk(relaxed = true)
        messageService = mockk(relaxed = true)
        service =
            GroundAdminService(
                applicationRepository = applicationRepository,
                memberRepository = memberRepository,
                adminRepository = adminRepository,
                sectorRepository = sectorRepository,
                messageService = messageService,
            )
    }

    private fun createTestMember(
        id: MemberId = memberId,
        sectorId: SectorId = this.sectorId,
        isGroundAdmin: Boolean = false,
        groundAdminStatus: GroundAdminStatus? = null,
    ): Member =
        Member(
            id = id,
            sectorId = sectorId,
            email = "test@example.com",
            emailHash = "testhash",
            passwordHash = "pwhash",
            mustChangePassword = false,
            phoneHash = null,
            pinHash = null,
            phone = "+27821234567",
            firstName = "Test",
            surname = "Member",
            address = "123 Test Street",
            registrationLocation = GeoPoint(27.9833, -26.1367),
            status = MemberStatus.Active,
            createdAt = Instant.now(),
            updatedAt = Instant.now(),
            isGroundAdmin = isGroundAdmin,
            groundAdminStatus = groundAdminStatus,
            groundAdminSince = if (isGroundAdmin) Instant.now() else null,
            groundAdminResponseRate = if (isGroundAdmin) java.math.BigDecimal("100.00") else null,
        )

    private fun createTestSector(id: SectorId = sectorId): Sector =
        Sector(
            id = id,
            podId = PodId.generate(),
            name = "Test Sector",
            center = GeoPoint(27.9833, -26.1367),
        )

    private fun createTestAdmin(
        id: MemberId = adminId,
        sectorId: SectorId = this.sectorId,
    ): Admin =
        Admin(
            id = AdminId(id.value),
            sectorId = sectorId,
            email = "admin@example.com",
            displayName = "Test Admin",
            role = AdminRole.SECTOR_ADMIN,
            createdAt = Instant.now(),
            updatedAt = Instant.now(),
        )

    private fun createTestApplication(
        id: GroundAdminApplicationId = GroundAdminApplicationId.generate(),
        memberId: MemberId = this.memberId,
        type: ApplicationType = ApplicationType.APPLICATION,
        status: ApplicationStatus = ApplicationStatus.PENDING,
        invitedBy: MemberId? = null,
    ): GroundAdminApplication =
        GroundAdminApplication(
            id = id,
            memberId = memberId,
            sectorId = sectorId,
            type = type,
            invitedBy = invitedBy,
            status = status,
            createdAt = Instant.now(),
            updatedAt = Instant.now(),
        )

    @Nested
    inner class Apply {
        @Test
        fun `should create application and return Success`() {
            val member = createTestMember()

            every { memberRepository.findById(memberId) } returns member
            every { applicationRepository.findPendingForMemberInSector(memberId, sectorId) } returns null
            every { applicationRepository.save(any()) } answers { firstArg() }
            every { memberRepository.findAdminsBySectorId(sectorId) } returns emptyList()

            val result = service.apply(memberId)

            result.shouldBeInstanceOf<GroundAdminResult.Success>()
            verify { applicationRepository.save(any()) }
        }

        @Test
        fun `should return NotFound when member not found`() {
            every { memberRepository.findById(memberId) } returns null

            val result = service.apply(memberId)

            result.shouldBeInstanceOf<GroundAdminResult.NotFound>()
        }

        @Test
        fun `should return Conflict when already a ground admin`() {
            val member = createTestMember(isGroundAdmin = true, groundAdminStatus = GroundAdminStatus.ACTIVE)

            every { memberRepository.findById(memberId) } returns member

            val result = service.apply(memberId)

            result.shouldBeInstanceOf<GroundAdminResult.Conflict>()
        }

        @Test
        fun `should return Conflict when pending application exists`() {
            val member = createTestMember()
            val existingApplication = createTestApplication()

            every { memberRepository.findById(memberId) } returns member
            every { applicationRepository.findPendingForMemberInSector(memberId, sectorId) } returns existingApplication

            val result = service.apply(memberId)

            result.shouldBeInstanceOf<GroundAdminResult.Conflict>()
        }

        @Test
        fun `should notify sector admins when application created`() {
            val member = createTestMember()
            val admin = createTestMember(id = adminId)
            val messageSlot = slot<MessageEntity>()

            every { memberRepository.findById(memberId) } returns member
            every { applicationRepository.findPendingForMemberInSector(memberId, sectorId) } returns null
            every { applicationRepository.save(any()) } answers { firstArg() }
            every { memberRepository.findAdminsBySectorId(sectorId) } returns listOf(admin)
            every { messageService.createMessage(capture(messageSlot)) } answers { firstArg() }

            service.apply(memberId)

            verify { messageService.createMessage(any()) }
        }
    }

    @Nested
    inner class AcceptInvitation {
        @Test
        fun `should accept invitation and promote member`() {
            val applicationId = GroundAdminApplicationId.generate()
            val invitation =
                createTestApplication(
                    id = applicationId,
                    type = ApplicationType.INVITATION,
                    invitedBy = adminId,
                )
            val member = createTestMember()

            every { applicationRepository.findById(applicationId) } returns invitation
            every { memberRepository.findById(memberId) } returns member
            every { applicationRepository.save(any()) } answers { firstArg() }
            every { memberRepository.save(any()) } answers { firstArg() }

            val result = service.acceptInvitation(memberId, applicationId)

            result.shouldBeInstanceOf<GroundAdminResult.Success>()
            verify { memberRepository.save(match { it.isGroundAdmin }) }
        }

        @Test
        fun `should return NotFound when application not found`() {
            val applicationId = GroundAdminApplicationId.generate()

            every { applicationRepository.findById(applicationId) } returns null

            val result = service.acceptInvitation(memberId, applicationId)

            result.shouldBeInstanceOf<GroundAdminResult.NotFound>()
        }

        @Test
        fun `should return NotFound when application belongs to different member`() {
            val applicationId = GroundAdminApplicationId.generate()
            val otherMemberId = MemberId.generate()
            val invitation =
                createTestApplication(
                    id = applicationId,
                    memberId = otherMemberId,
                    type = ApplicationType.INVITATION,
                )

            every { applicationRepository.findById(applicationId) } returns invitation

            val result = service.acceptInvitation(memberId, applicationId)

            result.shouldBeInstanceOf<GroundAdminResult.NotFound>()
        }

        @Test
        fun `should return ValidationError when not an invitation`() {
            val applicationId = GroundAdminApplicationId.generate()
            // Not an invitation - it's an application
            val application =
                createTestApplication(
                    id = applicationId,
                    type = ApplicationType.APPLICATION,
                )

            every { applicationRepository.findById(applicationId) } returns application

            val result = service.acceptInvitation(memberId, applicationId)

            result.shouldBeInstanceOf<GroundAdminResult.ValidationError>()
        }

        @Test
        fun `should return Conflict when invitation not pending`() {
            val applicationId = GroundAdminApplicationId.generate()
            // Already processed invitation
            val invitation =
                createTestApplication(
                    id = applicationId,
                    type = ApplicationType.INVITATION,
                    status = ApplicationStatus.ACCEPTED,
                )

            every { applicationRepository.findById(applicationId) } returns invitation

            val result = service.acceptInvitation(memberId, applicationId)

            result.shouldBeInstanceOf<GroundAdminResult.Conflict>()
        }

        @Test
        fun `should notify inviter with acceptance message when invitation accepted`() {
            val applicationId = GroundAdminApplicationId.generate()
            val invitation =
                createTestApplication(
                    id = applicationId,
                    type = ApplicationType.INVITATION,
                    invitedBy = adminId,
                )
            val member = createTestMember()
            val messageSlot = slot<MessageEntity>()

            every { applicationRepository.findById(applicationId) } returns invitation
            every { memberRepository.findById(memberId) } returns member
            every { applicationRepository.save(any()) } answers { firstArg() }
            every { memberRepository.save(any()) } answers { firstArg() }
            every { messageService.createMessage(capture(messageSlot)) } answers { firstArg() }

            val result = service.acceptInvitation(memberId, applicationId)

            result.shouldBeInstanceOf<GroundAdminResult.Success>()

            verify { messageService.createMessage(any()) }

            with(messageSlot.captured) {
                type shouldBe MessageType.GROUND_ADMIN_INVITATION_ACCEPTED
                recipientId shouldBe adminId.value
                recipientType shouldBe "admin"
                senderId shouldBe memberId.value
                senderType shouldBe "member"
                relatedEntityId shouldBe memberId.value
                relatedEntityType shouldBe "member"
                actionType shouldBe "view"
            }
        }
    }

    @Nested
    inner class DeclineInvitation {
        @Test
        fun `should decline invitation and notify inviter`() {
            val applicationId = GroundAdminApplicationId.generate()
            val invitation =
                createTestApplication(
                    id = applicationId,
                    type = ApplicationType.INVITATION,
                    invitedBy = adminId,
                )
            val member = createTestMember()

            every { applicationRepository.findById(applicationId) } returns invitation
            every { memberRepository.findById(memberId) } returns member
            every { applicationRepository.save(any()) } answers { firstArg() }

            val result = service.declineInvitation(memberId, applicationId, "Not interested")

            result.shouldBeInstanceOf<GroundAdminResult.Success>()
            verify { messageService.createMessage(any()) }
        }
    }

    @Nested
    inner class Invite {
        @Test
        fun `should create invitation and send message to member`() {
            val admin = createTestAdmin()
            val member = createTestMember()
            val sector = createTestSector()

            every { adminRepository.findById(AdminId(adminId.value)) } returns admin
            every { memberRepository.findById(memberId) } returns member
            every { sectorRepository.findById(sectorId) } returns sector
            every { applicationRepository.findPendingForMemberInSector(memberId, sectorId) } returns null
            every { applicationRepository.save(any()) } answers { firstArg() }

            val result = service.invite(adminId, memberId, "Welcome!")

            result.shouldBeInstanceOf<GroundAdminResult.Success>()
            verify { messageService.createMessage(any()) }
        }

        @Test
        fun `should return NotFound when admin not found`() {
            every { adminRepository.findById(AdminId(adminId.value)) } returns null

            val result = service.invite(adminId, memberId, null)

            result.shouldBeInstanceOf<GroundAdminResult.NotFound>()
        }

        @Test
        fun `should return Conflict when member already ground admin`() {
            val admin = createTestAdmin()
            val member = createTestMember(isGroundAdmin = true, groundAdminStatus = GroundAdminStatus.ACTIVE)

            every { adminRepository.findById(AdminId(adminId.value)) } returns admin
            every { memberRepository.findById(memberId) } returns member

            val result = service.invite(adminId, memberId, null)

            result.shouldBeInstanceOf<GroundAdminResult.Conflict>()
        }

        @Test
        fun `should return Forbidden when member in different sector`() {
            val otherSectorId = SectorId.generate()
            val admin = createTestAdmin()
            val member = createTestMember(sectorId = otherSectorId)

            every { adminRepository.findById(AdminId(adminId.value)) } returns admin
            every { memberRepository.findById(memberId) } returns member

            val result = service.invite(adminId, memberId, null)

            result.shouldBeInstanceOf<GroundAdminResult.Forbidden>()
        }
    }

    @Nested
    inner class ApproveApplication {
        @Test
        fun `should approve application and promote member`() {
            val applicationId = GroundAdminApplicationId.generate()
            val application = createTestApplication(id = applicationId)
            val member = createTestMember()

            every { applicationRepository.findById(applicationId) } returns application
            every { memberRepository.findById(memberId) } returns member
            every { applicationRepository.save(any()) } answers { firstArg() }
            every { memberRepository.save(any()) } answers { firstArg() }

            val result = service.approveApplication(adminId, memberId, applicationId)

            result.shouldBeInstanceOf<GroundAdminResult.Success>()
            verify { memberRepository.save(match { it.isGroundAdmin }) }
            verify { messageService.createMessage(any()) }
        }

        @Test
        fun `should return NotFound when application not found`() {
            val applicationId = GroundAdminApplicationId.generate()

            every { applicationRepository.findById(applicationId) } returns null

            val result = service.approveApplication(adminId, memberId, applicationId)

            result.shouldBeInstanceOf<GroundAdminResult.NotFound>()
        }

        @Test
        fun `should return NotFound when application memberId mismatch`() {
            val applicationId = GroundAdminApplicationId.generate()
            val otherMemberId = MemberId.generate()
            val application = createTestApplication(id = applicationId, memberId = otherMemberId)

            every { applicationRepository.findById(applicationId) } returns application

            val result = service.approveApplication(adminId, memberId, applicationId)

            result.shouldBeInstanceOf<GroundAdminResult.NotFound>()
        }
    }

    @Nested
    inner class DeclineApplication {
        @Test
        fun `should decline application and notify member`() {
            val applicationId = GroundAdminApplicationId.generate()
            val application = createTestApplication(id = applicationId)

            every { applicationRepository.findById(applicationId) } returns application
            every { applicationRepository.save(any()) } answers { firstArg() }

            val result = service.declineApplication(adminId, memberId, applicationId, "Insufficient activity")

            result.shouldBeInstanceOf<GroundAdminResult.Success>()
            verify { messageService.createMessage(any()) }
        }
    }

    @Nested
    inner class Revoke {
        @Test
        fun `should revoke ground admin status and notify member`() {
            val member = createTestMember(isGroundAdmin = true, groundAdminStatus = GroundAdminStatus.ACTIVE)

            every { memberRepository.findById(memberId) } returns member
            every { memberRepository.save(any()) } answers { firstArg() }

            val result = service.revoke(adminId, memberId, "Performance issues")

            result.shouldBeInstanceOf<GroundAdminResult.Success>()
            verify { memberRepository.save(match { !it.isGroundAdmin }) }
            verify { messageService.createMessage(any()) }
        }

        @Test
        fun `should return Conflict when member not a ground admin`() {
            val member = createTestMember(isGroundAdmin = false)

            every { memberRepository.findById(memberId) } returns member

            val result = service.revoke(adminId, memberId, "reason")

            result.shouldBeInstanceOf<GroundAdminResult.Conflict>()
        }
    }

    @Nested
    inner class UpdateStatus {
        @Test
        fun `should update status to ON_HOLD`() {
            val member = createTestMember(isGroundAdmin = true, groundAdminStatus = GroundAdminStatus.ACTIVE)

            every { memberRepository.findById(memberId) } returns member
            every { memberRepository.save(any()) } answers { firstArg() }

            val result = service.updateStatus(adminId, memberId, GroundAdminStatus.ON_HOLD)

            result.shouldBeInstanceOf<GroundAdminResult.Success>()
            verify { memberRepository.save(match { it.groundAdminStatus == GroundAdminStatus.ON_HOLD }) }
        }

        @Test
        fun `should update status to ACTIVE`() {
            val member = createTestMember(isGroundAdmin = true, groundAdminStatus = GroundAdminStatus.ON_HOLD)

            every { memberRepository.findById(memberId) } returns member
            every { memberRepository.save(any()) } answers { firstArg() }

            val result = service.updateStatus(adminId, memberId, GroundAdminStatus.ACTIVE)

            result.shouldBeInstanceOf<GroundAdminResult.Success>()
            verify { memberRepository.save(match { it.groundAdminStatus == GroundAdminStatus.ACTIVE }) }
        }

        @Test
        fun `should demote when status set to INACTIVE`() {
            val member = createTestMember(isGroundAdmin = true, groundAdminStatus = GroundAdminStatus.ACTIVE)

            every { memberRepository.findById(memberId) } returns member
            every { memberRepository.save(any()) } answers { firstArg() }

            val result = service.updateStatus(adminId, memberId, GroundAdminStatus.INACTIVE)

            result.shouldBeInstanceOf<GroundAdminResult.Success>()
            verify { memberRepository.save(match { !it.isGroundAdmin }) }
        }

        @Test
        fun `should return Conflict when member not a ground admin`() {
            val member = createTestMember(isGroundAdmin = false)

            every { memberRepository.findById(memberId) } returns member

            val result = service.updateStatus(adminId, memberId, GroundAdminStatus.ON_HOLD)

            result.shouldBeInstanceOf<GroundAdminResult.Conflict>()
        }
    }

    @Nested
    inner class RequestStepDown {
        @Test
        fun `should notify sector admins`() {
            val member = createTestMember(isGroundAdmin = true, groundAdminStatus = GroundAdminStatus.ACTIVE)
            val admin = createTestMember(id = adminId)

            every { memberRepository.findById(memberId) } returns member
            every { memberRepository.findAdminsBySectorId(sectorId) } returns listOf(admin)

            val result = service.requestStepDown(memberId, "Personal reasons")

            result.shouldBeInstanceOf<GroundAdminResult.Success>()
            verify { messageService.createMessage(any()) }
        }

        @Test
        fun `should return Conflict when not a ground admin`() {
            val member = createTestMember(isGroundAdmin = false)

            every { memberRepository.findById(memberId) } returns member

            val result = service.requestStepDown(memberId, null)

            result.shouldBeInstanceOf<GroundAdminResult.Conflict>()
        }
    }

    @Nested
    inner class ListGroundAdmins {
        @Test
        fun `should return list of ground admins in sector`() {
            val ga1 = createTestMember(id = MemberId.generate(), isGroundAdmin = true, groundAdminStatus = GroundAdminStatus.ACTIVE)
            val ga2 = createTestMember(id = MemberId.generate(), isGroundAdmin = true, groundAdminStatus = GroundAdminStatus.ACTIVE)

            every { memberRepository.findBySectorIdAndIsGroundAdmin(sectorId, true) } returns listOf(ga1, ga2)

            val result = service.listGroundAdmins(sectorId)

            result.items.size shouldBe 2
            result.total shouldBe 2
        }

        @Test
        fun `should filter by status when provided`() {
            val ga = createTestMember(isGroundAdmin = true, groundAdminStatus = GroundAdminStatus.ON_HOLD)

            every {
                memberRepository.findBySectorIdAndIsGroundAdminAndGroundAdminStatus(
                    sectorId,
                    true,
                    GroundAdminStatus.ON_HOLD,
                )
            } returns listOf(ga)

            val result = service.listGroundAdmins(sectorId, GroundAdminStatus.ON_HOLD)

            result.items.size shouldBe 1
        }
    }

    @Nested
    inner class GetMyGroundAdminInfo {
        @Test
        fun `should return null for non-ground-admin`() {
            val member = createTestMember(isGroundAdmin = false)

            every { memberRepository.findById(memberId) } returns member

            val result = service.getMyGroundAdminInfo(memberId)

            result.shouldBeInstanceOf<GroundAdminResult.Success>()
            (result as GroundAdminResult.Success).data shouldBe null
        }

        @Test
        fun `should return info for ground admin`() {
            val member = createTestMember(isGroundAdmin = true, groundAdminStatus = GroundAdminStatus.ACTIVE)

            every { memberRepository.findById(memberId) } returns member

            val result = service.getMyGroundAdminInfo(memberId)

            result.shouldBeInstanceOf<GroundAdminResult.Success>()
        }
    }
}
