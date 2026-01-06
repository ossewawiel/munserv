package com.munserv.photos.service

import com.munserv.photos.domain.PhotoId
import org.springframework.web.multipart.MultipartFile

/**
 * Interface for photo storage operations.
 * Allows switching between local storage and cloud storage (R2).
 */
interface PhotoStorageService {
    /**
     * Store a file and return URLs.
     *
     * @param file The multipart file to store
     * @param photoId The unique ID for this photo
     * @return UploadResult with URLs on success, error otherwise
     */
    fun store(
        file: MultipartFile,
        photoId: PhotoId,
    ): UploadResult

    /**
     * Delete a stored photo.
     *
     * @param photoId The ID of the photo to delete
     * @return true if deleted, false if not found
     */
    fun delete(photoId: PhotoId): Boolean

    /**
     * Generate the public URL for a filename.
     *
     * @param filename The filename
     * @return The public URL
     */
    fun generateUrl(filename: String): String

    /**
     * Get file extension from multipart file.
     *
     * @param file The multipart file
     * @return The file extension (without dot)
     */
    fun getExtension(file: MultipartFile): String
}
