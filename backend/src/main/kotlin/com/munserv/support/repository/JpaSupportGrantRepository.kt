package com.munserv.support.repository

import com.munserv.shared.types.PodId
import com.munserv.support.domain.SupportGrant
import com.munserv.support.domain.SupportGrantId
import com.munserv.support.domain.SupportGrantStatus
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.findByIdOrNull
import org.springframework.stereotype.Repository
import java.time.Instant
import java.util.UUID

/**
 * Spring Data JPA repository for SupportGrantEntity.
 */
interface SupportGrantJpaRepository : JpaRepository<SupportGrantEntity, UUID> {
    @Query("SELECT g FROM SupportGrantEntity g WHERE g.podId = :podId ORDER BY g.grantedAt DESC")
    fun findByPodIdOrderByGrantedAtDesc(podId: UUID): List<SupportGrantEntity>

    @Query(
        "SELECT g FROM SupportGrantEntity g WHERE g.podId = :podId AND g.status = :status " +
            "ORDER BY g.grantedAt DESC",
    )
    fun findByPodIdAndStatus(
        podId: UUID,
        status: String,
    ): List<SupportGrantEntity>

    @Query("SELECT g FROM SupportGrantEntity g WHERE g.podId = :podId AND g.status = 'active'")
    fun findActiveByPodId(podId: UUID): SupportGrantEntity?

    @Query("SELECT g FROM SupportGrantEntity g WHERE g.status = 'active' AND g.expiresAt <= :now")
    fun findExpiredActive(now: Instant): List<SupportGrantEntity>
}

/**
 * Implementation of SupportGrantRepository using Spring Data JPA.
 */
@Repository
class JpaSupportGrantRepositoryImpl(
    private val jpa: SupportGrantJpaRepository,
) : SupportGrantRepository {
    override fun findById(id: SupportGrantId): SupportGrant? = jpa.findByIdOrNull(id.value)?.toDomain()

    override fun save(grant: SupportGrant): SupportGrant = jpa.save(SupportGrantEntity.fromDomain(grant)).toDomain()

    override fun findByPodId(podId: PodId): List<SupportGrant> =
        jpa
            .findByPodIdOrderByGrantedAtDesc(podId.value)
            .map { it.toDomain() }

    override fun findByPodIdAndStatus(
        podId: PodId,
        status: SupportGrantStatus,
    ): List<SupportGrant> =
        jpa
            .findByPodIdAndStatus(podId.value, status.toDbValue())
            .map { it.toDomain() }

    override fun findActiveByPodId(podId: PodId): SupportGrant? = jpa.findActiveByPodId(podId.value)?.toDomain()

    override fun findExpiredActive(now: Instant): List<SupportGrant> =
        jpa
            .findExpiredActive(now)
            .map { it.toDomain() }
}
