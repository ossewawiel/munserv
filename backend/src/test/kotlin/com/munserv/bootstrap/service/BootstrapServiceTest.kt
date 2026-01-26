package com.munserv.bootstrap.service

import com.munserv.admin.domain.Admin
import com.munserv.admin.domain.AdminRole
import com.munserv.admin.domain.OnboardingStatus
import com.munserv.admin.repository.AdminRepository
import com.munserv.audit.service.AuditService
import com.munserv.bootstrap.config.BootstrapConfig
import com.munserv.bootstrap.domain.BootstrapStatus
import com.munserv.shared.email.EmailService
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.PodId
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldHaveMinLength
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.Runs
import io.mockk.every
import io.mockk.just
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

class BootstrapServiceTest {
    private lateinit var adminRepository: AdminRepository
    private lateinit var bootstrapConfig: BootstrapConfig
    private lateinit var passwordEncoder: PasswordEncoder
    private lateinit var emailService: EmailService
    private lateinit var auditService: AuditService
    private lateinit var clock: Clock
    private lateinit var service: BootstrapService

    private val testPodId = PodId(UUID.fromString("550e8400-e29b-41d4-a716-446655440000"))
    private val testAdminId = AdminId(UUID.fromString("550e8400-e29b-41d4-a716-446655440001"))
    private val fixedInstant = Instant.parse("2026-01-26T10:00:00Z")

    private fun createPodChief(onboardingStatus: OnboardingStatus): Admin =
        Admin(
            id = testAdminId,
            podId = testPodId,
            email = "podchief@example.com",
            displayName = "Pod Chief",
            role = AdminRole.POD_CHIEF,
            onboardingStatus = onboardingStatus,
            onboardingCompletedAt = if (onboardingStatus == OnboardingStatus.ACTIVE) fixedInstant else null,
            createdAt = fixedInstant.minusSeconds(3600),
            updatedAt = fixedInstant.minusSeconds(3600),
        )

    @BeforeEach
    fun setUp() {
        adminRepository = mockk()
        bootstrapConfig = mockk()
        passwordEncoder = mockk()
        emailService = mockk()
        auditService = mockk(relaxed = true)
        clock = Clock.fixed(fixedInstant, ZoneOffset.UTC)
        service = BootstrapService(adminRepository, bootstrapConfig, passwordEncoder, emailService, auditService, clock)

        // Default mock for bootstrapConfig.email used in audit logging
        every { bootstrapConfig.email } returns "super@example.com"
    }

    @Nested
    inner class GetStatus {
        @Test
        fun `should return Eligible when no Pod Chief exists`() {
            every { adminRepository.existsPodChiefOnboarded(testPodId) } returns false
            every { adminRepository.findPodChief(testPodId) } returns null

            val result = service.getStatus(testPodId)

            result.shouldBeInstanceOf<BootstrapStatus.Eligible>()
            result.canBootstrap shouldBe true
            verify { adminRepository.existsPodChiefOnboarded(testPodId) }
            verify { adminRepository.findPodChief(testPodId) }
        }

        @Test
        fun `should return PodChiefOnboarding when Pod Chief exists but is PENDING`() {
            val pendingPodChief = createPodChief(OnboardingStatus.PENDING)
            every { adminRepository.existsPodChiefOnboarded(testPodId) } returns false
            every { adminRepository.findPodChief(testPodId) } returns pendingPodChief

            val result = service.getStatus(testPodId)

            result.shouldBeInstanceOf<BootstrapStatus.PodChiefOnboarding>()
            result.canBootstrap shouldBe false
        }

        @Test
        fun `should return PodChiefOnboarding when Pod Chief exists but is PASSWORD_CHANGED`() {
            val passwordChangedPodChief = createPodChief(OnboardingStatus.PASSWORD_CHANGED)
            every { adminRepository.existsPodChiefOnboarded(testPodId) } returns false
            every { adminRepository.findPodChief(testPodId) } returns passwordChangedPodChief

            val result = service.getStatus(testPodId)

            result.shouldBeInstanceOf<BootstrapStatus.PodChiefOnboarding>()
            result.canBootstrap shouldBe false
        }

        @Test
        fun `should return PodChiefOnboarding when Pod Chief exists but is PROFILE_COMPLETE`() {
            val profileCompletePodChief = createPodChief(OnboardingStatus.PROFILE_COMPLETE)
            every { adminRepository.existsPodChiefOnboarded(testPodId) } returns false
            every { adminRepository.findPodChief(testPodId) } returns profileCompletePodChief

            val result = service.getStatus(testPodId)

            result.shouldBeInstanceOf<BootstrapStatus.PodChiefOnboarding>()
            result.canBootstrap shouldBe false
        }

        @Test
        fun `should return NotEligible when Pod Chief exists and is ACTIVE`() {
            every { adminRepository.existsPodChiefOnboarded(testPodId) } returns true

            val result = service.getStatus(testPodId)

            result.shouldBeInstanceOf<BootstrapStatus.NotEligible>()
            result.canBootstrap shouldBe false
            // Should not call findPodChief when existsPodChiefOnboarded returns true
            verify(exactly = 0) { adminRepository.findPodChief(testPodId) }
        }

        @Test
        fun `should check existsPodChiefOnboarded before findPodChief for performance`() {
            every { adminRepository.existsPodChiefOnboarded(testPodId) } returns true

            service.getStatus(testPodId)

            // Verifies the order - existsPodChiefOnboarded should be checked first
            // and findPodChief should not be called when onboarded Pod Chief exists
            verify(exactly = 1) { adminRepository.existsPodChiefOnboarded(testPodId) }
            verify(exactly = 0) { adminRepository.findPodChief(testPodId) }
        }
    }

    @Nested
    inner class IsBootstrapEnabled {
        @Test
        fun `should return true when bootstrap is configured`() {
            every { bootstrapConfig.isConfigured() } returns true

            val result = service.isBootstrapEnabled()

            result shouldBe true
        }

        @Test
        fun `should return false when bootstrap is not configured`() {
            every { bootstrapConfig.isConfigured() } returns false

            val result = service.isBootstrapEnabled()

            result shouldBe false
        }

        @Test
        fun `should delegate to bootstrapConfig isConfigured`() {
            every { bootstrapConfig.isConfigured() } returns true

            service.isBootstrapEnabled()

            verify { bootstrapConfig.isConfigured() }
        }
    }

    @Nested
    inner class CreatePodChief {
        private val validEmail = "newpodchief@example.com"
        private val validDisplayName = "New Pod Chief"

        @Test
        fun `should return PodChiefCreated when valid inputs and no existing Pod Chief`() {
            // Arrange
            every { adminRepository.findPodChief(testPodId) } returns null
            every { adminRepository.existsByEmail(validEmail) } returns false
            every { passwordEncoder.encode(any()) } returns "hashedPassword123"
            every { emailService.sendPodChiefWelcomeEmail(any(), any(), any()) } just Runs

            val adminSlot = slot<Admin>()
            every {
                adminRepository.save(capture(adminSlot), any(), any())
            } answers { adminSlot.captured }

            // Act
            val result = service.createPodChief(validEmail, validDisplayName, testPodId)

            // Assert
            result.shouldBeInstanceOf<BootstrapResult.PodChiefCreated>()
            val createdResult = result as BootstrapResult.PodChiefCreated
            createdResult.admin.email shouldBe validEmail
            createdResult.admin.displayName shouldBe validDisplayName
            createdResult.admin.role shouldBe AdminRole.POD_CHIEF
            createdResult.admin.onboardingStatus shouldBe OnboardingStatus.PENDING
            createdResult.admin.podId shouldBe testPodId
            createdResult.temporaryPassword.shouldHaveMinLength(12)
        }

        @Test
        fun `should send welcome email when Pod Chief is created`() {
            // Arrange
            every { adminRepository.findPodChief(testPodId) } returns null
            every { adminRepository.existsByEmail(validEmail) } returns false
            every { passwordEncoder.encode(any()) } returns "hashedPassword123"
            every { emailService.sendPodChiefWelcomeEmail(any(), any(), any()) } just Runs

            val adminSlot = slot<Admin>()
            every {
                adminRepository.save(capture(adminSlot), any(), any())
            } answers { adminSlot.captured }

            // Act
            service.createPodChief(validEmail, validDisplayName, testPodId)

            // Assert
            verify(exactly = 1) {
                emailService.sendPodChiefWelcomeEmail(
                    toEmail = validEmail,
                    displayName = validDisplayName,
                    tempPassword = any(),
                )
            }
        }

        @Test
        fun `should return PodAlreadyBootstrapped when Pod Chief exists`() {
            // Arrange
            val existingPodChief = createPodChief(OnboardingStatus.PENDING)
            every { adminRepository.findPodChief(testPodId) } returns existingPodChief

            // Act
            val result = service.createPodChief(validEmail, validDisplayName, testPodId)

            // Assert
            result.shouldBeInstanceOf<BootstrapResult.PodAlreadyBootstrapped>()
            verify(exactly = 0) { adminRepository.save(any(), any(), any()) }
        }

        @Test
        fun `should return EmailAlreadyExists when email is taken`() {
            // Arrange
            every { adminRepository.findPodChief(testPodId) } returns null
            every { adminRepository.existsByEmail(validEmail) } returns true

            // Act
            val result = service.createPodChief(validEmail, validDisplayName, testPodId)

            // Assert
            result.shouldBeInstanceOf<BootstrapResult.EmailAlreadyExists>()
            val emailError = result as BootstrapResult.EmailAlreadyExists
            emailError.email shouldBe validEmail
            verify(exactly = 0) { adminRepository.save(any(), any(), any()) }
        }

        @Test
        fun `should return ValidationError when email is blank`() {
            // Act
            val result = service.createPodChief("", validDisplayName, testPodId)

            // Assert
            result.shouldBeInstanceOf<BootstrapResult.ValidationError>()
            val validationError = result as BootstrapResult.ValidationError
            validationError.errors.any { it.contains("Email") } shouldBe true
        }

        @Test
        fun `should return ValidationError when email format is invalid`() {
            // Act
            val result = service.createPodChief("not-an-email", validDisplayName, testPodId)

            // Assert
            result.shouldBeInstanceOf<BootstrapResult.ValidationError>()
            val validationError = result as BootstrapResult.ValidationError
            validationError.errors.any { it.contains("email") } shouldBe true
        }

        @Test
        fun `should return ValidationError when displayName is blank`() {
            // Act
            val result = service.createPodChief(validEmail, "", testPodId)

            // Assert
            result.shouldBeInstanceOf<BootstrapResult.ValidationError>()
            val validationError = result as BootstrapResult.ValidationError
            validationError.errors.any { it.contains("Display name") } shouldBe true
        }

        @Test
        fun `should return ValidationError with multiple errors when both fields are invalid`() {
            // Act
            val result = service.createPodChief("", "", testPodId)

            // Assert
            result.shouldBeInstanceOf<BootstrapResult.ValidationError>()
            val validationError = result as BootstrapResult.ValidationError
            validationError.errors.size shouldBe 2
        }

        @Test
        fun `should hash password before saving`() {
            // Arrange
            every { adminRepository.findPodChief(testPodId) } returns null
            every { adminRepository.existsByEmail(validEmail) } returns false
            every { passwordEncoder.encode(any()) } returns "bcryptHashedPassword"
            every { emailService.sendPodChiefWelcomeEmail(any(), any(), any()) } just Runs

            val passwordHashSlot = slot<String>()
            every {
                adminRepository.save(any(), capture(passwordHashSlot), any())
            } answers { firstArg() }

            // Act
            service.createPodChief(validEmail, validDisplayName, testPodId)

            // Assert
            verify { passwordEncoder.encode(any()) }
            passwordHashSlot.captured shouldBe "bcryptHashedPassword"
        }

        @Test
        fun `should use current timestamp from clock for createdAt and updatedAt`() {
            // Arrange
            every { adminRepository.findPodChief(testPodId) } returns null
            every { adminRepository.existsByEmail(validEmail) } returns false
            every { passwordEncoder.encode(any()) } returns "hashedPassword"
            every { emailService.sendPodChiefWelcomeEmail(any(), any(), any()) } just Runs

            val adminSlot = slot<Admin>()
            every {
                adminRepository.save(capture(adminSlot), any(), any())
            } answers { adminSlot.captured }

            // Act
            service.createPodChief(validEmail, validDisplayName, testPodId)

            // Assert
            adminSlot.captured.createdAt shouldBe fixedInstant
            adminSlot.captured.updatedAt shouldBe fixedInstant
        }

        @Test
        fun `should log Pod Chief creation to audit service`() {
            // Arrange
            every { adminRepository.findPodChief(testPodId) } returns null
            every { adminRepository.existsByEmail(validEmail) } returns false
            every { passwordEncoder.encode(any()) } returns "hashedPassword"
            every { emailService.sendPodChiefWelcomeEmail(any(), any(), any()) } just Runs

            val adminSlot = slot<Admin>()
            every {
                adminRepository.save(capture(adminSlot), any(), any())
            } answers { adminSlot.captured }

            // Act
            service.createPodChief(validEmail, validDisplayName, testPodId)

            // Assert
            verify(exactly = 1) {
                auditService.logPodChiefCreated(
                    superUserEmail = "super@example.com",
                    adminId = any(),
                    adminEmail = validEmail,
                    podId = testPodId,
                )
            }
        }

        @Test
        fun `should not log to audit service when validation fails`() {
            // Act
            service.createPodChief("", validDisplayName, testPodId)

            // Assert
            verify(exactly = 0) { auditService.logPodChiefCreated(any(), any(), any(), any(), any(), any()) }
        }

        @Test
        fun `should not log to audit service when Pod Chief already exists`() {
            // Arrange
            val existingPodChief = createPodChief(OnboardingStatus.PENDING)
            every { adminRepository.findPodChief(testPodId) } returns existingPodChief

            // Act
            service.createPodChief(validEmail, validDisplayName, testPodId)

            // Assert
            verify(exactly = 0) { auditService.logPodChiefCreated(any(), any(), any(), any(), any(), any()) }
        }
    }
}
