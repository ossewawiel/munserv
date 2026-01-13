package com.munserv.photos.service

import com.munserv.issues.domain.IssueId
import com.munserv.photos.domain.IssuePhoto
import com.munserv.photos.domain.PhotoId
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import java.time.Instant
import java.util.UUID

/**
 * Unit tests for PhotoResult and UploadResult sealed interfaces.
 */
class PhotoResultTest {
    private val testPhoto =
        IssuePhoto(
            id = PhotoId.generate(),
            issueId = IssueId(UUID.randomUUID()),
            url = "http://localhost:8080/uploads/test.jpg",
            thumbnailUrl = "http://localhost:8080/uploads/test-thumb.jpg",
            sortOrder = 1,
            createdAt = Instant.now(),
        )

    @Nested
    inner class PhotoResultTypes {
        @Test
        fun `Success should contain photo`() {
            val result: PhotoResult = PhotoResult.Success(testPhoto)

            result.shouldBeInstanceOf<PhotoResult.Success>()
            (result as PhotoResult.Success).photo shouldBe testPhoto
        }

        @Test
        fun `NotFound should contain photo id`() {
            val photoId = PhotoId.generate()
            val result: PhotoResult = PhotoResult.NotFound(photoId)

            result.shouldBeInstanceOf<PhotoResult.NotFound>()
            (result as PhotoResult.NotFound).id shouldBe photoId
        }

        @Test
        fun `ValidationError should contain list of errors`() {
            val errors = listOf("Invalid format", "File too large")
            val result: PhotoResult = PhotoResult.ValidationError(errors)

            result.shouldBeInstanceOf<PhotoResult.ValidationError>()
            (result as PhotoResult.ValidationError).errors shouldBe errors
        }

        @Test
        fun `StorageError should contain message`() {
            val result: PhotoResult = PhotoResult.StorageError("Disk full")

            result.shouldBeInstanceOf<PhotoResult.StorageError>()
            (result as PhotoResult.StorageError).message shouldBe "Disk full"
        }
    }

    @Nested
    inner class UploadResultTypes {
        @Test
        fun `Success should contain url and thumbnailUrl`() {
            val result: UploadResult =
                UploadResult.Success(
                    url = "http://localhost:8080/uploads/photo.jpg",
                    thumbnailUrl = "http://localhost:8080/uploads/photo-thumb.jpg",
                )

            result.shouldBeInstanceOf<UploadResult.Success>()
            val success = result as UploadResult.Success
            success.url shouldBe "http://localhost:8080/uploads/photo.jpg"
            success.thumbnailUrl shouldBe "http://localhost:8080/uploads/photo-thumb.jpg"
        }

        @Test
        fun `ValidationError should contain list of errors`() {
            val errors = listOf("Invalid MIME type")
            val result: UploadResult = UploadResult.ValidationError(errors)

            result.shouldBeInstanceOf<UploadResult.ValidationError>()
            (result as UploadResult.ValidationError).errors shouldBe errors
        }

        @Test
        fun `StorageError should contain message`() {
            val result: UploadResult = UploadResult.StorageError("Connection failed")

            result.shouldBeInstanceOf<UploadResult.StorageError>()
            (result as UploadResult.StorageError).message shouldBe "Connection failed"
        }
    }

    @Nested
    inner class PatternMatching {
        @Test
        fun `when expression should match Success`() {
            val result: PhotoResult = PhotoResult.Success(testPhoto)

            val message =
                when (result) {
                    is PhotoResult.Success -> "Photo uploaded: ${result.photo.id}"
                    is PhotoResult.NotFound -> "Not found"
                    is PhotoResult.ValidationError -> "Validation failed"
                    is PhotoResult.StorageError -> "Storage error"
                }

            message shouldBe "Photo uploaded: ${testPhoto.id}"
        }

        @Test
        fun `when expression should match ValidationError`() {
            val result: PhotoResult = PhotoResult.ValidationError(listOf("Error 1", "Error 2"))

            val message =
                when (result) {
                    is PhotoResult.Success -> "Success"
                    is PhotoResult.NotFound -> "Not found"
                    is PhotoResult.ValidationError -> "Errors: ${result.errors.size}"
                    is PhotoResult.StorageError -> "Storage error"
                }

            message shouldBe "Errors: 2"
        }
    }
}
