package com.munserv.pod.service

import com.munserv.shared.types.PodId

/**
 * Sealed interface representing the possible results of pod operations.
 * Used instead of exceptions for business logic flow control.
 */
sealed interface PodResult<out T> {
    /**
     * Operation completed successfully.
     */
    data class Success<T>(
        val data: T,
    ) : PodResult<T>

    /**
     * Pod was not found.
     */
    data class NotFound(
        val podId: PodId,
    ) : PodResult<Nothing>

    /**
     * Validation errors occurred.
     */
    data class ValidationError(
        val errors: List<String>,
    ) : PodResult<Nothing>

    /**
     * User is not authorized to perform the operation.
     */
    data class Unauthorized(
        val reason: String,
    ) : PodResult<Nothing>
}
