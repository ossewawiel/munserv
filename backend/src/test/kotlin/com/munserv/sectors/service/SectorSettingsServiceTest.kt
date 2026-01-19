package com.munserv.sectors.service

import com.munserv.sectors.domain.SectorSettings
import com.munserv.sectors.repository.SectorRepository
import com.munserv.sectors.repository.SectorSettingsRepository
import com.munserv.shared.enums.VerificationMode
import com.munserv.shared.types.SectorId
import com.munserv.shared.types.SectorSettingsId
import io.kotest.matchers.collections.shouldContainAnyOf
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

class SectorSettingsServiceTest {
    private lateinit var settingsRepository: SectorSettingsRepository
    private lateinit var sectorRepository: SectorRepository
    private lateinit var clock: Clock
    private lateinit var service: SectorSettingsService

    private val fixedInstant = Instant.parse("2025-01-15T10:00:00Z")
    private val testSectorId = SectorId(UUID.fromString("550e8400-e29b-41d4-a716-446655440001"))
    private val testSettingsId = SectorSettingsId(UUID.fromString("550e8400-e29b-41d4-a716-446655440010"))

    @BeforeEach
    fun setUp() {
        settingsRepository = mockk()
        sectorRepository = mockk()
        clock = Clock.fixed(fixedInstant, ZoneId.of("UTC"))
        service = SectorSettingsService(settingsRepository, sectorRepository, clock)
    }

    private fun createTestSettings(
        id: SectorSettingsId = testSettingsId,
        sectorId: SectorId = testSectorId,
        newIssueVerificationMode: VerificationMode = VerificationMode.ALL_NOTIFIED,
        fixVerificationMode: VerificationMode = VerificationMode.ALL_NOTIFIED,
        daysFixedBeforeClosed: Int = 7,
        minimumGroundAdmins: Int = 2,
    ) = SectorSettings(
        id = id,
        sectorId = sectorId,
        newIssueVerificationMode = newIssueVerificationMode,
        fixVerificationMode = fixVerificationMode,
        daysFixedBeforeClosed = daysFixedBeforeClosed,
        minimumGroundAdmins = minimumGroundAdmins,
        createdAt = fixedInstant,
        updatedAt = fixedInstant,
    )

    @Nested
    inner class GetSettings {
        @Test
        fun `should return Success with existing settings`() {
            val settings = createTestSettings()
            every { sectorRepository.existsById(testSectorId) } returns true
            every { settingsRepository.findBySectorId(testSectorId) } returns settings

            val result = service.getSettings(testSectorId)

            val success = result.shouldBeInstanceOf<SectorSettingsResult.Success>()
            success.settings shouldBe settings
        }

        @Test
        fun `should create and return default settings when none exist`() {
            val savedSlot = slot<SectorSettings>()
            every { sectorRepository.existsById(testSectorId) } returns true
            every { settingsRepository.findBySectorId(testSectorId) } returns null
            every { settingsRepository.save(capture(savedSlot)) } answers { savedSlot.captured }

            val result = service.getSettings(testSectorId)

            val success = result.shouldBeInstanceOf<SectorSettingsResult.Success>()
            success.settings.sectorId shouldBe testSectorId
            success.settings.newIssueVerificationMode shouldBe VerificationMode.ALL_NOTIFIED
            success.settings.fixVerificationMode shouldBe VerificationMode.ALL_NOTIFIED
            success.settings.daysFixedBeforeClosed shouldBe 7
            success.settings.minimumGroundAdmins shouldBe 2
            verify(exactly = 1) { settingsRepository.save(any()) }
        }

        @Test
        fun `should return NotFound when sector does not exist`() {
            every { sectorRepository.existsById(testSectorId) } returns false

            val result = service.getSettings(testSectorId)

            val notFound = result.shouldBeInstanceOf<SectorSettingsResult.SectorNotFound>()
            notFound.sectorId shouldBe testSectorId
        }
    }

    @Nested
    inner class UpdateSettings {
        @Test
        fun `should update newIssueVerificationMode`() {
            val existingSettings = createTestSettings()
            val savedSlot = slot<SectorSettings>()
            val command =
                UpdateSectorSettingsCommand(
                    newIssueVerificationMode = VerificationMode.ADMIN_ASSIGNS,
                )

            every { sectorRepository.existsById(testSectorId) } returns true
            every { settingsRepository.findBySectorId(testSectorId) } returns existingSettings
            every { settingsRepository.save(capture(savedSlot)) } answers { savedSlot.captured }

            val result = service.updateSettings(testSectorId, command)

            result.shouldBeInstanceOf<SectorSettingsResult.Success>()
            savedSlot.captured.newIssueVerificationMode shouldBe VerificationMode.ADMIN_ASSIGNS
            savedSlot.captured.updatedAt shouldBe fixedInstant
        }

        @Test
        fun `should update fixVerificationMode`() {
            val existingSettings = createTestSettings()
            val savedSlot = slot<SectorSettings>()
            val command =
                UpdateSectorSettingsCommand(
                    fixVerificationMode = VerificationMode.NEAREST_AUTO,
                )

            every { sectorRepository.existsById(testSectorId) } returns true
            every { settingsRepository.findBySectorId(testSectorId) } returns existingSettings
            every { settingsRepository.save(capture(savedSlot)) } answers { savedSlot.captured }

            val result = service.updateSettings(testSectorId, command)

            result.shouldBeInstanceOf<SectorSettingsResult.Success>()
            savedSlot.captured.fixVerificationMode shouldBe VerificationMode.NEAREST_AUTO
        }

        @Test
        fun `should update daysFixedBeforeClosed`() {
            val existingSettings = createTestSettings()
            val savedSlot = slot<SectorSettings>()
            val command =
                UpdateSectorSettingsCommand(
                    daysFixedBeforeClosed = 14,
                )

            every { sectorRepository.existsById(testSectorId) } returns true
            every { settingsRepository.findBySectorId(testSectorId) } returns existingSettings
            every { settingsRepository.save(capture(savedSlot)) } answers { savedSlot.captured }

            val result = service.updateSettings(testSectorId, command)

            result.shouldBeInstanceOf<SectorSettingsResult.Success>()
            savedSlot.captured.daysFixedBeforeClosed shouldBe 14
        }

        @Test
        fun `should update minimumGroundAdmins`() {
            val existingSettings = createTestSettings()
            val savedSlot = slot<SectorSettings>()
            val command =
                UpdateSectorSettingsCommand(
                    minimumGroundAdmins = 5,
                )

            every { sectorRepository.existsById(testSectorId) } returns true
            every { settingsRepository.findBySectorId(testSectorId) } returns existingSettings
            every { settingsRepository.save(capture(savedSlot)) } answers { savedSlot.captured }

            val result = service.updateSettings(testSectorId, command)

            result.shouldBeInstanceOf<SectorSettingsResult.Success>()
            savedSlot.captured.minimumGroundAdmins shouldBe 5
        }

        @Test
        fun `should update multiple fields at once`() {
            val existingSettings = createTestSettings()
            val savedSlot = slot<SectorSettings>()
            val command =
                UpdateSectorSettingsCommand(
                    newIssueVerificationMode = VerificationMode.FIRST_COME,
                    fixVerificationMode = VerificationMode.ADMIN_ASSIGNS,
                    daysFixedBeforeClosed = 30,
                    minimumGroundAdmins = 10,
                )

            every { sectorRepository.existsById(testSectorId) } returns true
            every { settingsRepository.findBySectorId(testSectorId) } returns existingSettings
            every { settingsRepository.save(capture(savedSlot)) } answers { savedSlot.captured }

            val result = service.updateSettings(testSectorId, command)

            result.shouldBeInstanceOf<SectorSettingsResult.Success>()
            savedSlot.captured.newIssueVerificationMode shouldBe VerificationMode.FIRST_COME
            savedSlot.captured.fixVerificationMode shouldBe VerificationMode.ADMIN_ASSIGNS
            savedSlot.captured.daysFixedBeforeClosed shouldBe 30
            savedSlot.captured.minimumGroundAdmins shouldBe 10
        }

        @Test
        fun `should preserve unchanged fields`() {
            val existingSettings =
                createTestSettings(
                    newIssueVerificationMode = VerificationMode.ADMIN_ASSIGNS,
                    fixVerificationMode = VerificationMode.NEAREST_AUTO,
                    daysFixedBeforeClosed = 10,
                    minimumGroundAdmins = 3,
                )
            val savedSlot = slot<SectorSettings>()
            val command =
                UpdateSectorSettingsCommand(
                    daysFixedBeforeClosed = 20,
                )

            every { sectorRepository.existsById(testSectorId) } returns true
            every { settingsRepository.findBySectorId(testSectorId) } returns existingSettings
            every { settingsRepository.save(capture(savedSlot)) } answers { savedSlot.captured }

            val result = service.updateSettings(testSectorId, command)

            result.shouldBeInstanceOf<SectorSettingsResult.Success>()
            savedSlot.captured.newIssueVerificationMode shouldBe VerificationMode.ADMIN_ASSIGNS
            savedSlot.captured.fixVerificationMode shouldBe VerificationMode.NEAREST_AUTO
            savedSlot.captured.minimumGroundAdmins shouldBe 3
            savedSlot.captured.daysFixedBeforeClosed shouldBe 20
        }

        @Test
        fun `should create default settings and update when none exist`() {
            val savedSlot = slot<SectorSettings>()
            val command =
                UpdateSectorSettingsCommand(
                    daysFixedBeforeClosed = 14,
                )

            every { sectorRepository.existsById(testSectorId) } returns true
            every { settingsRepository.findBySectorId(testSectorId) } returns null
            every { settingsRepository.save(capture(savedSlot)) } answers { savedSlot.captured }

            val result = service.updateSettings(testSectorId, command)

            result.shouldBeInstanceOf<SectorSettingsResult.Success>()
            // Default values except the one being updated
            savedSlot.captured.newIssueVerificationMode shouldBe VerificationMode.ALL_NOTIFIED
            savedSlot.captured.fixVerificationMode shouldBe VerificationMode.ALL_NOTIFIED
            savedSlot.captured.minimumGroundAdmins shouldBe 2
            savedSlot.captured.daysFixedBeforeClosed shouldBe 14
        }

        @Test
        fun `should return SectorNotFound when sector does not exist`() {
            val command = UpdateSectorSettingsCommand(daysFixedBeforeClosed = 14)
            every { sectorRepository.existsById(testSectorId) } returns false

            val result = service.updateSettings(testSectorId, command)

            result.shouldBeInstanceOf<SectorSettingsResult.SectorNotFound>()
        }

        @Test
        fun `should return ValidationError when daysFixedBeforeClosed is less than 1`() {
            val command = UpdateSectorSettingsCommand(daysFixedBeforeClosed = 0)
            every { sectorRepository.existsById(testSectorId) } returns true

            val result = service.updateSettings(testSectorId, command)

            val error = result.shouldBeInstanceOf<SectorSettingsResult.ValidationError>()
            error.errors.shouldContainAnyOf("daysFixedBeforeClosed must be at least 1")
        }

        @Test
        fun `should return ValidationError when daysFixedBeforeClosed is greater than 365`() {
            val command = UpdateSectorSettingsCommand(daysFixedBeforeClosed = 400)
            every { sectorRepository.existsById(testSectorId) } returns true

            val result = service.updateSettings(testSectorId, command)

            val error = result.shouldBeInstanceOf<SectorSettingsResult.ValidationError>()
            error.errors.shouldContainAnyOf("daysFixedBeforeClosed must be at most 365")
        }

        @Test
        fun `should return ValidationError when minimumGroundAdmins is negative`() {
            val command = UpdateSectorSettingsCommand(minimumGroundAdmins = -1)
            every { sectorRepository.existsById(testSectorId) } returns true

            val result = service.updateSettings(testSectorId, command)

            val error = result.shouldBeInstanceOf<SectorSettingsResult.ValidationError>()
            error.errors.shouldContainAnyOf("minimumGroundAdmins cannot be negative")
        }

        @Test
        fun `should return ValidationError when minimumGroundAdmins is greater than 100`() {
            val command = UpdateSectorSettingsCommand(minimumGroundAdmins = 150)
            every { sectorRepository.existsById(testSectorId) } returns true

            val result = service.updateSettings(testSectorId, command)

            val error = result.shouldBeInstanceOf<SectorSettingsResult.ValidationError>()
            error.errors.shouldContainAnyOf("minimumGroundAdmins must be at most 100")
        }

        @Test
        fun `should accept daysFixedBeforeClosed at boundary value 1`() {
            val existingSettings = createTestSettings()
            val savedSlot = slot<SectorSettings>()
            val command = UpdateSectorSettingsCommand(daysFixedBeforeClosed = 1)

            every { sectorRepository.existsById(testSectorId) } returns true
            every { settingsRepository.findBySectorId(testSectorId) } returns existingSettings
            every { settingsRepository.save(capture(savedSlot)) } answers { savedSlot.captured }

            val result = service.updateSettings(testSectorId, command)

            result.shouldBeInstanceOf<SectorSettingsResult.Success>()
            savedSlot.captured.daysFixedBeforeClosed shouldBe 1
        }

        @Test
        fun `should accept daysFixedBeforeClosed at boundary value 365`() {
            val existingSettings = createTestSettings()
            val savedSlot = slot<SectorSettings>()
            val command = UpdateSectorSettingsCommand(daysFixedBeforeClosed = 365)

            every { sectorRepository.existsById(testSectorId) } returns true
            every { settingsRepository.findBySectorId(testSectorId) } returns existingSettings
            every { settingsRepository.save(capture(savedSlot)) } answers { savedSlot.captured }

            val result = service.updateSettings(testSectorId, command)

            result.shouldBeInstanceOf<SectorSettingsResult.Success>()
            savedSlot.captured.daysFixedBeforeClosed shouldBe 365
        }

        @Test
        fun `should accept minimumGroundAdmins at boundary value 0`() {
            val existingSettings = createTestSettings()
            val savedSlot = slot<SectorSettings>()
            val command = UpdateSectorSettingsCommand(minimumGroundAdmins = 0)

            every { sectorRepository.existsById(testSectorId) } returns true
            every { settingsRepository.findBySectorId(testSectorId) } returns existingSettings
            every { settingsRepository.save(capture(savedSlot)) } answers { savedSlot.captured }

            val result = service.updateSettings(testSectorId, command)

            result.shouldBeInstanceOf<SectorSettingsResult.Success>()
            savedSlot.captured.minimumGroundAdmins shouldBe 0
        }

        @Test
        fun `should accept minimumGroundAdmins at boundary value 100`() {
            val existingSettings = createTestSettings()
            val savedSlot = slot<SectorSettings>()
            val command = UpdateSectorSettingsCommand(minimumGroundAdmins = 100)

            every { sectorRepository.existsById(testSectorId) } returns true
            every { settingsRepository.findBySectorId(testSectorId) } returns existingSettings
            every { settingsRepository.save(capture(savedSlot)) } answers { savedSlot.captured }

            val result = service.updateSettings(testSectorId, command)

            result.shouldBeInstanceOf<SectorSettingsResult.Success>()
            savedSlot.captured.minimumGroundAdmins shouldBe 100
        }

        @Test
        fun `should return multiple validation errors for multiple invalid values`() {
            val command =
                UpdateSectorSettingsCommand(
                    daysFixedBeforeClosed = 0,
                    minimumGroundAdmins = -1,
                )
            every { sectorRepository.existsById(testSectorId) } returns true

            val result = service.updateSettings(testSectorId, command)

            val error = result.shouldBeInstanceOf<SectorSettingsResult.ValidationError>()
            error.errors shouldHaveSize 2
        }
    }

    @Nested
    inner class EnsureSettingsExist {
        @Test
        fun `should return existing settings`() {
            val existingSettings = createTestSettings()
            every { settingsRepository.findBySectorId(testSectorId) } returns existingSettings

            val result = service.ensureSettingsExist(testSectorId)

            result shouldBe existingSettings
        }

        @Test
        fun `should create and return default settings when none exist`() {
            val savedSlot = slot<SectorSettings>()
            every { settingsRepository.findBySectorId(testSectorId) } returns null
            every { settingsRepository.save(capture(savedSlot)) } answers { savedSlot.captured }

            val result = service.ensureSettingsExist(testSectorId)

            result.sectorId shouldBe testSectorId
            result.newIssueVerificationMode shouldBe VerificationMode.ALL_NOTIFIED
            verify(exactly = 1) { settingsRepository.save(any()) }
        }
    }
}
