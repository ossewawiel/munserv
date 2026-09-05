package com.munserv.support.repository

import com.munserv.admin.domain.AdminRole
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.PodId
import com.munserv.support.domain.SupportGrant
import com.munserv.support.domain.SupportGrantId
import com.munserv.support.domain.SupportGrantStatus
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.time.Instant
import java.util.UUID

/**
 * JPA entity for support_grants table.
 */
@Entity
@Table(name = "support_grants")
class SupportGrantEntity(
    @Id
    val id: UUID,
    @Column(name = "pod_id", nullable = false)
    val podId: UUID,
    @Column(name = "granted_role", nullable = false)
    val grantedRole: String,
    @Column(nullable = false)
    val purpose: String,
    @Column(name = "granted_by", nullable = false)
    val grantedBy: UUID,
    @Column(name = "granted_at", nullable = false)
    val grantedAt: Instant,
    @Column(name = "expires_at", nullable = false)
    val expiresAt: Instant,
    @Column(name = "last_activity")
    val lastActivity: Instant?,
    @Column(nullable = false)
    val status: String,
    @Column(name = "revoked_at")
    val revokedAt: Instant?,
    @Column(name = "revoked_by")
    val revokedBy: UUID?,
    @Column(name = "expired_at")
    val expiredAt: Instant?,
    @Column(name = "created_at", nullable = false)
    val createdAt: Instant,
) {
    /**
     * Convert JPA entity to domain model.
     */
    fun toDomain(): SupportGrant =
        SupportGrant(
            id = SupportGrantId(id),
            podId = PodId(podId),
            grantedRole = AdminRole.fromDbValue(grantedRole),
            purpose = purpose,
            grantedBy = AdminId(grantedBy),
            grantedAt = grantedAt,
            expiresAt = expiresAt,
            lastActivity = lastActivity,
            status = SupportGrantStatus.fromDbValue(status),
            revokedAt = revokedAt,
            revokedBy = revokedBy?.let { AdminId(it) },
            expiredAt = expiredAt,
        )

    companion object {
        /**
         * Convert domain model to JPA entity.
         */
        fun fromDomain(grant: SupportGrant): SupportGrantEntity =
            SupportGrantEntity(
                id = grant.id.value,
                podId = grant.podId.value,
                grantedRole = grant.grantedRole.toDbValue(),
                purpose = grant.purpose,
                grantedBy = grant.grantedBy.value,
                grantedAt = grant.grantedAt,
                expiresAt = grant.expiresAt,
                lastActivity = grant.lastActivity,
                status = grant.status.toDbValue(),
                revokedAt = grant.revokedAt,
                revokedBy = grant.revokedBy?.value,
                expiredAt = grant.expiredAt,
                createdAt = grant.grantedAt,
            )
    }
}
