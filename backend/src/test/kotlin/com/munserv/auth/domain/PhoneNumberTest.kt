package com.munserv.auth.domain

import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.string.shouldHaveLength
import io.kotest.matchers.string.shouldStartWith
import org.junit.jupiter.api.Test

class PhoneNumberTest {
    @Test
    fun `should create PhoneNumber from valid E164 format`() {
        val phone = PhoneNumber.fromString("+27821234567")

        phone.value shouldBe "+27821234567"
    }

    @Test
    fun `should normalize phone number without plus sign`() {
        val phone = PhoneNumber.fromString("27821234567")

        phone.value shouldBe "+27821234567"
    }

    @Test
    fun `should reject phone number that is too short`() {
        shouldThrow<IllegalArgumentException> {
            PhoneNumber.fromString("+2782")
        }
    }

    @Test
    fun `should reject phone number that is too long`() {
        shouldThrow<IllegalArgumentException> {
            PhoneNumber.fromString("+2782123456789012345")
        }
    }

    @Test
    fun `should reject phone number with non-numeric characters`() {
        shouldThrow<IllegalArgumentException> {
            PhoneNumber.fromString("+27-821-234-567")
        }
    }

    @Test
    fun `should reject phone number with letters`() {
        shouldThrow<IllegalArgumentException> {
            PhoneNumber.fromString("+27abc234567")
        }
    }

    @Test
    fun `should reject empty phone number`() {
        shouldThrow<IllegalArgumentException> {
            PhoneNumber.fromString("")
        }
    }

    @Test
    fun `should have correct equality`() {
        val phone1 = PhoneNumber.fromString("+27821234567")
        val phone2 = PhoneNumber.fromString("27821234567")
        val phone3 = PhoneNumber.fromString("+27829999999")

        phone1 shouldBe phone2
        phone1 shouldNotBe phone3
    }

    @Test
    fun `should generate consistent hash`() {
        val phone = PhoneNumber.fromString("+27821234567")

        val hash1 = phone.hash()
        val hash2 = phone.hash()

        hash1 shouldBe hash2
        hash1 shouldHaveLength 64
    }

    @Test
    fun `should generate different hashes for different numbers`() {
        val phone1 = PhoneNumber.fromString("+27821234567")
        val phone2 = PhoneNumber.fromString("+27829999999")

        phone1.hash() shouldNotBe phone2.hash()
    }

    @Test
    fun `hash should be SHA-256 hex string`() {
        val phone = PhoneNumber.fromString("+27821234567")
        val hash = phone.hash()

        hash shouldHaveLength 64
        hash.all { it in '0'..'9' || it in 'a'..'f' } shouldBe true
    }

    @Test
    fun `should mask phone number for display`() {
        val phone = PhoneNumber.fromString("+27821234567")

        phone.masked() shouldStartWith "+27"
        phone.masked().contains("****") shouldBe true
    }

    @Test
    fun `toString should return masked value for security`() {
        val phone = PhoneNumber.fromString("+27821234567")

        phone.toString().contains("****") shouldBe true
        phone.toString() shouldNotBe "+27821234567"
    }
}
