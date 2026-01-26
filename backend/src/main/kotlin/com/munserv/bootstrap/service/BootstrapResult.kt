package com.munserv.bootstrap.service

import com.munserv.admin.domain.Admin

/**
 * Result type for bootstrap operations.
 * Uses sealed interface pattern for exhaustive handling.
 */
sealed interface BootstrapResult {
    /**
     * Pod Chief was successfully created.
     */
    data class PodChiefCreated(
        val admin: Admin,
        val temporaryPassword: String,
    ) : BootstrapResult

    /**
     * Pod already has a Pod Chief (cannot create another).
     */
    data object PodAlreadyBootstrapped : BootstrapResult

    /**
     * Caller is not authorized to perform this operation.
     */
    data object NotAuthorized : BootstrapResult

    /**
     * Input validation failed.
     */
    data class ValidationError(val errors: List<String>) : BootstrapResult

    /**
     * Email is already in use by another admin.
     */
    data class EmailAlreadyExists(val email: String) : BootstrapResult
}
