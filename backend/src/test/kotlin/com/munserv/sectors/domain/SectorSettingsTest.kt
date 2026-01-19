package com.munserv.sectors.domain

import com.munserv.shared.enums.VerificationMode
import com.munserv.shared.types.SectorId
import com.munserv.shared.types.SectorSettingsId
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import java.time.Instant
import java.util.UUID

class SectorSettingsTest {
    private val testSectorId = SectorId(UUID.fromString("550e8400-e29b-41d4-a716-446655440001"))
    private val fixedInstant = Instant.parse("2025-01-15T10:00:00Z")

    private fun createTestSettings(
        sectorId: SectorId = testSectorId,
        newIssueVerificationMode: VerificationMode = VerificationMode.ALL_NOTIFIED,
        fixVerificationMode: VerificationMode = VerificationMode.ALL_NOTIFIED,
        daysFixedBeforeClosed: Int = 7,
        minimumGroundAdmins: Int = 2,
        createdAt: Instant = fixedInstant,
        updatedAt: Instant = fixedInstant,
    ) = SectorSettings(
        id = SectorSettingsId.generate(),
        sectorId = sectorId,
        newIssueVerificationMode = newIssueVerificationMode,
        fixVerificationMode = fixVerificationMode,
        daysFixedBeforeClosed = daysFixedBeforeClosed,
        minimumGroundAdmins = minimumGroundAdmins,
        createdAt = createdAt,
        updatedAt = updatedAt,
    )

    @Nested
    inner class Creation {
        @Test
        fun `should create settings with default values`() {
            val settings = SectorSettings.createDefault(testSectorId, fixedInstant)

            settings.sectorId shouldBe testSectorId
            settings.newIssueVerificationMode shouldBe VerificationMode.ALL_NOTIFIED
            settings.fixVerificationMode shouldBe VerificationMode.ALL_NOTIFIED
            settings.daysFixedBeforeClosed shouldBe 7
            settings.minimumGroundAdmins shouldBe 2
            settings.createdAt shouldBe fixedInstant
            settings.updatedAt shouldBe fixedInstant
        }

        @Test
        fun `should create settings with custom values`() {
            val settings =
                createTestSettings(
                    newIssueVerificationMode = VerificationMode.ADMIN_ASSIGNS,
                    fixVerificationMode = VerificationMode.NEAREST_AUTO,
                    daysFixedBeforeClosed = 14,
                    minimumGroundAdmins = 5,
                )

            settings.newIssueVerificationMode shouldBe VerificationMode.ADMIN_ASSIGNS
            settings.fixVerificationMode shouldBe VerificationMode.NEAREST_AUTO
            settings.daysFixedBeforeClosed shouldBe 14
            settings.minimumGroundAdmins shouldBe 5
        }
    }

    @Nested
    inner class ImmutableUpdates {
        @Test
        fun `should update newIssueVerificationMode immutably`() {
            val original = createTestSettings()
            val newInstant = fixedInstant.plusSeconds(3600)

            val updated = original.withNewIssueVerificationMode(VerificationMode.ADMIN_ASSIGNS, newInstant)

            updated.newIssueVerificationMode shouldBe VerificationMode.ADMIN_ASSIGNS
            updated.updatedAt shouldBe newInstant
            original.newIssueVerificationMode shouldBe VerificationMode.ALL_NOTIFIED // Original unchanged
        }

        @Test
        fun `should update fixVerificationMode immutably`() {
            val original = createTestSettings()
            val newInstant = fixedInstant.plusSeconds(3600)

            val updated = original.withFixVerificationMode(VerificationMode.FIRST_COME, newInstant)

            updated.fixVerificationMode shouldBe VerificationMode.FIRST_COME
            updated.updatedAt shouldBe newInstant
        }

        @Test
        fun `should update daysFixedBeforeClosed immutably`() {
            val original = createTestSettings()
            val newInstant = fixedInstant.plusSeconds(3600)

            val updated = original.withDaysFixedBeforeClosed(14, newInstant)

            updated.daysFixedBeforeClosed shouldBe 14
            updated.updatedAt shouldBe newInstant
        }

        @Test
        fun `should update minimumGroundAdmins immutably`() {
            val original = createTestSettings()
            val newInstant = fixedInstant.plusSeconds(3600)

            val updated = original.withMinimumGroundAdmins(5, newInstant)

            updated.minimumGroundAdmins shouldBe 5
            updated.updatedAt shouldBe newInstant
        }

        @Test
        fun `should preserve other fields when updating single field`() {
            val original =
                createTestSettings(
                    newIssueVerificationMode = VerificationMode.ADMIN_ASSIGNS,
                    fixVerificationMode = VerificationMode.NEAREST_AUTO,
                    daysFixedBeforeClosed = 10,
                    minimumGroundAdmins = 3,
                )
            val newInstant = fixedInstant.plusSeconds(3600)

            val updated = original.withDaysFixedBeforeClosed(20, newInstant)

            updated.newIssueVerificationMode shouldBe VerificationMode.ADMIN_ASSIGNS
            updated.fixVerificationMode shouldBe VerificationMode.NEAREST_AUTO
            updated.minimumGroundAdmins shouldBe 3
            updated.daysFixedBeforeClosed shouldBe 20
        }
    }

    @Nested
    inner class SectorSettingsIdTest {
        @Test
        fun `should generate unique IDs`() {
            val id1 = SectorSettingsId.generate()
            val id2 = SectorSettingsId.generate()

            id1 shouldNotBe id2
        }

        @Test
        fun `should create ID from string`() {
            val uuid = "550e8400-e29b-41d4-a716-446655440001"
            val id = SectorSettingsId.fromString(uuid)

            id.toString() shouldBe uuid
        }
    }
}
