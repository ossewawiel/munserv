package com.munserv.auth.domain

import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.string.shouldHaveLength
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

class EmailTest {
    @Nested
    inner class Validation {
        @Test
        fun `should create Email from valid format`() {
            val email = Email.fromString("test@example.com")

            email.value shouldBe "test@example.com"
        }

        @Test
        fun `should accept email with subdomain`() {
            val email = Email.fromString("user@mail.example.com")

            email.value shouldBe "user@mail.example.com"
        }

        @Test
        fun `should accept email with plus tag`() {
            val email = Email.fromString("user.name+tag@domain.co.uk")

            email.value shouldBe "user.name+tag@domain.co.uk"
        }

        @Test
        fun `should accept email with numbers`() {
            val email = Email.fromString("user123@example123.com")

            email.value shouldBe "user123@example123.com"
        }

        @Test
        fun `should accept email with dots in local part`() {
            val email = Email.fromString("first.last@example.com")

            email.value shouldBe "first.last@example.com"
        }

        @Test
        fun `should reject email without at symbol`() {
            shouldThrow<IllegalArgumentException> {
                Email.fromString("invalid.email.com")
            }
        }

        @Test
        fun `should reject email without domain`() {
            shouldThrow<IllegalArgumentException> {
                Email.fromString("user@")
            }
        }

        @Test
        fun `should reject email without local part`() {
            shouldThrow<IllegalArgumentException> {
                Email.fromString("@example.com")
            }
        }

        @Test
        fun `should reject email without TLD`() {
            shouldThrow<IllegalArgumentException> {
                Email.fromString("user@example")
            }
        }

        @Test
        fun `should reject blank email`() {
            shouldThrow<IllegalArgumentException> {
                Email.fromString("")
            }
        }

        @Test
        fun `should reject whitespace only email`() {
            shouldThrow<IllegalArgumentException> {
                Email.fromString("   ")
            }
        }
    }

    @Nested
    inner class Normalization {
        @Test
        fun `should normalize email to lowercase`() {
            val email = Email.fromString("Test@EXAMPLE.COM")

            email.value shouldBe "test@example.com"
        }

        @Test
        fun `should trim whitespace`() {
            val email = Email.fromString("  test@example.com  ")

            email.value shouldBe "test@example.com"
        }

        @Test
        fun `should trim and lowercase`() {
            val email = Email.fromString("  TEST@Example.COM  ")

            email.value shouldBe "test@example.com"
        }
    }

    @Nested
    inner class Hashing {
        @Test
        fun `should generate consistent hash`() {
            val email = Email.fromString("test@example.com")

            val hash1 = email.hash()
            val hash2 = email.hash()

            hash1 shouldBe hash2
        }

        @Test
        fun `should generate same hash for same email with different cases`() {
            val email1 = Email.fromString("test@example.com")
            val email2 = Email.fromString("TEST@EXAMPLE.COM")

            email1.hash() shouldBe email2.hash()
        }

        @Test
        fun `should generate different hashes for different emails`() {
            val email1 = Email.fromString("user1@example.com")
            val email2 = Email.fromString("user2@example.com")

            email1.hash() shouldNotBe email2.hash()
        }

        @Test
        fun `hash should be SHA-256 hex string (64 characters)`() {
            val email = Email.fromString("test@example.com")
            val hash = email.hash()

            hash shouldHaveLength 64
            hash.all { it in '0'..'9' || it in 'a'..'f' } shouldBe true
        }
    }

    @Nested
    inner class Masking {
        @Test
        fun `should mask email with long local part`() {
            val email = Email.fromString("john.doe@example.com")

            email.masked() shouldBe "j******e@example.com"
        }

        @Test
        fun `should mask email with short local part`() {
            val email = Email.fromString("ab@test.com")

            email.masked() shouldBe "**@test.com"
        }

        @Test
        fun `should mask single character local part`() {
            val email = Email.fromString("a@test.com")

            email.masked() shouldBe "*@test.com"
        }

        @Test
        fun `should mask three character local part`() {
            val email = Email.fromString("abc@test.com")

            email.masked() shouldBe "a*c@test.com"
        }

        @Test
        fun `toString should return masked value`() {
            val email = Email.fromString("john.doe@example.com")

            email.toString() shouldBe "j******e@example.com"
            email.toString() shouldNotBe "john.doe@example.com"
        }
    }

    @Nested
    inner class Equality {
        @Test
        fun `should be equal for same normalized email`() {
            val email1 = Email.fromString("test@example.com")
            val email2 = Email.fromString("TEST@EXAMPLE.COM")

            email1 shouldBe email2
        }

        @Test
        fun `should not be equal for different emails`() {
            val email1 = Email.fromString("user1@example.com")
            val email2 = Email.fromString("user2@example.com")

            email1 shouldNotBe email2
        }
    }

    @Nested
    inner class StaticValidation {
        @Test
        fun `isValid should return true for valid email`() {
            Email.isValid("test@example.com") shouldBe true
        }

        @Test
        fun `isValid should return true for complex valid email`() {
            Email.isValid("user.name+tag@domain.co.uk") shouldBe true
        }

        @Test
        fun `isValid should return false for invalid email`() {
            Email.isValid("invalid") shouldBe false
        }

        @Test
        fun `isValid should return false for email without at symbol`() {
            Email.isValid("noat.com") shouldBe false
        }

        @Test
        fun `isValid should return false for email starting with at`() {
            Email.isValid("@nodomain.com") shouldBe false
        }

        @Test
        fun `isValid should return false for blank email`() {
            Email.isValid("") shouldBe false
        }
    }

    @Nested
    inner class FromStringOrNull {
        @Test
        fun `should return Email for valid input`() {
            val email = Email.fromStringOrNull("test@example.com")

            email shouldNotBe null
            email?.value shouldBe "test@example.com"
        }

        @Test
        fun `should return null for invalid input`() {
            val email = Email.fromStringOrNull("invalid")

            email shouldBe null
        }

        @Test
        fun `should return null for blank input`() {
            val email = Email.fromStringOrNull("")

            email shouldBe null
        }
    }
}
