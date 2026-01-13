package com.munserv.photos.domain

import com.munserv.issues.domain.IssueId
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import java.time.Instant
import java.util.UUID

/**
 * Unit tests for IssuePhoto domain entity.
 */
class IssuePhotoTest {
    private val testPhotoId = PhotoId(UUID.fromString("550e8400-e29b-41d4-a716-446655440001"))
    private val testIssueId = IssueId(UUID.fromString("550e8400-e29b-41d4-a716-446655440002"))
    private val testCreatedAt = Instant.parse("2026-01-15T10:30:00Z")

    private fun createTestPhoto() =
        IssuePhoto(
            id = testPhotoId,
            issueId = testIssueId,
            url = "http://localhost:8080/uploads/photo.jpg",
            thumbnailUrl = "http://localhost:8080/uploads/photo-thumb.jpg",
            sortOrder = 1,
            createdAt = testCreatedAt,
        )

    @Nested
    inner class Construction {
        @Test
        fun `should create IssuePhoto with all fields`() {
            val photo = createTestPhoto()

            photo.id shouldBe testPhotoId
            photo.issueId shouldBe testIssueId
            photo.url shouldBe "http://localhost:8080/uploads/photo.jpg"
            photo.thumbnailUrl shouldBe "http://localhost:8080/uploads/photo-thumb.jpg"
            photo.sortOrder shouldBe 1
            photo.createdAt shouldBe testCreatedAt
        }
    }

    @Nested
    inner class Immutability {
        @Test
        fun `copy should create new instance with modified field`() {
            val original = createTestPhoto()
            val modified = original.copy(sortOrder = 2)

            original.sortOrder shouldBe 1
            modified.sortOrder shouldBe 2
            modified.id shouldBe original.id
        }

        @Test
        fun `copy should preserve unmodified fields`() {
            val original = createTestPhoto()
            val modified = original.copy(url = "http://new-url.com/photo.jpg")

            modified.id shouldBe original.id
            modified.issueId shouldBe original.issueId
            modified.thumbnailUrl shouldBe original.thumbnailUrl
            modified.sortOrder shouldBe original.sortOrder
            modified.createdAt shouldBe original.createdAt
            modified.url shouldBe "http://new-url.com/photo.jpg"
        }
    }

    @Nested
    inner class Equality {
        @Test
        fun `two IssuePhotos with same fields should be equal`() {
            val photo1 = createTestPhoto()
            val photo2 = createTestPhoto()

            photo1 shouldBe photo2
        }

        @Test
        fun `two IssuePhotos with different sortOrder should not be equal`() {
            val photo1 = createTestPhoto()
            val photo2 = photo1.copy(sortOrder = 2)

            (photo1 == photo2) shouldBe false
        }
    }
}
