package com.munserv.support.api

import com.munserv.support.service.SupportGrantView
import io.swagger.v3.oas.annotations.media.Schema

/**
 * Request to grant temporary support access to the super user.
 */
@Schema(description = "Request to grant temporary support access")
data class GrantSupportAccessRequest(
    @field:Schema(
        description = "Role to grant the super user, strictly below pod_chief",
        example = "pod_admin",
        required = true,
    )
    val grantedRole: String,
    @field:Schema(
        description = "Stated purpose for the access, 10-500 characters",
        example = "Investigate duplicate issue reports in sector 3",
        required = true,
    )
    val purpose: String,
)

/**
 * A single support grant on the wire.
 */
@Schema(description = "A temporary super user support grant")
data class SupportGrantResponse(
    @field:Schema(description = "Support grant identifier")
    val id: String,
    @field:Schema(description = "Role granted to the super user")
    val grantedRole: String,
    @field:Schema(description = "Stated purpose for the access")
    val purpose: String,
    @field:Schema(description = "Status of the grant")
    val status: String,
    @field:Schema(description = "Admin ID of the pod chief who issued the grant")
    val grantedBy: String,
    @field:Schema(description = "Display name of the pod chief who issued the grant")
    val grantedByName: String,
    @field:Schema(description = "When the grant was issued")
    val grantedAt: String,
    @field:Schema(description = "When the grant expires absent further activity")
    val expiresAt: String,
    @field:Schema(description = "When the super user last acted under this grant")
    val lastActivity: String?,
    @field:Schema(description = "When the grant was revoked, if it was")
    val revokedAt: String?,
    @field:Schema(description = "When the grant expired, if it did")
    val expiredAt: String?,
)

/**
 * Paginated list of support grants.
 */
@Schema(description = "List of support grants")
data class SupportGrantListResponse(
    @field:Schema(description = "Support grants for the caller's pod")
    val items: List<SupportGrantResponse>,
    @field:Schema(description = "Total number of grants returned")
    val total: Int,
)

/**
 * Error response with a machine-readable code, used for conflict responses.
 */
@Schema(description = "Support access error response")
data class SupportAccessErrorResponse(
    @field:Schema(description = "Machine-readable error code", example = "active_grant_exists")
    val code: String,
    @field:Schema(description = "Human-readable error message")
    val message: String,
)

/**
 * Validation error response.
 */
@Schema(description = "Support access validation error response")
data class SupportAccessValidationErrorResponse(
    @field:Schema(description = "List of validation error messages")
    val messages: List<String>,
)

/**
 * Convert a [SupportGrantView] to its wire representation.
 */
fun SupportGrantView.toResponse(): SupportGrantResponse =
    SupportGrantResponse(
        id = grant.id.value.toString(),
        grantedRole = grant.grantedRole.toDbValue(),
        purpose = grant.purpose,
        status = grant.status.toDbValue(),
        grantedBy = grant.grantedBy.value.toString(),
        grantedByName = grantedByName,
        grantedAt = grant.grantedAt.toString(),
        expiresAt = grant.expiresAt.toString(),
        lastActivity = grant.lastActivity?.toString(),
        revokedAt = grant.revokedAt?.toString(),
        expiredAt = grant.expiredAt?.toString(),
    )
