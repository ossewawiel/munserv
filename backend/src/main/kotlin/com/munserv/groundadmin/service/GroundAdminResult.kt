package com.munserv.groundadmin.service

/**
 * Sealed interface representing the possible results of Ground Admin operations.
 * Used instead of exceptions for business logic flow control.
 */
sealed interface GroundAdminResult {
    /**
     * Operation completed successfully.
     */
    data class Success(
        val data: Any? = null,
    ) : GroundAdminResult

    /**
     * Resource was not found.
     */
    data class NotFound(
        val message: String,
    ) : GroundAdminResult

    /**
     * Operation conflicts with current state.
     */
    data class Conflict(
        val message: String,
    ) : GroundAdminResult

    /**
     * Operation not authorized.
     */
    data class Forbidden(
        val message: String,
    ) : GroundAdminResult

    /**
     * Validation errors occurred.
     */
    data class ValidationError(
        val errors: List<String>,
    ) : GroundAdminResult
}
