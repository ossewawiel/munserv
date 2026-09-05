package com.munserv.support.service

import com.munserv.admin.domain.AdminRole
import com.munserv.admin.repository.AdminRepository
import com.munserv.audit.domain.AuditActorType
import com.munserv.audit.service.AuditService
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.PodId
import com.munserv.support.domain.SupportGrant
import com.munserv.support.domain.SupportGrantId
import com.munserv.support.domain.SupportGrantStatus
import com.munserv.support.repository.SupportGrantRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.time.Duration
import java.time.Instant

/**
 * Service for granting, listing, revoking and expiring temporary super user support access.
 *
 * Only a pod chief may grant or revoke support access for their own pod. Grant activity
 * (from the super user acting under a grant) is tracked separately via [recordActivity].
 */
@Service
class SupportAccessService(
    private val supportGrantRepository: SupportGrantRepository,
    private val adminRepository: AdminRepository,
    private val auditService: AuditService,
    private val clock: Clock = Clock.systemUTC(),
) {
    /**
     * Grant temporary support access to the super user for the actor's pod.
     */
    @Transactional
    fun grant(
        actor: AdminId,
        role: AdminRole,
        purpose: String,
    ): SupportAccessResult {
        val admin = adminRepository.findById(actor) ?: return SupportAccessResult.NotAuthorized
        val podId = admin.podId
        if (admin.role != AdminRole.POD_CHIEF || podId == null) {
            return SupportAccessResult.NotAuthorized
        }

        val errors = mutableListOf<String>()
        if (purpose.isBlank() || purpose.length !in PURPOSE_MIN_LENGTH..PURPOSE_MAX_LENGTH) {
            errors.add("Purpose must be between $PURPOSE_MIN_LENGTH and $PURPOSE_MAX_LENGTH characters")
        }
        if (!AdminRole.POD_CHIEF.canManage(role)) {
            errors.add("Granted role must be strictly below pod_chief")
        }
        if (errors.isNotEmpty()) {
            return SupportAccessResult.ValidationError(errors)
        }

        if (supportGrantRepository.findActiveByPodId(podId) != null) {
            return SupportAccessResult.ActiveGrantExists
        }

        val grant =
            SupportGrant.create(
                id = SupportGrantId.generate(),
                podId = podId,
                grantedRole = role,
                purpose = purpose,
                grantedBy = actor,
                grantedAt = Instant.now(clock),
            )
        val saved = supportGrantRepository.save(grant)

        auditService.logSupportAccessGranted(
            podChiefEmail = admin.email,
            grantId = saved.id.value,
            grantedRole = saved.grantedRole.toDbValue(),
            purpose = saved.purpose,
            podId = podId,
        )

        return SupportAccessResult.Granted(SupportGrantView(saved, admin.displayName))
    }

    /**
     * List support grants for the actor's pod, optionally filtered by status.
     */
    fun list(
        actor: AdminId,
        status: SupportGrantStatus?,
    ): SupportAccessResult {
        val admin = adminRepository.findById(actor) ?: return SupportAccessResult.NotAuthorized
        val podId = admin.podId
        if (admin.role != AdminRole.POD_CHIEF || podId == null) {
            return SupportAccessResult.NotAuthorized
        }

        val grants =
            if (status != null) {
                supportGrantRepository.findByPodIdAndStatus(podId, status)
            } else {
                supportGrantRepository.findByPodId(podId)
            }

        val views =
            grants.map { grant ->
                val grantedByAdmin = adminRepository.findById(grant.grantedBy)
                SupportGrantView(grant, grantedByAdmin?.displayName ?: "Unknown")
            }

        return SupportAccessResult.Grants(views)
    }

    /**
     * Revoke an active support grant on behalf of the pod chief.
     */
    @Transactional
    fun revoke(
        actor: AdminId,
        id: SupportGrantId,
    ): SupportAccessResult {
        val admin = adminRepository.findById(actor) ?: return SupportAccessResult.NotAuthorized
        val grant = supportGrantRepository.findById(id) ?: return SupportAccessResult.NotFound

        if (admin.podId != grant.podId) {
            return SupportAccessResult.NotAuthorized
        }
        if (!grant.status.canTransitionTo(SupportGrantStatus.REVOKED)) {
            return SupportAccessResult.GrantNotActive
        }

        val revoked = grant.revoked(Instant.now(clock), actor)
        supportGrantRepository.save(revoked)

        auditService.logSupportAccessRevoked(
            revokerEmail = admin.email,
            actorType = AuditActorType.POD_CHIEF,
            grantId = revoked.id.value,
            reason = "revoked_by_pod_chief",
            podId = revoked.podId,
        )

        return SupportAccessResult.Revoked
    }

    /**
     * Revoke a grant when the super user logs out. Called by the auth flow (W29).
     */
    @Transactional
    fun revokeOnLogout(id: SupportGrantId): SupportAccessResult {
        val grant = supportGrantRepository.findById(id) ?: return SupportAccessResult.NotFound
        if (!grant.status.canTransitionTo(SupportGrantStatus.REVOKED)) {
            return SupportAccessResult.GrantNotActive
        }

        val revoked = grant.revoked(Instant.now(clock), null)
        supportGrantRepository.save(revoked)

        auditService.logSupportAccessRevoked(
            revokerEmail = "system",
            actorType = AuditActorType.SYSTEM,
            grantId = revoked.id.value,
            reason = "logout",
            podId = revoked.podId,
        )

        return SupportAccessResult.Revoked
    }

    /**
     * Log the super user in under the pod's active support grant.
     *
     * Called by the auth flow (B9) when the pod is not bootstrap-eligible. Writes a
     * `SUPPORT_ACCESS_LOGIN` audit entry on success.
     */
    @Transactional
    fun loginUnderGrant(
        podId: PodId,
        superUserEmail: String,
    ): SupportAccessResult {
        val grant =
            supportGrantRepository.findActiveByPodId(podId)
                ?: return SupportAccessResult.NotFound
        if (!grant.isActiveAt(Instant.now(clock))) {
            return SupportAccessResult.GrantNotActive
        }

        auditService.logSupportAccessLogin(superUserEmail, grant.id.value, podId)

        val grantedByAdmin = adminRepository.findById(grant.grantedBy)
        return SupportAccessResult.Granted(SupportGrantView(grant, grantedByAdmin?.displayName ?: "Unknown"))
    }

    /**
     * Return the caller's own grant, for a grant-scoped token to check its status.
     */
    fun currentGrant(id: SupportGrantId): SupportAccessResult {
        val grant = supportGrantRepository.findById(id) ?: return SupportAccessResult.NotFound
        if (!grant.isActiveAt(Instant.now(clock))) {
            return SupportAccessResult.GrantNotActive
        }

        val grantedByAdmin = adminRepository.findById(grant.grantedBy)
        return SupportAccessResult.Granted(SupportGrantView(grant, grantedByAdmin?.displayName ?: "Unknown"))
    }

    /**
     * Record activity for an active grant, sliding its expiry forward.
     * Writes are throttled to once per [ACTIVITY_THROTTLE] to avoid excessive updates.
     *
     * @return true if activity was recorded, false when the grant does not exist,
     * is not active, or the throttle window has not elapsed.
     */
    @Transactional
    fun recordActivity(
        id: SupportGrantId,
        now: Instant,
    ): Boolean {
        val grant = supportGrantRepository.findById(id) ?: return false
        if (!grant.isActiveAt(now)) {
            return false
        }

        val lastActivity = grant.lastActivity
        if (lastActivity != null && Duration.between(lastActivity, now) < ACTIVITY_THROTTLE) {
            return false
        }

        supportGrantRepository.save(grant.withActivity(now))
        return true
    }

    /**
     * Expire all active grants whose expiry has passed. Returns the number of grants expired.
     */
    @Transactional
    fun expireStaleGrants(): Int {
        val now = Instant.now(clock)
        val expired = supportGrantRepository.findExpiredActive(now)

        expired.forEach { grant ->
            val saved = supportGrantRepository.save(grant.expired(now))
            auditService.logSupportAccessExpired(saved.id.value, saved.podId)
        }

        return expired.size
    }

    companion object {
        private const val PURPOSE_MIN_LENGTH = 10
        private const val PURPOSE_MAX_LENGTH = 500
        val ACTIVITY_THROTTLE: Duration = Duration.ofSeconds(60)
    }
}
