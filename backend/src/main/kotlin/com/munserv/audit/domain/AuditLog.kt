package com.munserv.audit.domain

import com.munserv.shared.types.PodId
import java.time.Instant
import java.util.UUID

/**
 * Domain model for an audit log entry.
 *
 * Records actions taken by super users and pod chiefs for
 * security traceability and compliance.
 */
data class AuditLog(
    val id: UUID,
    val podId: PodId,
    val action: AuditAction,
    val actorEmail: String,
    val actorType: AuditActorType,
    val targetType: String?,
    val targetId: UUID?,
    val details: Map<String, Any>?,
    val ipAddress: String?,
    val userAgent: String?,
    val createdAt: Instant,
)
