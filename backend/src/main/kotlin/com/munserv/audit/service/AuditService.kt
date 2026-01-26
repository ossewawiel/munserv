package com.munserv.audit.service

import com.munserv.audit.domain.AuditAction
import com.munserv.audit.domain.AuditActorType
import com.munserv.audit.domain.AuditLog
import com.munserv.audit.repository.AuditLogRepository
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.PodId
import org.springframework.stereotype.Service
import java.time.Clock
import java.time.Instant
import java.util.UUID

/**
 * Service for recording audit log entries.
 *
 * Provides methods for logging super user and pod chief actions
 * for security traceability and compliance.
 */
@Service
class AuditService(
    private val repository: AuditLogRepository,
    private val clock: Clock = Clock.systemUTC(),
) {
    /**
     * Log a super user login attempt.
     *
     * @param email Super user's email address
     * @param success Whether the login was successful
     * @param podId The pod being accessed
     * @param ipAddress Client IP address (optional)
     * @param userAgent Client user agent (optional)
     */
    fun logSuperUserLoginAttempt(
        email: String,
        success: Boolean,
        podId: PodId,
        ipAddress: String? = null,
        userAgent: String? = null,
    ) {
        val action =
            if (success) {
                AuditAction.SUPER_USER_LOGIN_SUCCESS
            } else {
                AuditAction.SUPER_USER_LOGIN_FAILURE
            }

        val log =
            AuditLog(
                id = UUID.randomUUID(),
                podId = podId,
                action = action,
                actorEmail = email,
                actorType = AuditActorType.SUPER_USER,
                targetType = null,
                targetId = null,
                details = null,
                ipAddress = ipAddress,
                userAgent = userAgent,
                createdAt = Instant.now(clock),
            )

        repository.save(log)
    }

    /**
     * Log Pod Chief creation.
     *
     * @param superUserEmail Email of the super user who created the Pod Chief
     * @param adminId ID of the created Pod Chief admin
     * @param adminEmail Email of the created Pod Chief
     * @param podId The pod where Pod Chief was created
     * @param ipAddress Client IP address (optional)
     * @param userAgent Client user agent (optional)
     */
    fun logPodChiefCreated(
        superUserEmail: String,
        adminId: AdminId,
        adminEmail: String,
        podId: PodId,
        ipAddress: String? = null,
        userAgent: String? = null,
    ) {
        val log =
            AuditLog(
                id = UUID.randomUUID(),
                podId = podId,
                action = AuditAction.POD_CHIEF_CREATED,
                actorEmail = superUserEmail,
                actorType = AuditActorType.SUPER_USER,
                targetType = "ADMIN",
                targetId = adminId.value,
                details =
                    mapOf(
                        "adminEmail" to adminEmail,
                        "role" to "POD_CHIEF",
                    ),
                ipAddress = ipAddress,
                userAgent = userAgent,
                createdAt = Instant.now(clock),
            )

        repository.save(log)
    }

    /**
     * Log support access granted (for B8).
     *
     * @param podChiefEmail Email of the Pod Chief granting access
     * @param grantId ID of the support access grant
     * @param grantedRole Role granted to the support user
     * @param purpose Stated purpose for the access
     * @param podId The pod where access was granted
     */
    fun logSupportAccessGranted(
        podChiefEmail: String,
        grantId: UUID,
        grantedRole: String,
        purpose: String,
        podId: PodId,
    ) {
        val log =
            AuditLog(
                id = UUID.randomUUID(),
                podId = podId,
                action = AuditAction.SUPPORT_ACCESS_GRANTED,
                actorEmail = podChiefEmail,
                actorType = AuditActorType.POD_CHIEF,
                targetType = "SUPPORT_GRANT",
                targetId = grantId,
                details =
                    mapOf(
                        "grantedRole" to grantedRole,
                        "purpose" to purpose,
                    ),
                ipAddress = null,
                userAgent = null,
                createdAt = Instant.now(clock),
            )

        repository.save(log)
    }

    /**
     * Log support access revoked (for B8).
     *
     * @param revokerEmail Email of the user revoking access
     * @param actorType Type of actor revoking (POD_CHIEF or SYSTEM)
     * @param grantId ID of the support access grant being revoked
     * @param reason Reason for revocation (optional)
     * @param podId The pod where access was revoked
     */
    fun logSupportAccessRevoked(
        revokerEmail: String,
        actorType: AuditActorType,
        grantId: UUID,
        reason: String?,
        podId: PodId,
    ) {
        val log =
            AuditLog(
                id = UUID.randomUUID(),
                podId = podId,
                action = AuditAction.SUPPORT_ACCESS_REVOKED,
                actorEmail = revokerEmail,
                actorType = actorType,
                targetType = "SUPPORT_GRANT",
                targetId = grantId,
                details = reason?.let { mapOf("reason" to it) },
                ipAddress = null,
                userAgent = null,
                createdAt = Instant.now(clock),
            )

        repository.save(log)
    }

    /**
     * Log support access login (for B8).
     *
     * @param superUserEmail Email of the super user logging in via support access
     * @param grantId ID of the support access grant being used
     * @param podId The pod being accessed
     * @param ipAddress Client IP address (optional)
     * @param userAgent Client user agent (optional)
     */
    fun logSupportAccessLogin(
        superUserEmail: String,
        grantId: UUID,
        podId: PodId,
        ipAddress: String? = null,
        userAgent: String? = null,
    ) {
        val log =
            AuditLog(
                id = UUID.randomUUID(),
                podId = podId,
                action = AuditAction.SUPPORT_ACCESS_LOGIN,
                actorEmail = superUserEmail,
                actorType = AuditActorType.SUPER_USER,
                targetType = "SUPPORT_GRANT",
                targetId = grantId,
                details = null,
                ipAddress = ipAddress,
                userAgent = userAgent,
                createdAt = Instant.now(clock),
            )

        repository.save(log)
    }
}
