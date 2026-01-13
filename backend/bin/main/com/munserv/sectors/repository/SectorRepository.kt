package com.munserv.sectors.repository

import com.munserv.sectors.domain.Sector
import com.munserv.shared.types.PodId
import com.munserv.shared.types.SectorId

/**
 * Domain repository interface for Sector operations.
 * Implementations should handle data access concerns.
 */
interface SectorRepository {
    fun findById(id: SectorId): Sector?

    fun findByPodId(podId: PodId): List<Sector>

    fun findAll(): List<Sector>

    fun save(sector: Sector): Sector

    fun existsById(id: SectorId): Boolean
}
