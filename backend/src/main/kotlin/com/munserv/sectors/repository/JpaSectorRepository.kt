package com.munserv.sectors.repository

import com.munserv.sectors.domain.Sector
import com.munserv.shared.types.PodId
import com.munserv.shared.types.SectorId
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.repository.findByIdOrNull
import org.springframework.stereotype.Repository
import java.util.UUID

/**
 * Spring Data JPA repository interface for direct database access.
 */
interface SectorJpaRepository : JpaRepository<SectorEntity, UUID> {
    fun findByPodId(podId: UUID): List<SectorEntity>
}

/**
 * Implementation of domain SectorRepository using Spring Data JPA.
 */
@Repository
class JpaSectorRepository(
    private val jpaRepository: SectorJpaRepository,
) : SectorRepository {
    override fun findById(id: SectorId): Sector? = jpaRepository.findByIdOrNull(id.value)?.toDomain()

    override fun findByPodId(podId: PodId): List<Sector> = jpaRepository.findByPodId(podId.value).map { it.toDomain() }

    override fun findAll(): List<Sector> = jpaRepository.findAll().map { it.toDomain() }

    override fun save(sector: Sector): Sector = jpaRepository.save(SectorEntity.fromDomain(sector)).toDomain()

    override fun existsById(id: SectorId): Boolean = jpaRepository.existsById(id.value)
}
