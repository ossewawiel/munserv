package com.munserv.admin.service

import com.munserv.admin.domain.Admin
import com.munserv.admin.domain.AdminRole
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.PodId
import com.munserv.shared.types.SectorId
import com.munserv.shared.types.WardId

/**
 * Sealed interface representing the possible results of admin management operations.
 * Used instead of exceptions for business logic flow control.
 */
sealed interface AdminResult {
    /**
     * Operation completed successfully with an admin.
     */
    data class Success(val admin: Admin) : AdminResult

    /**
     * Admin creation succeeded, includes temporary password.
     */
    data class Created(
        val admin: Admin,
        val temporaryPassword: String,
    ) : AdminResult

    /**
     * List operation completed successfully.
     */
    data class ListSuccess(
        val admins: List<Admin>,
        val total: Int,
    ) : AdminResult

    /**
     * Deletion completed successfully.
     */
    data object Deleted : AdminResult

    /**
     * Admin was not found.
     */
    data class NotFound(val id: AdminId) : AdminResult

    /**
     * Email is already registered to another admin.
     */
    data class EmailAlreadyExists(val email: String) : AdminResult

    /**
     * Validation errors occurred.
     */
    data class ValidationError(val errors: List<String>) : AdminResult

    /**
     * Operation not authorized - insufficient permissions.
     */
    data class Unauthorized(val reason: String) : AdminResult

    /**
     * Cannot manage admin in a different sector (for sector-level admins).
     */
    data class CrossSectorOperation(
        val actorSectorId: SectorId,
        val targetSectorId: SectorId,
    ) : AdminResult

    /**
     * Cannot manage admin in a different ward (for ward-level admins).
     */
    data class CrossWardOperation(
        val actorWardId: WardId,
        val targetWardId: WardId?,
    ) : AdminResult

    /**
     * Cannot manage admin in a different pod (for pod-level admins).
     */
    data class CrossPodOperation(
        val actorPodId: PodId,
        val targetPodId: PodId?,
    ) : AdminResult

    /**
     * Cannot manage admin with equal or higher role.
     */
    data class InsufficientRoleToManage(
        val actorRole: AdminRole,
        val targetRole: AdminRole,
    ) : AdminResult

    /**
     * Cannot delete own account.
     */
    data object CannotDeleteSelf : AdminResult

    /**
     * Target admin is outside the actor's scope.
     */
    data class OutOfScope(val reason: String) : AdminResult
}
