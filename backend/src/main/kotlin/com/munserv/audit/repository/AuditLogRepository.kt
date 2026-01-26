package com.munserv.audit.repository

import com.munserv.audit.domain.AuditAction
import com.munserv.audit.domain.AuditLog
import com.munserv.shared.types.PodId
import java.time.Instant

/**
 * Repository interface for audit log persistence.
 */
interface AuditLogRepository {
    fun save(log: AuditLog): AuditLog

    fun findByPodId(
        podId: PodId,
        limit: Int = 100,
    ): List<AuditLog>

    fun findByPodIdAndAction(
        podId: PodId,
        action: AuditAction,
    ): List<AuditLog>

    fun findByPodIdAndDateRange(
        podId: PodId,
        from: Instant,
        to: Instant,
    ): List<AuditLog>
}
