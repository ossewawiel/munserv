package com.munserv.admin.service

import com.munserv.admin.domain.Admin
import com.munserv.admin.domain.AdminRole
import com.munserv.admin.domain.OnboardingStatus
import com.munserv.admin.repository.AdminRepository
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.PodId
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.springframework.security.crypto.password.PasswordEncoder
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset
import java.util.UUID

class OnboardingServiceTest {
    private lateinit var adminRepository: AdminRepository
    private lateinit var passwordEncoder: PasswordEncoder
    private lateinit var service: OnboardingService

    private val fixedInstant = Instant.parse("2026-01-23T10:00:00Z")
    private val clock = Clock.fixed(fixedInstant, ZoneOffset.UTC)

    private val testAdminId = AdminId(UUID.fromString("550e8400-e29b-41d4-a716-446655440001"))
    private val testPodId = PodId(UUID.fromString("550e8400-e29b-41d4-a716-446655440000"))

    private val pendingAdmin =
        Admin(
            id = testAdminId,
            podId = testPodId,
            email = "newadmin@example.com",
            displayName = "New Admin",
            role = AdminRole.WARD_ADMIN,
            onboardingStatus = OnboardingStatus.PENDING,
            createdAt = fixedInstant.minusSeconds(3600),
            updatedAt = fixedInstant.minusSeconds(3600),
        )

    private val passwordChangedAdmin =
        pendingAdmin.copy(
            onboardingStatus = OnboardingStatus.PASSWORD_CHANGED,
        )

    private val activeAdmin =
        pendingAdmin.copy(
            onboardingStatus = OnboardingStatus.ACTIVE,
            onboardingCompletedAt = fixedInstant,
        )

    @BeforeEach
    fun setUp() {
        adminRepository = mockk()
        passwordEncoder = mockk()
        service = OnboardingService(adminRepository, passwordEncoder, clock)
    }

    @Nested
    inner class ChangePassword {
        @Test
        fun `should return AdminNotFound when admin does not exist`() {
            every { adminRepository.findById(testAdminId) } returns null

            val result = service.changePassword(testAdminId, "NewPass123")

            result.shouldBeInstanceOf<OnboardingResult.AdminNotFound>()
            (result as OnboardingResult.AdminNotFound).id shouldBe testAdminId
        }

        @Test
        fun `should return ValidationError when password is too short`() {
            every { adminRepository.findById(testAdminId) } returns pendingAdmin

            val result = service.changePassword(testAdminId, "Ab1")

            result.shouldBeInstanceOf<OnboardingResult.ValidationError>()
            val errors = (result as OnboardingResult.ValidationError).errors
            errors.any { it.contains("at least") } shouldBe true
        }

        @Test
        fun `should return ValidationError when password missing uppercase`() {
            every { adminRepository.findById(testAdminId) } returns pendingAdmin

            val result = service.changePassword(testAdminId, "password123")

            result.shouldBeInstanceOf<OnboardingResult.ValidationError>()
            val errors = (result as OnboardingResult.ValidationError).errors
            errors.any { it.contains("uppercase") } shouldBe true
        }

        @Test
        fun `should return ValidationError when password missing lowercase`() {
            every { adminRepository.findById(testAdminId) } returns pendingAdmin

            val result = service.changePassword(testAdminId, "PASSWORD123")

            result.shouldBeInstanceOf<OnboardingResult.ValidationError>()
            val errors = (result as OnboardingResult.ValidationError).errors
            errors.any { it.contains("lowercase") } shouldBe true
        }

        @Test
        fun `should return ValidationError when password missing digit`() {
            every { adminRepository.findById(testAdminId) } returns pendingAdmin

            val result = service.changePassword(testAdminId, "PasswordAbc")

            result.shouldBeInstanceOf<OnboardingResult.ValidationError>()
            val errors = (result as OnboardingResult.ValidationError).errors
            errors.any { it.contains("digit") } shouldBe true
        }

        @Test
        fun `should return InvalidStep when admin is not in PENDING status`() {
            every { adminRepository.findById(testAdminId) } returns passwordChangedAdmin

            val result = service.changePassword(testAdminId, "NewPass123")

            result.shouldBeInstanceOf<OnboardingResult.InvalidStep>()
            (result as OnboardingResult.InvalidStep).current shouldBe OnboardingStatus.PASSWORD_CHANGED
            result.expected shouldBe OnboardingStatus.PENDING
        }

        @Test
        fun `should change password and update status to PASSWORD_CHANGED`() {
            val capturedAdmin = slot<Admin>()
            val encodedPassword = "encoded_password"

            every { adminRepository.findById(testAdminId) } returns pendingAdmin
            every { passwordEncoder.encode("NewPass123") } returns encodedPassword
            every {
                adminRepository.updateWithPassword(
                    capture(capturedAdmin),
                    encodedPassword,
                )
            } answers {
                capturedAdmin.captured
            }

            val result = service.changePassword(testAdminId, "NewPass123")

            result.shouldBeInstanceOf<OnboardingResult.Success>()
            val updatedAdmin = (result as OnboardingResult.Success).admin
            updatedAdmin.onboardingStatus shouldBe OnboardingStatus.PASSWORD_CHANGED
            updatedAdmin.updatedAt shouldBe fixedInstant

            verify { adminRepository.updateWithPassword(any(), encodedPassword) }
        }
    }

    @Nested
    inner class CompleteProfile {
        @Test
        fun `should return AdminNotFound when admin does not exist`() {
            every { adminRepository.findById(testAdminId) } returns null

            val result = service.completeProfile(testAdminId, "New Name")

            result.shouldBeInstanceOf<OnboardingResult.AdminNotFound>()
        }

        @Test
        fun `should return InvalidStep when admin is in PENDING status`() {
            every { adminRepository.findById(testAdminId) } returns pendingAdmin

            val result = service.completeProfile(testAdminId, "New Name")

            result.shouldBeInstanceOf<OnboardingResult.InvalidStep>()
            (result as OnboardingResult.InvalidStep).current shouldBe OnboardingStatus.PENDING
            result.expected shouldBe OnboardingStatus.PASSWORD_CHANGED
        }

        @Test
        fun `should return InvalidStep when admin is already ACTIVE`() {
            every { adminRepository.findById(testAdminId) } returns activeAdmin

            val result = service.completeProfile(testAdminId, "New Name")

            result.shouldBeInstanceOf<OnboardingResult.InvalidStep>()
        }

        @Test
        fun `should return ValidationError when display name is blank`() {
            every { adminRepository.findById(testAdminId) } returns passwordChangedAdmin

            val result = service.completeProfile(testAdminId, "   ")

            result.shouldBeInstanceOf<OnboardingResult.ValidationError>()
        }

        @Test
        fun `should complete profile and set status to ACTIVE`() {
            val capturedAdmin = slot<Admin>()

            every { adminRepository.findById(testAdminId) } returns passwordChangedAdmin
            every { adminRepository.update(capture(capturedAdmin)) } answers { capturedAdmin.captured }

            val result = service.completeProfile(testAdminId, "John D. Smith")

            result.shouldBeInstanceOf<OnboardingResult.Completed>()
            val updatedAdmin = (result as OnboardingResult.Completed).admin
            updatedAdmin.displayName shouldBe "John D. Smith"
            updatedAdmin.onboardingStatus shouldBe OnboardingStatus.ACTIVE
            updatedAdmin.onboardingCompletedAt shouldBe fixedInstant
            updatedAdmin.updatedAt shouldBe fixedInstant
        }

        @Test
        fun `should complete profile without changing display name when null`() {
            val capturedAdmin = slot<Admin>()

            every { adminRepository.findById(testAdminId) } returns passwordChangedAdmin
            every { adminRepository.update(capture(capturedAdmin)) } answers { capturedAdmin.captured }

            val result = service.completeProfile(testAdminId, null)

            result.shouldBeInstanceOf<OnboardingResult.Completed>()
            val updatedAdmin = (result as OnboardingResult.Completed).admin
            updatedAdmin.displayName shouldBe "New Admin" // unchanged
            updatedAdmin.onboardingStatus shouldBe OnboardingStatus.ACTIVE
        }
    }

    @Nested
    inner class GetOnboardingStatus {
        @Test
        fun `should return AdminNotFound when admin does not exist`() {
            every { adminRepository.findById(testAdminId) } returns null

            val result = service.getOnboardingStatus(testAdminId)

            result.shouldBeInstanceOf<OnboardingResult.AdminNotFound>()
        }

        @Test
        fun `should return Success with admin for PENDING status`() {
            every { adminRepository.findById(testAdminId) } returns pendingAdmin

            val result = service.getOnboardingStatus(testAdminId)

            result.shouldBeInstanceOf<OnboardingResult.Success>()
            val admin = (result as OnboardingResult.Success).admin
            admin.onboardingStatus shouldBe OnboardingStatus.PENDING
            admin.requiresPasswordChange shouldBe true
            admin.requiresProfileCompletion shouldBe false
        }

        @Test
        fun `should return Success with admin for PASSWORD_CHANGED status`() {
            every { adminRepository.findById(testAdminId) } returns passwordChangedAdmin

            val result = service.getOnboardingStatus(testAdminId)

            result.shouldBeInstanceOf<OnboardingResult.Success>()
            val admin = (result as OnboardingResult.Success).admin
            admin.onboardingStatus shouldBe OnboardingStatus.PASSWORD_CHANGED
            admin.requiresPasswordChange shouldBe false
            admin.requiresProfileCompletion shouldBe true
        }

        @Test
        fun `should return Success with admin for ACTIVE status`() {
            every { adminRepository.findById(testAdminId) } returns activeAdmin

            val result = service.getOnboardingStatus(testAdminId)

            result.shouldBeInstanceOf<OnboardingResult.Success>()
            val admin = (result as OnboardingResult.Success).admin
            admin.onboardingStatus shouldBe OnboardingStatus.ACTIVE
            admin.requiresOnboarding shouldBe false
        }
    }
}
