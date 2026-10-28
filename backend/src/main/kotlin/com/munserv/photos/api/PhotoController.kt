package com.munserv.photos.api

import com.munserv.issues.domain.IssueId
import com.munserv.photos.domain.IssuePhoto
import com.munserv.photos.domain.PhotoId
import com.munserv.photos.service.IssuePhotoService
import com.munserv.photos.service.PhotoActor
import com.munserv.photos.service.PhotoResult
import com.munserv.shared.api.ErrorBody
import com.munserv.shared.api.ErrorCodes
import com.munserv.shared.api.ErrorResponse
import com.munserv.shared.api.forbiddenError
import com.munserv.shared.api.unauthorizedError
import com.munserv.shared.security.JwtAuthenticationFilter
import com.munserv.shared.types.MemberId
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.media.Content
import io.swagger.v3.oas.annotations.media.Schema
import io.swagger.v3.oas.annotations.responses.ApiResponse
import io.swagger.v3.oas.annotations.responses.ApiResponses
import io.swagger.v3.oas.annotations.security.SecurityRequirement
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.http.ResponseEntity
import org.springframework.security.core.Authentication
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
@Schema(description = "Photo metadata")
data class PhotoResponse(
    @Schema(description = "Photo UUID", example = "550e8400-e29b-41d4-a716-446655440001")
    val id: String,
    @Schema(description = "Full-size photo URL", example = "https://storage.example.com/photos/abc123.jpg")
    val url: String,
    @Schema(description = "Thumbnail URL", example = "https://storage.example.com/photos/abc123_thumb.jpg")
    val thumbnailUrl: String,
    @Schema(description = "Display order", example = "1")
    val sortOrder: Int,
    @Schema(description = "Upload timestamp", example = "2025-01-15T10:30:00Z")
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
@Tag(name = "Photos", description = "Photo upload and management for issues")
@SecurityRequirement(name = "bearerAuth")
class PhotoController(
    private val photoService: IssuePhotoService,
) {
    /**
     * POST /api/v1/issues/{issueId}/photos - Upload a photo for an issue.
     */
    @Operation(
        summary = "Upload photo for issue",
        description = "Upload a photo to attach to an issue. Supports JPEG, PNG, and WebP formats up to 5MB.",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "201",
                description = "Photo uploaded successfully",
                content = [Content(schema = Schema(implementation = PhotoResponse::class))],
            ),
            ApiResponse(responseCode = "400", description = "Invalid file format or size"),
            ApiResponse(responseCode = "401", description = "Unauthorized - invalid or missing token"),
            ApiResponse(responseCode = "403", description = "Not the reporter, an admin or the verifying ground admin"),
            ApiResponse(responseCode = "404", description = "Issue not found"),
            ApiResponse(responseCode = "500", description = "Storage error"),
        ],
    )
    @PostMapping(
        "/issues/{issueId}/photos",
        consumes = [MediaType.MULTIPART_FORM_DATA_VALUE],
    )
    fun uploadPhoto(
        @Parameter(description = "Issue UUID", required = true, example = "550e8400-e29b-41d4-a716-446655440001")
        @PathVariable issueId: String,
        @Parameter(description = "Photo file (JPEG, PNG, or WebP, max 5MB)", required = true)
        @RequestParam("file") file: MultipartFile,
        authentication: Authentication?,
    ): ResponseEntity<*> {
        val actor =
            authentication.toPhotoActor()
                ?: return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(unauthorizedError())
        val issueIdValue = IssueId(UUID.fromString(issueId))

        return when (val result = photoService.uploadPhoto(issueIdValue, file, actor)) {
            is PhotoResult.Success -> {
                ResponseEntity
                    .status(HttpStatus.CREATED)
                    .body(result.photo.toResponse())
            }

            is PhotoResult.ValidationError -> {
                ResponseEntity
                    .status(HttpStatus.BAD_REQUEST)
                    .body(ErrorResponse(ErrorBody(ErrorCodes.VALIDATION_ERROR, result.errors.joinToString(", "))))
            }

            is PhotoResult.StorageError -> {
                ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ErrorResponse(ErrorBody(ErrorCodes.INTERNAL_ERROR, result.message)))
            }

            is PhotoResult.NotFound -> {
                ResponseEntity
                    .status(HttpStatus.NOT_FOUND)
                    .body(ErrorResponse(ErrorBody(ErrorCodes.NOT_FOUND, "Photo not found")))
            }

            is PhotoResult.IssueNotFound -> {
                ResponseEntity
                    .status(HttpStatus.NOT_FOUND)
                    .body(ErrorResponse(ErrorBody(ErrorCodes.NOT_FOUND, "Issue not found")))
            }

            is PhotoResult.Forbidden -> {
                ResponseEntity
                    .status(HttpStatus.FORBIDDEN)
                    .body(forbiddenError(result.message))
            }
        }
    }

    /**
     * GET /api/v1/issues/{issueId}/photos - Get all photos for an issue.
     */
    @Operation(
        summary = "Get photos for issue",
        description = "Retrieve all photos attached to an issue",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Photos retrieved successfully",
                content = [Content(schema = Schema(implementation = Array<PhotoResponse>::class))],
            ),
            ApiResponse(responseCode = "401", description = "Unauthorized - invalid or missing token"),
        ],
    )
    @GetMapping("/issues/{issueId}/photos")
    fun getPhotosForIssue(
        @Parameter(description = "Issue UUID", required = true, example = "550e8400-e29b-41d4-a716-446655440001")
        @PathVariable issueId: String,
    ): ResponseEntity<List<PhotoResponse>> {
        val issueIdValue = IssueId(UUID.fromString(issueId))
        val photos = photoService.getPhotosForIssue(issueIdValue)
        return ResponseEntity.ok(photos.map { it.toResponse() })
    }

    /**
     * DELETE /api/v1/photos/{photoId} - Delete a photo.
     */
    @Operation(
        summary = "Delete photo",
        description = "Delete a photo by its ID",
    )
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "204", description = "Photo deleted successfully"),
            ApiResponse(responseCode = "401", description = "Unauthorized - invalid or missing token"),
            ApiResponse(responseCode = "403", description = "Not the reporter or an admin"),
            ApiResponse(responseCode = "404", description = "Photo not found"),
        ],
    )
    @DeleteMapping("/photos/{photoId}")
    fun deletePhoto(
        @Parameter(description = "Photo UUID", required = true, example = "550e8400-e29b-41d4-a716-446655440001")
        @PathVariable photoId: String,
        authentication: Authentication?,
    ): ResponseEntity<*> {
        val actor =
            authentication.toPhotoActor()
                ?: return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(unauthorizedError())
        val photoIdValue = PhotoId(UUID.fromString(photoId))

        return when (val result = photoService.deletePhoto(photoIdValue, actor)) {
            is PhotoResult.Success -> {
                ResponseEntity.noContent().build<Unit>()
            }

            is PhotoResult.NotFound, is PhotoResult.IssueNotFound -> {
                ResponseEntity
                    .status(HttpStatus.NOT_FOUND)
                    .body(ErrorResponse(ErrorBody(ErrorCodes.NOT_FOUND, "Photo not found")))
            }

            is PhotoResult.Forbidden -> {
                ResponseEntity
                    .status(HttpStatus.FORBIDDEN)
                    .body(forbiddenError(result.message))
            }

            is PhotoResult.ValidationError -> {
                ResponseEntity
                    .status(HttpStatus.BAD_REQUEST)
                    .body(ErrorResponse(ErrorBody(ErrorCodes.VALIDATION_ERROR, result.errors.joinToString(", "))))
            }

            is PhotoResult.StorageError -> {
                ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ErrorResponse(ErrorBody(ErrorCodes.INTERNAL_ERROR, result.message)))
            }
        }
    }
}

private val ADMIN_AUTHORITIES = setOf("ROLE_ADMIN", JwtAuthenticationFilter.SUPPORT_GRANT_AUTHORITY)

/**
 * Map the request's authentication to a photo actor; null when unauthenticated or the subject is not a UUID.
 */
private fun Authentication?.toPhotoActor(): PhotoActor? {
    val auth = this ?: return null
    if (auth.authorities.any { it.authority in ADMIN_AUTHORITIES }) return PhotoActor.Admin
    val subject = auth.principal as? String ?: return null
    return runCatching { MemberId.fromString(subject) }.getOrNull()?.let { PhotoActor.Member(it) }
}
