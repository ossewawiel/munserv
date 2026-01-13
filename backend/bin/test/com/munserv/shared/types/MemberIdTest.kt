package com.munserv.shared.types

import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import org.junit.jupiter.api.Test
import java.util.UUID

class MemberIdTest {
    @Test
    fun `should create MemberId with valid UUID`() {
        val uuid = UUID.randomUUID()
        val memberId = MemberId(uuid)

        memberId.value shouldBe uuid
    }

    @Test
    fun `should create MemberId from string`() {
        val uuidString = "550e8400-e29b-41d4-a716-446655440010"
        val memberId = MemberId.fromString(uuidString)

        memberId.value.toString() shouldBe uuidString
    }

    @Test
    fun `should throw exception for invalid UUID string`() {
        shouldThrow<IllegalArgumentException> {
            MemberId.fromString("not-a-uuid")
        }
    }

    @Test
    fun `should have correct equality`() {
        val uuid = UUID.randomUUID()
        val memberId1 = MemberId(uuid)
        val memberId2 = MemberId(uuid)
        val memberId3 = MemberId(UUID.randomUUID())

        memberId1 shouldBe memberId2
        memberId1 shouldNotBe memberId3
    }

    @Test
    fun `should have meaningful toString`() {
        val uuidString = "550e8400-e29b-41d4-a716-446655440010"
        val memberId = MemberId.fromString(uuidString)

        memberId.toString() shouldBe uuidString
    }

    @Test
    fun `should generate new MemberId`() {
        val memberId = MemberId.generate()

        memberId.value shouldNotBe null
    }
}
