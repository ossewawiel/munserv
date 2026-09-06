package com.munserv.pod.service

import com.munserv.photos.domain.PhotoId
import com.munserv.photos.service.PhotoStorageService
import com.munserv.photos.service.PhotoValidationService
import com.munserv.photos.service.UploadResult
import com.munserv.photos.service.ValidationResult
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.mock.web.MockMultipartFile

/**
 * TDD tests for PodLogoService, written before the implementation.
 */
class PodLogoServiceTest {
    private val storage: PhotoStorageService = mockk()
    private val validation: PhotoValidationService = mockk()
    private lateinit var service: PodLogoService

    @BeforeEach
    fun setUp() {
        service = PodLogoService(storage, validation)
    }

    private fun createMockFile(
        name: String = "logo.png",
        contentType: String = "image/png",
        size: Int = 1024,
    ): MockMultipartFile {
        val content = ByteArray(size) { 0 }
        return MockMultipartFile("file", name, contentType, content)
    }

    @Test
    fun `should return the stored url when the file is valid`() {
        val file = createMockFile()
        every { validation.validate(file) } returns ValidationResult.Valid
        every { storage.store(file, any()) } returns
            UploadResult.Success(
                url = "http://localhost:8080/uploads/logo.png",
                thumbnailUrl = "http://localhost:8080/uploads/logo-thumb.png",
            )

        val result = service.uploadLogo(file)

        result.shouldBeInstanceOf<PodLogoResult.Success>()
        (result as PodLogoResult.Success).logoUrl shouldBe "http://localhost:8080/uploads/logo.png"
        verify { storage.store(file, any<PhotoId>()) }
    }

    @Test
    fun `should return a validation error when the file is not an image`() {
        val file = createMockFile(contentType = "text/plain")
        every { validation.validate(file) } returns
            ValidationResult.Invalid(listOf("Invalid content type: text/plain"))

        val result = service.uploadLogo(file)

        result.shouldBeInstanceOf<PodLogoResult.ValidationError>()
        (result as PodLogoResult.ValidationError).errors shouldBe listOf("Invalid content type: text/plain")
        verify(exactly = 0) { storage.store(any(), any()) }
    }

    @Test
    fun `should return a storage error when the file cannot be written`() {
        val file = createMockFile()
        every { validation.validate(file) } returns ValidationResult.Valid
        every { storage.store(file, any()) } returns UploadResult.StorageError("Disk full")

        val result = service.uploadLogo(file)

        result.shouldBeInstanceOf<PodLogoResult.StorageError>()
        (result as PodLogoResult.StorageError).message shouldBe "Disk full"
    }
}
