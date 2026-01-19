package com.munserv.sectors.repository

import com.munserv.sectors.domain.SectorSettings
import com.munserv.shared.types.SectorId
import com.munserv.shared.types.SectorSettingsId
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.repository.findByIdOrNull
import org.springframework.stereotype.Repository
import java.util.UUID

/**
 * Spring Data JPA repository interface for direct database access.
 */
interface SectorSettingsJpaRepository : JpaRepository<SectorSettingsEntity, UUID> {
    fun findBySectorId(sectorId: UUID): SectorSettingsEntity?

    fun existsBySectorId(sectorId: UUID): Boolean
}

/**
 * Implementation of domain SectorSettingsRepository using Spring Data JPA.
 */
@Repository
class JpaSectorSettingsRepository(
    private val jpaRepository: SectorSettingsJpaRepository,
) : SectorSettingsRepository {
    override fun findById(id: SectorSettingsId): SectorSettings? = jpaRepository.findByIdOrNull(id.value)?.toDomain()

    override fun findBySectorId(sectorId: SectorId): SectorSettings? = jpaRepository.findBySectorId(sectorId.value)?.toDomain()

    override fun save(settings: SectorSettings): SectorSettings = jpaRepository.save(SectorSettingsEntity.fromDomain(settings)).toDomain()

    override fun existsBySectorId(sectorId: SectorId): Boolean = jpaRepository.existsBySectorId(sectorId.value)
}
