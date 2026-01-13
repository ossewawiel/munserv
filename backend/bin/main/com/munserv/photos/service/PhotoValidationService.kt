package com.munserv.photos.service

import org.springframework.stereotype.Service
import org.springframework.web.multipart.MultipartFile

/**
 * Result type for photo validation.
 */
sealed interface ValidationResult {
    data object Valid : ValidationResult

    data class Invalid(val errors: List<String>) : ValidationResult
}

/**
 * Service for validating photo uploads.
 * Checks file type and size constraints.
 */
@Service
class PhotoValidationService(
    private val maxFileSizeBytes: Long = DEFAULT_MAX_FILE_SIZE,
    private val allowedContentTypes: Set<String> = DEFAULT_ALLOWED_TYPES,
) {
    companion object {
        const val DEFAULT_MAX_FILE_SIZE = 5L * 1024 * 1024 // 5MB
        val DEFAULT_ALLOWED_TYPES = setOf("image/jpeg", "image/png", "image/webp")
    }

    /**
     * Validate a multipart file for upload.
     *
     * @param file The file to validate
     * @return ValidationResult.Valid if valid, ValidationResult.Invalid with errors otherwise
     */
    fun validate(file: MultipartFile): ValidationResult {
        val errors = mutableListOf<String>()

        // Check empty file
        if (file.isEmpty || file.size == 0L) {
            errors.add("File is empty")
        }

        // Check content type
        val contentType = file.contentType
        if (contentType == null || contentType !in allowedContentTypes) {
            errors.add(
                "Invalid content type: $contentType. Allowed types: ${allowedContentTypes.joinToString(", ")}",
            )
        }

        // Check file size
        if (file.size > maxFileSizeBytes) {
            val maxSizeMb = maxFileSizeBytes / (1024 * 1024)
            val fileSizeMb = file.size / (1024.0 * 1024.0)
            errors.add(
                "File size exceeds maximum allowed (${String.format("%.2f", fileSizeMb)}MB > ${maxSizeMb}MB)",
            )
        }

        return if (errors.isEmpty()) {
            ValidationResult.Valid
        } else {
            ValidationResult.Invalid(errors)
        }
    }
}
