package com.munserv.photos.repository

import com.munserv.issues.domain.IssueId
import com.munserv.photos.domain.IssuePhoto
import com.munserv.photos.domain.PhotoId
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import java.time.Instant
import java.util.UUID

/**
 * Unit tests for IssuePhotoEntity JPA entity.
 */
class IssuePhotoEntityTest {
    private val testPhotoUuid = UUID.fromString("550e8400-e29b-41d4-a716-446655440001")
    private val testIssueUuid = UUID.fromString("550e8400-e29b-41d4-a716-446655440002")
    private val testCreatedAt = Instant.parse("2026-01-15T10:30:00Z")

    private fun createTestEntity() =
        IssuePhotoEntity(
            id = testPhotoUuid,
            issueId = testIssueUuid,
            url = "http://localhost:8080/uploads/photo.jpg",
            thumbnailUrl = "http://localhost:8080/uploads/photo-thumb.jpg",
            sortOrder = 1,
            createdAt = testCreatedAt,
        )

    private fun createTestDomain() =
        IssuePhoto(
            id = PhotoId(testPhotoUuid),
            issueId = IssueId(testIssueUuid),
            url = "http://localhost:8080/uploads/photo.jpg",
            thumbnailUrl = "http://localhost:8080/uploads/photo-thumb.jpg",
            sortOrder = 1,
            createdAt = testCreatedAt,
        )

    @Nested
    inner class ToDomain {
        @Test
        fun `should convert entity to domain correctly`() {
            val entity = createTestEntity()
            val domain = entity.toDomain()

            domain.id.value shouldBe testPhotoUuid
            domain.issueId.value shouldBe testIssueUuid
            domain.url shouldBe "http://localhost:8080/uploads/photo.jpg"
            domain.thumbnailUrl shouldBe "http://localhost:8080/uploads/photo-thumb.jpg"
            domain.sortOrder shouldBe 1
            domain.createdAt shouldBe testCreatedAt
        }
    }

    @Nested
    inner class FromDomain {
        @Test
        fun `should convert domain to entity correctly`() {
            val domain = createTestDomain()
            val entity = IssuePhotoEntity.fromDomain(domain)

            entity.id shouldBe testPhotoUuid
            entity.issueId shouldBe testIssueUuid
            entity.url shouldBe "http://localhost:8080/uploads/photo.jpg"
            entity.thumbnailUrl shouldBe "http://localhost:8080/uploads/photo-thumb.jpg"
            entity.sortOrder shouldBe 1
            entity.createdAt shouldBe testCreatedAt
        }
    }

    @Nested
    inner class RoundTrip {
        @Test
        fun `domain to entity to domain should preserve all fields`() {
            val original = createTestDomain()
            val entity = IssuePhotoEntity.fromDomain(original)
            val roundTripped = entity.toDomain()

            roundTripped shouldBe original
        }
    }
}
