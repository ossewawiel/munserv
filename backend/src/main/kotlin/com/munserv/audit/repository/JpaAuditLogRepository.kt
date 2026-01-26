package com.munserv.audit.repository

import com.munserv.audit.domain.AuditAction
import com.munserv.audit.domain.AuditLog
import com.munserv.shared.types.PodId
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import java.time.Instant
import java.util.UUID

/**
 * Spring Data JPA repository for AuditLogEntity.
 */
interface AuditLogJpaRepository : JpaRepository<AuditLogEntity, UUID> {
    @Query("SELECT a FROM AuditLogEntity a WHERE a.podId = :podId ORDER BY a.createdAt DESC")
    fun findByPodIdOrderByCreatedAtDesc(podId: UUID): List<AuditLogEntity>

    @Query("SELECT a FROM AuditLogEntity a WHERE a.podId = :podId AND a.action = :action ORDER BY a.createdAt DESC")
    fun findByPodIdAndAction(
        podId: UUID,
        action: String,
    ): List<AuditLogEntity>

    @Query("SELECT a FROM AuditLogEntity a WHERE a.podId = :podId AND a.createdAt BETWEEN :from AND :to ORDER BY a.createdAt DESC")
    fun findByPodIdAndCreatedAtBetween(
        podId: UUID,
        from: Instant,
        to: Instant,
    ): List<AuditLogEntity>
}

/**
 * Implementation of AuditLogRepository using Spring Data JPA.
 */
@Repository
class JpaAuditLogRepositoryImpl(
    private val jpa: AuditLogJpaRepository,
) : AuditLogRepository {
    override fun save(log: AuditLog): AuditLog = jpa.save(AuditLogEntity.fromDomain(log)).toDomain()

    override fun findByPodId(
        podId: PodId,
        limit: Int,
    ): List<AuditLog> =
        jpa.findByPodIdOrderByCreatedAtDesc(podId.value)
            .take(limit)
            .map { it.toDomain() }

    override fun findByPodIdAndAction(
        podId: PodId,
        action: AuditAction,
    ): List<AuditLog> =
        jpa.findByPodIdAndAction(podId.value, action.dbValue)
            .map { it.toDomain() }

    override fun findByPodIdAndDateRange(
        podId: PodId,
        from: Instant,
        to: Instant,
    ): List<AuditLog> =
        jpa.findByPodIdAndCreatedAtBetween(podId.value, from, to)
            .map { it.toDomain() }
}
