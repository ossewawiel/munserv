package com.munserv.photos.service

import com.munserv.issues.domain.IssueId
import com.munserv.issues.service.IssueResult
import com.munserv.issues.service.IssueService
import com.munserv.photos.domain.IssuePhoto
import com.munserv.photos.domain.PhotoId
import com.munserv.photos.repository.IssuePhotoRepository
import com.munserv.verification.service.VerificationService
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.multipart.MultipartFile
import java.time.Clock
import java.time.Instant

/**
 * Service for managing issue photos.
 * Coordinates between validation, storage, and persistence.
 */
@Service
class IssuePhotoService(
    private val repository: IssuePhotoRepository,
    private val storageService: PhotoStorageService,
    private val validationService: PhotoValidationService,
    private val issueService: IssueService,
    private val verificationService: VerificationService,
    private val clock: Clock,
) {
    private val logger = LoggerFactory.getLogger(IssuePhotoService::class.java)

    /**
     * Upload a photo for an issue.
     *
     * @param issueId The issue to attach the photo to
     * @param file The uploaded file
     * @param actor Who is uploading: the reporter, an admin or the verifying ground admin may
     * @return PhotoResult with the saved photo on success
     */
    @Transactional
    fun uploadPhoto(
        issueId: IssueId,
        file: MultipartFile,
        actor: PhotoActor,
    ): PhotoResult {
        val issue =
            (issueService.findById(issueId) as? IssueResult.Success)?.issue
                ?: return PhotoResult.IssueNotFound(issueId)

        val allowed =
            actor.isReporterOrAdminOf(issue) ||
                (actor is PhotoActor.Member && verificationService.mayVerify(issue.id, actor.id))
        if (!allowed) {
            return PhotoResult.Forbidden("Only the reporter, an admin or the verifying ground admin can add photos to this issue")
        }

        // Validate the file
        val validationResult = validationService.validate(file)
        if (validationResult is ValidationResult.Invalid) {
            return PhotoResult.ValidationError(validationResult.errors)
        }

        // Generate a new photo ID
        val photoId = PhotoId.generate()

        // Store the file
        val uploadResult = storageService.store(file, photoId)
        if (uploadResult !is UploadResult.Success) {
            return when (uploadResult) {
                is UploadResult.ValidationError -> PhotoResult.ValidationError(uploadResult.errors)
                is UploadResult.StorageError -> PhotoResult.StorageError(uploadResult.message)
                else -> PhotoResult.StorageError("Unknown error")
            }
        }

        // Get the next sort order
        val sortOrder = repository.getNextSortOrder(issueId)

        // Create and save the photo entity
        val photo =
            IssuePhoto(
                id = photoId,
                issueId = issueId,
                url = uploadResult.url,
                thumbnailUrl = uploadResult.thumbnailUrl,
                sortOrder = sortOrder,
                createdAt = Instant.now(clock),
            )

        val savedPhoto = repository.save(photo)
        logger.info("Uploaded photo ${savedPhoto.id} for issue $issueId")

        return PhotoResult.Success(savedPhoto)
    }

    /**
     * Get all photos for an issue, ordered by sort order.
     */
    fun getPhotosForIssue(issueId: IssueId): List<IssuePhoto> = repository.findByIssueId(issueId)

    /**
     * Get photo URLs for an issue.
     */
    fun getPhotoUrls(issueId: IssueId): List<String> = repository.findByIssueId(issueId).map { it.url }

    /**
     * Get the first photo's thumbnail URL for an issue.
     */
    fun getThumbnailUrl(issueId: IssueId): String? = repository.findByIssueId(issueId).firstOrNull()?.thumbnailUrl

    /**
     * Delete a photo. Only the reporter of its issue or an admin may delete.
     */
    @Transactional
    fun deletePhoto(
        photoId: PhotoId,
        actor: PhotoActor,
    ): PhotoResult {
        val photo = repository.findById(photoId) ?: return PhotoResult.NotFound(photoId)
        val issue =
            (issueService.findById(photo.issueId) as? IssueResult.Success)?.issue
                ?: return PhotoResult.NotFound(photoId)

        if (!actor.isReporterOrAdminOf(issue)) {
            return PhotoResult.Forbidden("Only the reporter or an admin can delete this photo")
        }

        storageService.delete(photoId)
        repository.deleteById(photoId)

        logger.info("Deleted photo $photoId")
        return PhotoResult.Success(photo)
    }

    /**
     * Delete all photos for an issue.
     *
     * @param issueId The issue whose photos to delete
     */
    @Transactional
    fun deletePhotosForIssue(issueId: IssueId) {
        val photos = repository.findByIssueId(issueId)
        photos.forEach { photo ->
            storageService.delete(photo.id)
        }
        repository.deleteByIssueId(issueId)
        logger.info("Deleted ${photos.size} photos for issue $issueId")
    }
}
