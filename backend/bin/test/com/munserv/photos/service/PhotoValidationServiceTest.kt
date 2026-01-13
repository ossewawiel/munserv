package com.munserv.photos.service

import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.springframework.mock.web.MockMultipartFile

/**
 * TDD Tests for PhotoValidationService.
 * These tests are written BEFORE the implementation.
 */
class PhotoValidationServiceTest {
    private lateinit var service: PhotoValidationService

    companion object {
        private const val MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024L // 5MB
    }

    @BeforeEach
    fun setUp() {
        service =
            PhotoValidationService(
                maxFileSizeBytes = MAX_FILE_SIZE_BYTES,
                allowedContentTypes = setOf("image/jpeg", "image/png", "image/webp"),
            )
    }

    private fun createMockFile(
        name: String = "test.jpg",
        contentType: String = "image/jpeg",
        size: Int = 1024,
    ): MockMultipartFile {
        val content = ByteArray(size) { 0 }
        return MockMultipartFile("file", name, contentType, content)
    }

    @Nested
    inner class ValidateFileType {
        @Test
        fun `should accept jpeg files`() {
            val file = createMockFile(name = "photo.jpg", contentType = "image/jpeg")

            val result = service.validate(file)

            result.shouldBeInstanceOf<ValidationResult.Valid>()
        }

        @Test
        fun `should accept png files`() {
            val file = createMockFile(name = "photo.png", contentType = "image/png")

            val result = service.validate(file)

            result.shouldBeInstanceOf<ValidationResult.Valid>()
        }

        @Test
        fun `should accept webp files`() {
            val file = createMockFile(name = "photo.webp", contentType = "image/webp")

            val result = service.validate(file)

            result.shouldBeInstanceOf<ValidationResult.Valid>()
        }

        @Test
        fun `should reject gif files`() {
            val file = createMockFile(name = "photo.gif", contentType = "image/gif")

            val result = service.validate(file)

            result.shouldBeInstanceOf<ValidationResult.Invalid>()
            val invalid = result as ValidationResult.Invalid
            invalid.errors.any { it.contains("content type") } shouldBe true
        }

        @Test
        fun `should reject pdf files`() {
            val file = createMockFile(name = "document.pdf", contentType = "application/pdf")

            val result = service.validate(file)

            result.shouldBeInstanceOf<ValidationResult.Invalid>()
        }

        @Test
        fun `should reject files with no content type`() {
            val content = ByteArray(1024) { 0 }
            val file = MockMultipartFile("file", "test.jpg", null, content)

            val result = service.validate(file)

            result.shouldBeInstanceOf<ValidationResult.Invalid>()
        }
    }

    @Nested
    inner class ValidateFileSize {
        @Test
        fun `should accept file under max size`() {
            val file = createMockFile(size = 1024) // 1KB

            val result = service.validate(file)

            result.shouldBeInstanceOf<ValidationResult.Valid>()
        }

        @Test
        fun `should accept file exactly at max size`() {
            val file = createMockFile(size = MAX_FILE_SIZE_BYTES.toInt())

            val result = service.validate(file)

            result.shouldBeInstanceOf<ValidationResult.Valid>()
        }

        @Test
        fun `should reject file over max size`() {
            val file = createMockFile(size = (MAX_FILE_SIZE_BYTES + 1).toInt())

            val result = service.validate(file)

            result.shouldBeInstanceOf<ValidationResult.Invalid>()
            val invalid = result as ValidationResult.Invalid
            invalid.errors.any { it.contains("size") } shouldBe true
        }
    }

    @Nested
    inner class ValidateEmptyFile {
        @Test
        fun `should reject empty file`() {
            val file = createMockFile(size = 0)

            val result = service.validate(file)

            result.shouldBeInstanceOf<ValidationResult.Invalid>()
            val invalid = result as ValidationResult.Invalid
            invalid.errors.any { it.contains("empty") } shouldBe true
        }
    }

    @Nested
    inner class MultipleValidationErrors {
        @Test
        fun `should return all validation errors`() {
            val content = ByteArray((MAX_FILE_SIZE_BYTES + 1).toInt()) { 0 }
            val file = MockMultipartFile("file", "test.gif", "image/gif", content)

            val result = service.validate(file)

            result.shouldBeInstanceOf<ValidationResult.Invalid>()
            val invalid = result as ValidationResult.Invalid
            invalid.errors.size shouldBe 2 // wrong type + too large
        }
    }
}
