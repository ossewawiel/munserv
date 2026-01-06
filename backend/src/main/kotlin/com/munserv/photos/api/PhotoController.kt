package com.munserv.photos.api

import com.munserv.issues.api.ErrorDetail
import com.munserv.issues.api.ErrorResponse
import com.munserv.issues.domain.IssueId
import com.munserv.photos.domain.IssuePhoto
import com.munserv.photos.domain.PhotoId
import com.munserv.photos.service.IssuePhotoService
import com.munserv.photos.service.PhotoResult
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.multipart.MultipartFile
import java.util.UUID

/**
 * Response DTO for a photo.
 */
data class PhotoResponse(
    val id: String,
    val url: String,
    val thumbnailUrl: String,
    val sortOrder: Int,
    val createdAt: String,
)

/**
 * Convert domain to response.
 */
fun IssuePhoto.toResponse() =
    PhotoResponse(
        id = id.value.toString(),
        url = url,
        thumbnailUrl = thumbnailUrl,
        sortOrder = sortOrder,
        createdAt = createdAt.toString(),
    )

/**
 * REST controller for photo endpoints.
 */
@RestController
@RequestMapping("/api/v1")
class PhotoController(
    private val photoService: IssuePhotoService,
) {
    /**
     * POST /api/v1/issues/{issueId}/photos - Upload a photo for an issue.
     */
    @PostMapping(
        "/issues/{issueId}/photos",
        consumes = [MediaType.MULTIPART_FORM_DATA_VALUE],
    )
    fun uploadPhoto(
        @PathVariable issueId: String,
        @RequestParam("file") file: MultipartFile,
    ): ResponseEntity<*> {
        val issueIdValue = IssueId(UUID.fromString(issueId))

        return when (val result = photoService.uploadPhoto(issueIdValue, file)) {
            is PhotoResult.Success ->
                ResponseEntity.status(HttpStatus.CREATED)
                    .body(result.photo.toResponse())
            is PhotoResult.ValidationError ->
                ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ErrorResponse(ErrorDetail("VALIDATION_ERROR", result.errors.joinToString(", "))))
            is PhotoResult.StorageError ->
                ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ErrorResponse(ErrorDetail("STORAGE_ERROR", result.message)))
            is PhotoResult.NotFound ->
                ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ErrorResponse(ErrorDetail("NOT_FOUND", "Photo not found")))
        }
    }

    /**
     * GET /api/v1/issues/{issueId}/photos - Get all photos for an issue.
     */
    @GetMapping("/issues/{issueId}/photos")
    fun getPhotosForIssue(
        @PathVariable issueId: String,
    ): ResponseEntity<List<PhotoResponse>> {
        val issueIdValue = IssueId(UUID.fromString(issueId))
        val photos = photoService.getPhotosForIssue(issueIdValue)
        return ResponseEntity.ok(photos.map { it.toResponse() })
    }

    /**
     * DELETE /api/v1/photos/{photoId} - Delete a photo.
     */
    @DeleteMapping("/photos/{photoId}")
    fun deletePhoto(
        @PathVariable photoId: String,
    ): ResponseEntity<*> {
        val photoIdValue = PhotoId(UUID.fromString(photoId))
        val deleted = photoService.deletePhoto(photoIdValue)

        return if (deleted) {
            ResponseEntity.noContent().build<Unit>()
        } else {
            ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ErrorResponse(ErrorDetail("NOT_FOUND", "Photo not found")))
        }
    }
}
