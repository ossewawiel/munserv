package com.munserv.shared.types

import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import org.junit.jupiter.api.Test
import java.util.UUID

class PodIdTest {
    @Test
    fun `should create PodId with valid UUID`() {
        val uuid = UUID.randomUUID()
        val podId = PodId(uuid)

        podId.value shouldBe uuid
    }

    @Test
    fun `should create PodId from string`() {
        val uuidString = "550e8400-e29b-41d4-a716-446655440000"
        val podId = PodId.fromString(uuidString)

        podId.value.toString() shouldBe uuidString
    }

    @Test
    fun `should throw exception for invalid UUID string`() {
        shouldThrow<IllegalArgumentException> {
            PodId.fromString("not-a-uuid")
        }
    }

    @Test
    fun `should have correct equality`() {
        val uuid = UUID.randomUUID()
        val podId1 = PodId(uuid)
        val podId2 = PodId(uuid)
        val podId3 = PodId(UUID.randomUUID())

        podId1 shouldBe podId2
        podId1 shouldNotBe podId3
    }

    @Test
    fun `should have correct hashCode`() {
        val uuid = UUID.randomUUID()
        val podId1 = PodId(uuid)
        val podId2 = PodId(uuid)

        podId1.hashCode() shouldBe podId2.hashCode()
    }

    @Test
    fun `should have meaningful toString`() {
        val uuidString = "550e8400-e29b-41d4-a716-446655440000"
        val podId = PodId.fromString(uuidString)

        podId.toString() shouldBe uuidString
    }

    @Test
    fun `should generate new PodId`() {
        val podId = PodId.generate()

        podId.value shouldNotBe null
    }
}
