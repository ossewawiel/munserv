package com.munserv.photos.service

import com.munserv.photos.domain.PhotoId
import org.slf4j.LoggerFactory
import org.springframework.web.multipart.MultipartFile
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import java.nio.file.StandardCopyOption

/**
 * Local filesystem implementation of PhotoStorageService.
 * Stores photos in a local directory for development.
 */
class LocalPhotoStorageService(
    private val uploadDir: String,
    private val baseUrl: String,
) : PhotoStorageService {
    private val logger = LoggerFactory.getLogger(LocalPhotoStorageService::class.java)

    companion object {
        private const val UPLOADS_PATH = "/uploads"
        private val CONTENT_TYPE_TO_EXT =
            mapOf(
                "image/jpeg" to "jpg",
                "image/png" to "png",
                "image/webp" to "webp",
            )
    }

    init {
        // Ensure upload directory exists
        val path = Paths.get(uploadDir)
        if (!Files.exists(path)) {
            Files.createDirectories(path)
            logger.info("Created upload directory: $uploadDir")
        }
    }

    override fun store(
        file: MultipartFile,
        photoId: PhotoId,
    ): UploadResult =
        try {
            val extension = getExtension(file)
            val filename = "${photoId.value}.$extension"
            val targetPath = Paths.get(uploadDir, filename)

            // Store the file
            file.inputStream.use { input ->
                Files.copy(input, targetPath, StandardCopyOption.REPLACE_EXISTING)
            }

            val url = generateUrl(filename)
            val thumbnailUrl = generateThumbnailUrl(filename)

            logger.debug("Stored photo: $filename at $targetPath")

            UploadResult.Success(url = url, thumbnailUrl = thumbnailUrl)
        } catch (e: Exception) {
            logger.error("Failed to store photo: ${e.message}", e)
            UploadResult.StorageError("Failed to store photo: ${e.message}")
        }

    override fun delete(photoId: PhotoId): Boolean {
        return try {
            // Find the file matching this photoId
            val uploadPath = Paths.get(uploadDir)
            val matchingFiles =
                Files
                    .walk(uploadPath, 1)
                    .filter { Files.isRegularFile(it) }
                    .filter { it.fileName.toString().startsWith(photoId.value.toString()) }
                    .toList()

            if (matchingFiles.isEmpty()) {
                return false
            }

            matchingFiles.forEach { file ->
                Files.deleteIfExists(file)
                logger.debug("Deleted photo: ${file.fileName}")
            }

            true
        } catch (e: Exception) {
            logger.error("Failed to delete photo ${photoId.value}: ${e.message}", e)
            false
        }
    }

    override fun generateUrl(filename: String): String = "$baseUrl$UPLOADS_PATH/$filename"

    private fun generateThumbnailUrl(filename: String): String {
        val dotIndex = filename.lastIndexOf('.')
        return if (dotIndex > 0) {
            val name = filename.substring(0, dotIndex)
            val ext = filename.substring(dotIndex)
            "$baseUrl$UPLOADS_PATH/$name-thumb$ext"
        } else {
            "$baseUrl$UPLOADS_PATH/$filename-thumb"
        }
    }

    override fun getExtension(file: MultipartFile): String {
        // Try to get from original filename
        val originalFilename = file.originalFilename
        if (originalFilename != null && originalFilename.contains('.')) {
            val ext = originalFilename.substringAfterLast('.').lowercase()
            if (ext.isNotEmpty()) {
                return ext
            }
        }

        // Fall back to content type
        val contentType = file.contentType
        if (contentType != null) {
            val ext = CONTENT_TYPE_TO_EXT[contentType]
            if (ext != null) {
                return ext
            }
        }

        // Default to jpg
        return "jpg"
    }

    /**
     * Get the full path to the uploads directory.
     */
    fun getUploadPath(): Path = Paths.get(uploadDir)
}
