package com.munserv.pod.service

/**
 * Sealed result type for pod logo upload operations.
 * Kept separate from PodResult because PodController `when`s over PodResult
 * exhaustively for every other endpoint.
 */
sealed interface PodLogoResult {
    data class Success(
        val logoUrl: String,
    ) : PodLogoResult

    data class ValidationError(
        val errors: List<String>,
    ) : PodLogoResult

    data class StorageError(
        val message: String,
    ) : PodLogoResult
}
