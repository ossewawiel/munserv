package com.munserv.verification.service

/**
 * Sealed interface representing the possible results of Verification operations.
 * Used instead of exceptions for business logic flow control.
 */
sealed interface VerificationResult {
    /**
     * Operation completed successfully.
     */
    data class Success(val data: Any? = null) : VerificationResult

    /**
     * Resource was not found.
     */
    data class NotFound(val message: String) : VerificationResult

    /**
     * Operation conflicts with current state.
     */
    data class Conflict(val message: String) : VerificationResult

    /**
     * Operation not authorized.
     */
    data class Forbidden(val message: String) : VerificationResult

    /**
     * Validation errors occurred.
     */
    data class ValidationError(val errors: List<String>) : VerificationResult
}
