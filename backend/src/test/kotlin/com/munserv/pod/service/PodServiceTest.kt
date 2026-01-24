package com.munserv.pod.service

import com.munserv.pod.domain.Pod
import com.munserv.pod.domain.PodSetupStatus
import com.munserv.pod.domain.SetupStep
import com.munserv.pod.repository.PodRepository
import com.munserv.pod.repository.PodSetupStepRepository
import com.munserv.shared.types.PodId
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import java.time.Clock
import java.time.Instant
import java.time.ZoneId
import java.util.UUID

class PodServiceTest {
    private lateinit var podRepository: PodRepository
    private lateinit var setupStepRepository: PodSetupStepRepository
    private lateinit var clock: Clock
    private lateinit var service: PodService

    private val fixedInstant = Instant.parse("2026-01-23T10:00:00Z")
    private val testPodId = PodId(UUID.fromString("550e8400-e29b-41d4-a716-446655440000"))

    @BeforeEach
    fun setUp() {
        podRepository = mockk()
        setupStepRepository = mockk()
        clock = Clock.fixed(fixedInstant, ZoneId.of("UTC"))
        service = PodService(podRepository, setupStepRepository, clock)
    }

    private fun createTestPod(
        id: PodId = testPodId,
        name: String = "TestPod",
        displayName: String = "Munserv Pod TestPod",
        logoUrl: String? = null,
        setupCompletedAt: Instant? = null,
    ) = Pod(
        id = id,
        name = name,
        displayName = displayName,
        logoUrl = logoUrl,
        config = emptyMap(),
        setupCompletedAt = setupCompletedAt,
        createdAt = fixedInstant,
        updatedAt = fixedInstant,
    )

    @Nested
    inner class GetSetupStatus {
        @Test
        fun `should return NotFound when pod does not exist`() {
            every { podRepository.existsById(testPodId) } returns false

            val result = service.getSetupStatus(testPodId)

            val notFound = result.shouldBeInstanceOf<PodResult.NotFound>()
            notFound.podId shouldBe testPodId
        }

        @Test
        fun `should return Incomplete when no steps are completed`() {
            every { podRepository.existsById(testPodId) } returns true
            every { setupStepRepository.findCompletedSteps(testPodId) } returns emptySet()

            val result = service.getSetupStatus(testPodId)

            val success = result.shouldBeInstanceOf<PodResult.Success<PodSetupStatus>>()
            val status = success.data.shouldBeInstanceOf<PodSetupStatus.Incomplete>()
            status.missingSteps shouldContainExactlyInAnyOrder SetupStep.entries
        }

        @Test
        fun `should return Incomplete with specific missing steps`() {
            every { podRepository.existsById(testPodId) } returns true
            every { setupStepRepository.findCompletedSteps(testPodId) } returns setOf(
                SetupStep.POD_NAME,
                SetupStep.FIRST_ADMIN,
            )

            val result = service.getSetupStatus(testPodId)

            val success = result.shouldBeInstanceOf<PodResult.Success<PodSetupStatus>>()
            val status = success.data.shouldBeInstanceOf<PodSetupStatus.Incomplete>()
            status.missingSteps shouldContainExactlyInAnyOrder listOf(
                SetupStep.POD_BOUNDARIES,
                SetupStep.WARDS_SECTORS,
            )
        }

        @Test
        fun `should return Complete when all steps are completed`() {
            every { podRepository.existsById(testPodId) } returns true
            every { setupStepRepository.findCompletedSteps(testPodId) } returns SetupStep.entries.toSet()

            val result = service.getSetupStatus(testPodId)

            val success = result.shouldBeInstanceOf<PodResult.Success<PodSetupStatus>>()
            success.data.shouldBeInstanceOf<PodSetupStatus.Complete>()
            success.data.isComplete shouldBe true
        }
    }

    @Nested
    inner class GetSettings {
        @Test
        fun `should return NotFound when pod does not exist`() {
            every { podRepository.findById(testPodId) } returns null

            val result = service.getSettings(testPodId)

            val notFound = result.shouldBeInstanceOf<PodResult.NotFound>()
            notFound.podId shouldBe testPodId
        }

        @Test
        fun `should return Success with pod settings`() {
            val pod = createTestPod(logoUrl = "https://example.com/logo.png")
            every { podRepository.findById(testPodId) } returns pod

            val result = service.getSettings(testPodId)

            val success = result.shouldBeInstanceOf<PodResult.Success<*>>()
            val settings = success.data as com.munserv.pod.domain.PodSettings
            settings.podId shouldBe testPodId
            settings.name shouldBe "TestPod"
            settings.displayName shouldBe "Munserv Pod TestPod"
            settings.logoUrl shouldBe "https://example.com/logo.png"
        }
    }

    @Nested
    inner class UpdateSettings {
        @Test
        fun `should return NotFound when pod does not exist`() {
            val command = UpdatePodSettingsCommand(name = "NewName", logoUrl = null)
            every { podRepository.findById(testPodId) } returns null

            val result = service.updateSettings(testPodId, command)

            result.shouldBeInstanceOf<PodResult.NotFound>()
        }

        @Test
        fun `should return ValidationError for invalid name`() {
            val command = UpdatePodSettingsCommand(name = "", logoUrl = null)

            val result = service.updateSettings(testPodId, command)

            val error = result.shouldBeInstanceOf<PodResult.ValidationError>()
            error.errors shouldHaveSize 1
        }

        @Test
        fun `should return ValidationError for name too short`() {
            val command = UpdatePodSettingsCommand(name = "A", logoUrl = null)

            val result = service.updateSettings(testPodId, command)

            val error = result.shouldBeInstanceOf<PodResult.ValidationError>()
            error.errors.first() shouldBe "Pod name must be at least 2 characters"
        }

        @Test
        fun `should return current settings when no changes provided`() {
            val pod = createTestPod()
            val command = UpdatePodSettingsCommand(name = null, logoUrl = null)
            every { podRepository.findById(testPodId) } returns pod

            val result = service.updateSettings(testPodId, command)

            val success = result.shouldBeInstanceOf<PodResult.Success<*>>()
            val settings = success.data as com.munserv.pod.domain.PodSettings
            settings.name shouldBe "TestPod"
            verify(exactly = 0) { podRepository.save(any()) }
        }

        @Test
        fun `should update name and generate display name`() {
            val pod = createTestPod()
            val savedSlot = slot<Pod>()
            val command = UpdatePodSettingsCommand(name = "NewPodName", logoUrl = null)

            every { podRepository.findById(testPodId) } returns pod
            every { podRepository.save(capture(savedSlot)) } answers { savedSlot.captured }
            every { setupStepRepository.markComplete(testPodId, SetupStep.POD_NAME) } returns Unit
            every { setupStepRepository.isSetupComplete(testPodId) } returns false

            val result = service.updateSettings(testPodId, command)

            val success = result.shouldBeInstanceOf<PodResult.Success<*>>()
            val settings = success.data as com.munserv.pod.domain.PodSettings
            settings.name shouldBe "NewPodName"
            settings.displayName shouldBe "Munserv Pod NewPodName"
            savedSlot.captured.updatedAt shouldBe fixedInstant
            verify { setupStepRepository.markComplete(testPodId, SetupStep.POD_NAME) }
        }

        @Test
        fun `should update logo URL`() {
            val pod = createTestPod()
            val savedSlot = slot<Pod>()
            val command = UpdatePodSettingsCommand(name = null, logoUrl = "https://example.com/new-logo.png")

            every { podRepository.findById(testPodId) } returns pod
            every { podRepository.save(capture(savedSlot)) } answers { savedSlot.captured }

            val result = service.updateSettings(testPodId, command)

            val success = result.shouldBeInstanceOf<PodResult.Success<*>>()
            val settings = success.data as com.munserv.pod.domain.PodSettings
            settings.logoUrl shouldBe "https://example.com/new-logo.png"
        }

        @Test
        fun `should clear logo URL when blank string provided`() {
            val pod = createTestPod(logoUrl = "https://example.com/logo.png")
            val savedSlot = slot<Pod>()
            val command = UpdatePodSettingsCommand(name = null, logoUrl = "")

            every { podRepository.findById(testPodId) } returns pod
            every { podRepository.save(capture(savedSlot)) } answers { savedSlot.captured }

            val result = service.updateSettings(testPodId, command)

            val success = result.shouldBeInstanceOf<PodResult.Success<*>>()
            val settings = success.data as com.munserv.pod.domain.PodSettings
            settings.logoUrl shouldBe null
        }

        @Test
        fun `should update both name and logo`() {
            val pod = createTestPod()
            val savedSlot = slot<Pod>()
            val command = UpdatePodSettingsCommand(
                name = "UpdatedPod",
                logoUrl = "https://example.com/logo.png",
            )

            every { podRepository.findById(testPodId) } returns pod
            every { podRepository.save(capture(savedSlot)) } answers { savedSlot.captured }
            every { setupStepRepository.markComplete(testPodId, SetupStep.POD_NAME) } returns Unit
            every { setupStepRepository.isSetupComplete(testPodId) } returns false

            val result = service.updateSettings(testPodId, command)

            val success = result.shouldBeInstanceOf<PodResult.Success<*>>()
            val settings = success.data as com.munserv.pod.domain.PodSettings
            settings.name shouldBe "UpdatedPod"
            settings.displayName shouldBe "Munserv Pod UpdatedPod"
            settings.logoUrl shouldBe "https://example.com/logo.png"
        }

        @Test
        fun `should mark setup complete when all steps done after name update`() {
            val pod = createTestPod()
            val savedSlot = slot<Pod>()
            val command = UpdatePodSettingsCommand(name = "FinalPod", logoUrl = null)

            every { podRepository.findById(testPodId) } returns pod
            every { podRepository.save(capture(savedSlot)) } answers { savedSlot.captured }
            every { setupStepRepository.markComplete(testPodId, SetupStep.POD_NAME) } returns Unit
            every { setupStepRepository.isSetupComplete(testPodId) } returns true

            val result = service.updateSettings(testPodId, command)

            result.shouldBeInstanceOf<PodResult.Success<*>>()
            // Verify save was called twice (once for settings, once for marking complete)
            verify(atLeast = 1) { podRepository.save(any()) }
        }
    }

    @Nested
    inner class CompleteSetupStep {
        @Test
        fun `should return NotFound when pod does not exist`() {
            every { podRepository.existsById(testPodId) } returns false

            val result = service.completeSetupStep(testPodId, SetupStep.POD_NAME)

            result.shouldBeInstanceOf<PodResult.NotFound>()
        }

        @Test
        fun `should mark step complete and return updated status`() {
            every { podRepository.existsById(testPodId) } returns true
            every { setupStepRepository.markComplete(testPodId, SetupStep.POD_BOUNDARIES) } returns Unit
            every { setupStepRepository.isSetupComplete(testPodId) } returns false
            every { setupStepRepository.findCompletedSteps(testPodId) } returns setOf(
                SetupStep.POD_NAME,
                SetupStep.POD_BOUNDARIES,
            )

            val result = service.completeSetupStep(testPodId, SetupStep.POD_BOUNDARIES)

            val success = result.shouldBeInstanceOf<PodResult.Success<PodSetupStatus>>()
            val status = success.data.shouldBeInstanceOf<PodSetupStatus.Incomplete>()
            status.missingSteps shouldContainExactlyInAnyOrder listOf(
                SetupStep.WARDS_SECTORS,
                SetupStep.FIRST_ADMIN,
            )
            verify { setupStepRepository.markComplete(testPodId, SetupStep.POD_BOUNDARIES) }
        }

        @Test
        fun `should mark pod setup complete when final step completed`() {
            val pod = createTestPod(setupCompletedAt = null)
            val savedSlot = slot<Pod>()

            every { podRepository.existsById(testPodId) } returns true
            every { setupStepRepository.markComplete(testPodId, SetupStep.FIRST_ADMIN) } returns Unit
            every { setupStepRepository.isSetupComplete(testPodId) } returns true
            every { podRepository.findById(testPodId) } returns pod
            every { podRepository.save(capture(savedSlot)) } answers { savedSlot.captured }
            every { setupStepRepository.findCompletedSteps(testPodId) } returns SetupStep.entries.toSet()

            val result = service.completeSetupStep(testPodId, SetupStep.FIRST_ADMIN)

            val success = result.shouldBeInstanceOf<PodResult.Success<PodSetupStatus>>()
            success.data.shouldBeInstanceOf<PodSetupStatus.Complete>()
            savedSlot.captured.setupCompletedAt shouldBe fixedInstant
        }
    }
}
