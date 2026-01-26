package com.munserv.bootstrap.service

import com.munserv.admin.domain.Admin
import com.munserv.admin.domain.AdminRole
import com.munserv.admin.domain.OnboardingStatus
import com.munserv.admin.repository.AdminRepository
import com.munserv.bootstrap.config.BootstrapConfig
import com.munserv.bootstrap.domain.BootstrapStatus
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.PodId
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import java.time.Instant
import java.util.UUID

class BootstrapServiceTest {
    private lateinit var adminRepository: AdminRepository
    private lateinit var bootstrapConfig: BootstrapConfig
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
        service = BootstrapService(adminRepository, bootstrapConfig)
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
}
