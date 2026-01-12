package com.munserv.photos.domain

import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import java.util.UUID

/**
 * Unit tests for PhotoId value class.
 */
class PhotoIdTest {
    @Nested
    inner class Construction {
        @Test
        fun `should create PhotoId from UUID`() {
            val uuid = UUID.randomUUID()
            val photoId = PhotoId(uuid)

            photoId.value shouldBe uuid
        }

        @Test
        fun `should create PhotoId from string`() {
            val uuidString = "550e8400-e29b-41d4-a716-446655440001"
            val photoId = PhotoId.fromString(uuidString)

            photoId.value.toString() shouldBe uuidString
        }

        @Test
        fun `should throw exception for invalid UUID string`() {
            shouldThrow<IllegalArgumentException> {
                PhotoId.fromString("not-a-uuid")
            }
        }
    }

    @Nested
    inner class Generate {
        @Test
        fun `should generate unique PhotoIds`() {
            val id1 = PhotoId.generate()
            val id2 = PhotoId.generate()

            id1 shouldNotBe id2
        }
    }

    @Nested
    inner class ToString {
        @Test
        fun `toString should return UUID string`() {
            val uuid = UUID.fromString("550e8400-e29b-41d4-a716-446655440001")
            val photoId = PhotoId(uuid)

            photoId.toString() shouldBe "550e8400-e29b-41d4-a716-446655440001"
        }
    }

    @Nested
    inner class Equality {
        @Test
        fun `PhotoIds with same UUID should be equal`() {
            val uuid = UUID.randomUUID()
            val id1 = PhotoId(uuid)
            val id2 = PhotoId(uuid)

            id1 shouldBe id2
        }

        @Test
        fun `PhotoIds with different UUIDs should not be equal`() {
            val id1 = PhotoId.generate()
            val id2 = PhotoId.generate()

            id1 shouldNotBe id2
        }
    }
}
