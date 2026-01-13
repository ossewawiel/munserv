package com.munserv.auth.domain

import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.string.shouldHaveLength
import org.junit.jupiter.api.Test

class PinTest {
    @Test
    fun `should create Pin from valid 4-digit string`() {
        val pin = Pin.fromString("1234")

        pin shouldNotBe null
    }

    @Test
    fun `should reject PIN that is too short`() {
        shouldThrow<IllegalArgumentException> {
            Pin.fromString("123")
        }
    }

    @Test
    fun `should reject PIN that is too long`() {
        shouldThrow<IllegalArgumentException> {
            Pin.fromString("12345")
        }
    }

    @Test
    fun `should reject PIN with non-numeric characters`() {
        shouldThrow<IllegalArgumentException> {
            Pin.fromString("12ab")
        }
    }

    @Test
    fun `should reject PIN with spaces`() {
        shouldThrow<IllegalArgumentException> {
            Pin.fromString("12 4")
        }
    }

    @Test
    fun `should reject empty PIN`() {
        shouldThrow<IllegalArgumentException> {
            Pin.fromString("")
        }
    }

    @Test
    fun `should generate consistent hash`() {
        val pin = Pin.fromString("1234")

        val hash1 = pin.hash()
        val hash2 = pin.hash()

        hash1 shouldBe hash2
        hash1 shouldHaveLength 64
    }

    @Test
    fun `should generate different hashes for different PINs`() {
        val pin1 = Pin.fromString("1234")
        val pin2 = Pin.fromString("5678")

        pin1.hash() shouldNotBe pin2.hash()
    }

    @Test
    fun `hash should be SHA-256 hex string`() {
        val pin = Pin.fromString("1234")
        val hash = pin.hash()

        hash shouldHaveLength 64
        hash.all { it in '0'..'9' || it in 'a'..'f' } shouldBe true
    }

    @Test
    fun `should verify correct PIN against hash`() {
        val pin = Pin.fromString("1234")
        val storedHash = pin.hash()

        Pin.verify("1234", storedHash) shouldBe true
    }

    @Test
    fun `should not verify incorrect PIN against hash`() {
        val pin = Pin.fromString("1234")
        val storedHash = pin.hash()

        Pin.verify("5678", storedHash) shouldBe false
    }

    @Test
    fun `verify should return false for invalid PIN format`() {
        val pin = Pin.fromString("1234")
        val storedHash = pin.hash()

        Pin.verify("abc", storedHash) shouldBe false
        Pin.verify("", storedHash) shouldBe false
        Pin.verify("12345", storedHash) shouldBe false
    }

    @Test
    fun `toString should return masked value for security`() {
        val pin = Pin.fromString("1234")

        pin.toString() shouldBe "****"
        pin.toString() shouldNotBe "1234"
    }

    @Test
    fun `same PIN values should be equal`() {
        val pin1 = Pin.fromString("1234")
        val pin2 = Pin.fromString("1234")

        pin1 shouldBe pin2
    }

    @Test
    fun `different PIN values should not be equal`() {
        val pin1 = Pin.fromString("1234")
        val pin2 = Pin.fromString("5678")

        pin1 shouldNotBe pin2
    }
}
