package com.munserv.audit.repository

import com.munserv.audit.domain.AuditAction
import com.munserv.audit.domain.AuditActorType
import com.munserv.audit.domain.AuditLog
import com.munserv.shared.types.PodId
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import org.hibernate.annotations.ColumnTransformer
import org.hibernate.annotations.JdbcTypeCode
import org.hibernate.type.SqlTypes
import java.time.Instant
import java.util.UUID

/**
 * JPA entity for audit_logs table.
 */
@Entity
@Table(name = "audit_logs")
class AuditLogEntity(
    @Id
    val id: UUID,
    @Column(name = "pod_id", nullable = false)
    val podId: UUID,
    @Column(nullable = false, columnDefinition = "audit_action_type")
    @ColumnTransformer(write = "?::audit_action_type")
    val action: String,
    @Column(name = "actor_email", nullable = false)
    val actorEmail: String,
    @Column(name = "actor_type", nullable = false)
    val actorType: String,
    @Column(name = "target_type")
    val targetType: String?,
    @Column(name = "target_id")
    val targetId: UUID?,
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    val details: Map<String, Any>?,
    @Column(name = "ip_address")
    val ipAddress: String?,
    @Column(name = "user_agent")
    val userAgent: String?,
    @Column(name = "created_at", nullable = false)
    val createdAt: Instant,
) {
    /**
     * Convert JPA entity to domain model.
     */
    fun toDomain(): AuditLog =
        AuditLog(
            id = id,
            podId = PodId(podId),
            action = AuditAction.fromDbValue(action),
            actorEmail = actorEmail,
            actorType = AuditActorType.fromDbValue(actorType),
            targetType = targetType,
            targetId = targetId,
            details = details,
            ipAddress = ipAddress,
            userAgent = userAgent,
            createdAt = createdAt,
        )

    companion object {
        /**
         * Convert domain model to JPA entity.
         */
        fun fromDomain(log: AuditLog): AuditLogEntity =
            AuditLogEntity(
                id = log.id,
                podId = log.podId.value,
                action = log.action.dbValue,
                actorEmail = log.actorEmail,
                actorType = log.actorType.dbValue,
                targetType = log.targetType,
                targetId = log.targetId,
                details = log.details,
                ipAddress = log.ipAddress,
                userAgent = log.userAgent,
                createdAt = log.createdAt,
            )
    }
}
