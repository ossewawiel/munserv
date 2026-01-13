package com.munserv.auth.service

import com.munserv.auth.domain.Email
import com.munserv.auth.domain.Member
import com.munserv.auth.domain.MemberStatus
import com.munserv.auth.domain.Password
import com.munserv.auth.repository.MemberRepository
import com.munserv.sectors.domain.Sector
import com.munserv.sectors.service.SectorService
import com.munserv.shared.email.EmailService
import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.PodId
import com.munserv.shared.types.SectorId
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.Runs
import io.mockk.clearAllMocks
import io.mockk.every
import io.mockk.just
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset

class RegistrationServiceTest {
    private lateinit var registrationService: RegistrationService
    private lateinit var memberRepository: MemberRepository
    private lateinit var sectorService: SectorService
    private lateinit var emailService: EmailService
    private lateinit var clock: Clock

    private val testSectorId = SectorId.generate()
    private val testMemberId = MemberId.generate()
    private val fixedInstant = Instant.parse("2026-01-05T10:00:00Z")

    @BeforeEach
    fun setup() {
        clearAllMocks()
        clock = Clock.fixed(fixedInstant, ZoneOffset.UTC)
        memberRepository = mockk()
        sectorService = mockk()
        emailService = mockk(relaxed = true)
        registrationService = RegistrationService(memberRepository, sectorService, emailService, clock)
    }

    @Nested
    inner class RegisterMember {
        @Test
        fun `should create member with PendingApproval status`() {
            val command = createTestCommand()
            val memberSlot = slot<Member>()

            every { memberRepository.existsByEmailHash(any()) } returns false
            every { sectorService.findById(any()) } returns createTestSector()
            every { memberRepository.save(capture(memberSlot)) } answers { memberSlot.captured }

            val result = registrationService.registerMember(command)

            result.shouldBeInstanceOf<RegistrationResult.Success>()
            val success = result as RegistrationResult.Success
            success.member.status shouldBe MemberStatus.PendingApproval
            success.member.passwordHash shouldBe null
            success.member.mustChangePassword shouldBe true
            verify { memberRepository.save(match { it.status == MemberStatus.PendingApproval }) }
        }

        @Test
        fun `should return ValidationError for invalid email format`() {
            val command = createTestCommand(email = "invalid-email")

            val result = registrationService.registerMember(command)

            result.shouldBeInstanceOf<RegistrationResult.ValidationError>()
            val error = result as RegistrationResult.ValidationError
            error.errors.any { it.contains("email", ignoreCase = true) } shouldBe true
        }

        @Test
        fun `should return EmailAlreadyRegistered for duplicate email`() {
            val command = createTestCommand()

            every { memberRepository.existsByEmailHash(any()) } returns true

            val result = registrationService.registerMember(command)

            result shouldBe RegistrationResult.EmailAlreadyRegistered
        }

        @Test
        fun `should return InvalidSector for non-existent sector`() {
            val command = createTestCommand()

            every { memberRepository.existsByEmailHash(any()) } returns false
            every { sectorService.findById(any()) } returns null

            val result = registrationService.registerMember(command)

            result shouldBe RegistrationResult.InvalidSector
        }

        @Test
        fun `should store email hash for lookups`() {
            val command = createTestCommand()
            val memberSlot = slot<Member>()

            every { memberRepository.existsByEmailHash(any()) } returns false
            every { sectorService.findById(any()) } returns createTestSector()
            every { memberRepository.save(capture(memberSlot)) } answers { memberSlot.captured }

            registrationService.registerMember(command)

            val email = Email.fromString(command.email)
            memberSlot.captured.emailHash shouldBe email.hash()
        }
    }

    @Nested
    inner class ApproveMember {
        @Test
        fun `should activate member and generate password`() {
            val pendingMember = createTestMember(status = MemberStatus.PendingApproval)
            val memberSlot = slot<Member>()

            every { memberRepository.findById(any()) } returns pendingMember
            every { memberRepository.save(capture(memberSlot)) } answers { memberSlot.captured }

            val result = registrationService.approveMember(pendingMember.id)

            result.shouldBeInstanceOf<RegistrationResult.Approved>()
            val approved = result as RegistrationResult.Approved
            approved.member.status shouldBe MemberStatus.Active
            approved.member.passwordHash shouldNotBe null
            approved.member.mustChangePassword shouldBe true
            approved.temporaryPassword.isNotEmpty() shouldBe true
        }

        @Test
        fun `should send welcome email with temporary password`() {
            val pendingMember = createTestMember(status = MemberStatus.PendingApproval)

            every { memberRepository.findById(any()) } returns pendingMember
            every { memberRepository.save(any()) } answers { firstArg() }

            registrationService.approveMember(pendingMember.id)

            verify {
                emailService.sendWelcomeEmail(
                    toEmail = pendingMember.email,
                    memberName = pendingMember.fullName,
                    tempPassword = any(),
                )
            }
        }

        @Test
        fun `should return MemberNotFound for non-existent member`() {
            every { memberRepository.findById(any()) } returns null

            val result = registrationService.approveMember(testMemberId)

            result shouldBe RegistrationResult.MemberNotFound
        }

        @Test
        fun `should return InvalidStatus for non-pending member`() {
            val activeMember = createTestMember(status = MemberStatus.Active)

            every { memberRepository.findById(any()) } returns activeMember

            val result = registrationService.approveMember(activeMember.id)

            result.shouldBeInstanceOf<RegistrationResult.InvalidStatus>()
            val invalidStatus = result as RegistrationResult.InvalidStatus
            invalidStatus.current shouldBe "active"
            invalidStatus.expected shouldBe "pending_approval"
        }
    }

    @Nested
    inner class RejectMember {
        @Test
        fun `should delete pending member`() {
            val pendingMember = createTestMember(status = MemberStatus.PendingApproval)

            every { memberRepository.findById(any()) } returns pendingMember
            every { memberRepository.delete(any()) } just Runs

            val result = registrationService.rejectMember(pendingMember.id)

            result.shouldBeInstanceOf<RegistrationResult.Rejected>()
            verify { memberRepository.delete(pendingMember.id) }
        }

        @Test
        fun `should return MemberNotFound for non-existent member`() {
            every { memberRepository.findById(any()) } returns null

            val result = registrationService.rejectMember(testMemberId)

            result shouldBe RegistrationResult.MemberNotFound
        }

        @Test
        fun `should return InvalidStatus for non-pending member`() {
            val activeMember = createTestMember(status = MemberStatus.Active)

            every { memberRepository.findById(any()) } returns activeMember

            val result = registrationService.rejectMember(activeMember.id)

            result.shouldBeInstanceOf<RegistrationResult.InvalidStatus>()
        }
    }

    private fun createTestCommand(
        email: String = "test@example.com",
        firstName: String = "John",
        surname: String = "Doe",
        phone: String = "+27821234567",
        address: String = "123 Main Street",
        location: GeoPoint = GeoPoint(-26.2041, 28.0473),
        sectorId: SectorId = testSectorId,
    ) = WebRegistrationCommand(
        email = email,
        firstName = firstName,
        surname = surname,
        phone = phone,
        address = address,
        location = location,
        sectorId = sectorId,
    )

    private fun createTestSector() =
        Sector(
            id = testSectorId,
            podId = PodId.generate(),
            name = "Test Sector",
            center = GeoPoint(-26.2041, 28.0473),
            createdAt = fixedInstant,
            updatedAt = fixedInstant,
        )

    private fun createTestMember(
        status: MemberStatus = MemberStatus.Active,
        email: String = "test@example.com",
    ): Member {
        val emailObj = Email.fromString(email)
        return Member(
            id = testMemberId,
            sectorId = testSectorId,
            email = email,
            emailHash = emailObj.hash(),
            passwordHash = if (status == MemberStatus.Active) Password.hash("TempPass123") else null,
            mustChangePassword = status == MemberStatus.Active,
            phoneHash = null,
            pinHash = null,
            phone = "+27821234567",
            firstName = "Test",
            surname = "Member",
            address = "123 Test Street",
            registrationLocation = GeoPoint(-26.2041, 28.0473),
            status = status,
            createdAt = fixedInstant,
            updatedAt = fixedInstant,
        )
    }
}
