package com.munserv.sectors.service

import com.munserv.sectors.domain.SectorSettings
import com.munserv.sectors.repository.SectorRepository
import com.munserv.sectors.repository.SectorSettingsRepository
import com.munserv.shared.types.SectorId
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.time.Instant

/**
 * Service layer for sector settings operations.
 * Handles business logic and coordinates between domain and repository.
 */
@Service
class SectorSettingsService(
    private val settingsRepository: SectorSettingsRepository,
    private val sectorRepository: SectorRepository,
    private val clock: Clock,
) {
    /**
     * Get settings for a sector.
     * Creates default settings if none exist.
     */
    @Transactional(readOnly = true)
    fun getSettings(sectorId: SectorId): SectorSettingsResult {
        if (!sectorRepository.existsById(sectorId)) {
            return SectorSettingsResult.SectorNotFound(sectorId)
        }

        val settings =
            settingsRepository.findBySectorId(sectorId)
                ?: createDefaultSettings(sectorId)

        return SectorSettingsResult.Success(settings)
    }

    /**
     * Update settings for a sector.
     * Creates default settings first if none exist, then applies updates.
     */
    @Transactional
    fun updateSettings(
        sectorId: SectorId,
        command: UpdateSectorSettingsCommand,
    ): SectorSettingsResult {
        // Validate command first
        val errors = command.validate()
        if (errors.isNotEmpty()) {
            return SectorSettingsResult.ValidationError(errors)
        }

        // Check sector exists
        if (!sectorRepository.existsById(sectorId)) {
            return SectorSettingsResult.SectorNotFound(sectorId)
        }

        // Get or create settings
        val settings =
            settingsRepository.findBySectorId(sectorId)
                ?: createDefaultSettings(sectorId)

        // Apply updates
        val now = Instant.now(clock)
        var updated = settings

        command.newIssueVerificationMode?.let {
            updated = updated.withNewIssueVerificationMode(it, now)
        }
        command.fixVerificationMode?.let {
            updated = updated.withFixVerificationMode(it, now)
        }
        command.daysFixedBeforeClosed?.let {
            updated = updated.withDaysFixedBeforeClosed(it, now)
        }
        command.minimumGroundAdmins?.let {
            updated = updated.withMinimumGroundAdmins(it, now)
        }

        // Save and return
        val saved = settingsRepository.save(updated)
        return SectorSettingsResult.Success(saved)
    }

    /**
     * Ensure settings exist for a sector.
     * Called when a new sector is created or when settings are needed.
     */
    @Transactional
    fun ensureSettingsExist(sectorId: SectorId): SectorSettings =
        settingsRepository.findBySectorId(sectorId)
            ?: createDefaultSettings(sectorId)

    private fun createDefaultSettings(sectorId: SectorId): SectorSettings {
        val now = Instant.now(clock)
        val settings = SectorSettings.createDefault(sectorId, now)
        return settingsRepository.save(settings)
    }
}
