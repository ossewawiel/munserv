package com.munserv.support.domain

import com.munserv.admin.domain.AdminRole
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.PodId
import java.time.Duration
import java.time.Instant

/**
 * Domain entity for a temporary super user support grant.
 *
 * A pod has at most one active grant at a time. The grant expires one hour after the later
 * of [grantedAt] and [lastActivity]; activity by the super user slides that window forward,
 * it never extends beyond one idle hour.
 */
data class SupportGrant(
    val id: SupportGrantId,
    val podId: PodId,
    val grantedRole: AdminRole,
    val purpose: String,
    val grantedBy: AdminId,
    val grantedAt: Instant,
    val expiresAt: Instant,
    val lastActivity: Instant? = null,
    val status: SupportGrantStatus = SupportGrantStatus.ACTIVE,
    val revokedAt: Instant? = null,
    val revokedBy: AdminId? = null,
    val expiredAt: Instant? = null,
) {
    /**
     * Returns true when the grant is still active at [now], i.e. its status is
     * [SupportGrantStatus.ACTIVE] and [expiresAt] has not yet passed.
     */
    fun isActiveAt(now: Instant): Boolean = status == SupportGrantStatus.ACTIVE && now.isBefore(expiresAt)

    /**
     * Records activity at [now], sliding the expiry one idle hour forward.
     */
    fun withActivity(now: Instant): SupportGrant =
        copy(
            lastActivity = now,
            expiresAt = now.plus(INACTIVITY_WINDOW),
        )

    /**
     * Transitions the grant to `revoked`.
     *
     * @param by the pod chief who revoked the grant, or null for a system-initiated revocation (logout).
     */
    fun revoked(
        now: Instant,
        by: AdminId?,
    ): SupportGrant =
        copy(
            status = SupportGrantStatus.REVOKED,
            revokedAt = now,
            revokedBy = by,
        )

    /**
     * Transitions the grant to `expired`.
     */
    fun expired(now: Instant): SupportGrant =
        copy(
            status = SupportGrantStatus.EXPIRED,
            expiredAt = now,
        )

    companion object {
        val INACTIVITY_WINDOW: Duration = Duration.ofHours(1)

        fun create(
            id: SupportGrantId,
            podId: PodId,
            grantedRole: AdminRole,
            purpose: String,
            grantedBy: AdminId,
            grantedAt: Instant,
        ): SupportGrant =
            SupportGrant(
                id = id,
                podId = podId,
                grantedRole = grantedRole,
                purpose = purpose,
                grantedBy = grantedBy,
                grantedAt = grantedAt,
                expiresAt = grantedAt.plus(INACTIVITY_WINDOW),
            )
    }
}
