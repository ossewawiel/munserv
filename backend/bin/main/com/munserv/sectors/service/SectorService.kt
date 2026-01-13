package com.munserv.sectors.service

import com.munserv.sectors.domain.Sector
import com.munserv.sectors.repository.SectorRepository
import com.munserv.shared.types.SectorId
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

/**
 * Service layer for sector operations.
 */
@Service
class SectorService(
    private val sectorRepository: SectorRepository,
) {
    /**
     * Get all sectors.
     */
    @Transactional(readOnly = true)
    fun findAll(): List<Sector> = sectorRepository.findAll()

    /**
     * Get a sector by ID.
     */
    @Transactional(readOnly = true)
    fun findById(id: SectorId): Sector? = sectorRepository.findById(id)
}
