package com.munserv.sectors.repository

import com.munserv.sectors.domain.SectorSettings
import com.munserv.shared.types.SectorId
import com.munserv.shared.types.SectorSettingsId

/**
 * Domain repository interface for SectorSettings operations.
 * Implementations handle data access concerns.
 */
interface SectorSettingsRepository {
    fun findById(id: SectorSettingsId): SectorSettings?

    fun findBySectorId(sectorId: SectorId): SectorSettings?

    fun save(settings: SectorSettings): SectorSettings

    fun existsBySectorId(sectorId: SectorId): Boolean
}
