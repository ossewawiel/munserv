package com.munserv.photos.service

import com.munserv.photos.domain.PhotoId
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.string.shouldEndWith
import io.kotest.matchers.types.shouldBeInstanceOf
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.io.TempDir
import org.springframework.mock.web.MockMultipartFile
import java.nio.file.Files
import java.nio.file.Path

/**
 * TDD Tests for LocalPhotoStorageService.
 * These tests are written BEFORE the implementation.
 */
class LocalPhotoStorageServiceTest {
    @TempDir
    lateinit var tempDir: Path

    private lateinit var service: LocalPhotoStorageService
    private val baseUrl = "http://localhost:8080"

    @BeforeEach
    fun setUp() {
        service =
            LocalPhotoStorageService(
                uploadDir = tempDir.toString(),
                baseUrl = baseUrl,
            )
    }

    @AfterEach
    fun tearDown() {
        // Cleanup handled by @TempDir
    }

    private fun createMockFile(
        name: String = "test.jpg",
        contentType: String = "image/jpeg",
        content: ByteArray = "test image content".toByteArray(),
    ): MockMultipartFile = MockMultipartFile("file", name, contentType, content)

    @Nested
    inner class StoreFile {
        @Test
        fun `should store file and return success with URL`() {
            val file = createMockFile()
            val photoId = PhotoId.generate()

            val result = service.store(file, photoId)

            result.shouldBeInstanceOf<UploadResult.Success>()
            val success = result as UploadResult.Success
            success.url shouldContain "/uploads/"
            success.url shouldContain photoId.value.toString()
        }

        @Test
        fun `should create file on disk`() {
            val file = createMockFile(content = "test content".toByteArray())
            val photoId = PhotoId.generate()

            service.store(file, photoId)

            // Verify file exists on disk
            val storedFiles =
                Files
                    .walk(tempDir)
                    .filter { Files.isRegularFile(it) }
                    .toList()
            storedFiles.size shouldBe 1
        }

        @Test
        fun `should preserve original file extension`() {
            val file = createMockFile(name = "photo.png", contentType = "image/png")
            val photoId = PhotoId.generate()

            val result = service.store(file, photoId)

            result.shouldBeInstanceOf<UploadResult.Success>()
            (result as UploadResult.Success).url shouldEndWith ".png"
        }

        @Test
        fun `should generate thumbnail URL`() {
            val file = createMockFile()
            val photoId = PhotoId.generate()

            val result = service.store(file, photoId)

            result.shouldBeInstanceOf<UploadResult.Success>()
            val success = result as UploadResult.Success
            success.thumbnailUrl shouldContain "-thumb"
        }

        @Test
        fun `should use photoId in filename`() {
            val file = createMockFile()
            val photoId = PhotoId.generate()

            val result = service.store(file, photoId)

            result.shouldBeInstanceOf<UploadResult.Success>()
            (result as UploadResult.Success).url shouldContain photoId.value.toString()
        }
    }

    @Nested
    inner class DeleteFile {
        @Test
        fun `should delete existing file`() {
            val file = createMockFile()
            val photoId = PhotoId.generate()
            service.store(file, photoId)

            val deleted = service.delete(photoId)

            deleted shouldBe true
            // Verify file is deleted from disk
            val storedFiles =
                Files
                    .walk(tempDir)
                    .filter { Files.isRegularFile(it) }
                    .filter { it.fileName.toString().contains(photoId.value.toString()) }
                    .toList()
            storedFiles.size shouldBe 0
        }

        @Test
        fun `should return false when file does not exist`() {
            val photoId = PhotoId.generate()

            val deleted = service.delete(photoId)

            deleted shouldBe false
        }
    }

    @Nested
    inner class GenerateUrl {
        @Test
        fun `should generate URL with base URL and upload path`() {
            val filename = "abc123.jpg"

            val url = service.generateUrl(filename)

            url shouldBe "$baseUrl/uploads/$filename"
        }
    }

    @Nested
    inner class GetExtension {
        @Test
        fun `should extract jpg extension`() {
            val file = createMockFile(name = "photo.jpg")

            val ext = service.getExtension(file)

            ext shouldBe "jpg"
        }

        @Test
        fun `should extract png extension`() {
            val file = createMockFile(name = "photo.png", contentType = "image/png")

            val ext = service.getExtension(file)

            ext shouldBe "png"
        }

        @Test
        fun `should fall back to content type for extension`() {
            val file = MockMultipartFile("file", null, "image/jpeg", "content".toByteArray())

            val ext = service.getExtension(file)

            ext shouldBe "jpg"
        }

        @Test
        fun `should default to jpg when no extension info`() {
            val file = MockMultipartFile("file", null, null, "content".toByteArray())

            val ext = service.getExtension(file)

            ext shouldBe "jpg"
        }
    }
}
