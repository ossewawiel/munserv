package com.munserv.photos.config

import com.munserv.photos.service.LocalPhotoStorageService
import com.munserv.photos.service.PhotoStorageService
import com.munserv.photos.service.PhotoValidationService
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer
import java.nio.file.Paths

/**
 * Configuration for photo storage.
 * Configures storage service based on application.yml settings.
 */
@Configuration
class StorageConfig(
    @Value("\${storage.type:local}")
    private val storageType: String,
    @Value("\${storage.local.upload-dir:./uploads}")
    private val uploadDir: String,
    @Value("\${server.port:8080}")
    private val serverPort: Int,
) : WebMvcConfigurer {
    private val logger = LoggerFactory.getLogger(StorageConfig::class.java)

    /**
     * Create the photo storage service bean.
     * Currently only supports local storage.
     * R2 storage can be added in the future.
     */
    @Bean
    fun photoStorageService(): PhotoStorageService {
        val baseUrl = "http://localhost:$serverPort"

        return when (storageType) {
            "local" -> {
                logger.info("Configuring local photo storage at $uploadDir")
                LocalPhotoStorageService(
                    uploadDir = uploadDir,
                    baseUrl = baseUrl,
                )
            }
            "r2" -> {
                logger.warn("R2 storage not yet implemented, falling back to local")
                LocalPhotoStorageService(
                    uploadDir = uploadDir,
                    baseUrl = baseUrl,
                )
            }
            else -> {
                logger.warn("Unknown storage type '$storageType', using local")
                LocalPhotoStorageService(
                    uploadDir = uploadDir,
                    baseUrl = baseUrl,
                )
            }
        }
    }

    /**
     * Create the photo validation service bean.
     */
    @Bean
    fun photoValidationService(): PhotoValidationService = PhotoValidationService()

    /**
     * Configure static resource handler to serve uploaded files.
     */
    override fun addResourceHandlers(registry: ResourceHandlerRegistry) {
        val absolutePath = Paths.get(uploadDir).toAbsolutePath().toString()
        logger.info("Serving uploads from: $absolutePath")

        registry
            .addResourceHandler("/uploads/**")
            .addResourceLocations("file:$absolutePath/")
    }
}
