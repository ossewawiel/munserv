package com.munserv.photos.service

import com.munserv.issues.domain.IssueId
import com.munserv.photos.domain.IssuePhoto
import com.munserv.photos.domain.PhotoId

/**
 * Sealed result type for photo operations.
 * Following the same pattern as IssueResult.
 */
sealed interface PhotoResult {
    data class Success(
        val photo: IssuePhoto,
    ) : PhotoResult

    data class NotFound(
        val id: PhotoId,
    ) : PhotoResult

    data class ValidationError(
        val errors: List<String>,
    ) : PhotoResult

    data class StorageError(
        val message: String,
    ) : PhotoResult

    data class Forbidden(
        val message: String,
    ) : PhotoResult

    data class IssueNotFound(
        val id: IssueId,
    ) : PhotoResult
}

/**
 * Result for upload operations.
 */
sealed interface UploadResult {
    data class Success(
        val url: String,
        val thumbnailUrl: String,
    ) : UploadResult

    data class ValidationError(
        val errors: List<String>,
    ) : UploadResult

    data class StorageError(
        val message: String,
    ) : UploadResult
}
