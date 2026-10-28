package com.munserv.pod.service

import com.munserv.photos.domain.PhotoId
import com.munserv.photos.service.PhotoStorageService
import com.munserv.photos.service.PhotoValidationService
import com.munserv.photos.service.UploadResult
import com.munserv.photos.service.ValidationResult
import org.springframework.stereotype.Service
import org.springframework.web.multipart.MultipartFile

/**
 * Service for uploading a pod logo image.
 *
 * Reuses the same photo storage and validation mechanism as issue photos.
 * The generated [PhotoId] is only used as the storage key; nothing is
 * persisted to `issue_photos`. Persisting the returned URL on the pod is
 * the caller's responsibility via `PATCH /pod/settings`.
 */
@Service
class PodLogoService(
    private val photoStorageService: PhotoStorageService,
    private val photoValidationService: PhotoValidationService,
) {
    fun uploadLogo(file: MultipartFile): PodLogoResult {
        val validationResult = photoValidationService.validate(file)
        if (validationResult is ValidationResult.Invalid) {
            return PodLogoResult.ValidationError(validationResult.errors)
        }

        return when (val uploadResult = photoStorageService.store(file, PhotoId.generate())) {
            is UploadResult.Success -> PodLogoResult.Success(uploadResult.url)
            is UploadResult.ValidationError -> PodLogoResult.ValidationError(uploadResult.errors)
            is UploadResult.StorageError -> PodLogoResult.StorageError(uploadResult.message)
        }
    }
}
