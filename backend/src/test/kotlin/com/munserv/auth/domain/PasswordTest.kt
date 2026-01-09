package com.munserv.auth.domain

import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.string.shouldHaveMinLength
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.RepeatedTest
import org.junit.jupiter.api.Test

class PasswordTest {
    @Nested
    inner class Validation {
        @Test
        fun `should accept valid password with all requirements`() {
            val errors = Password.validate("Abc12345")

            errors.shouldBeEmpty()
        }

        @Test
        fun `should accept complex valid password`() {
            val errors = Password.validate("MySecurePass123")

            errors.shouldBeEmpty()
        }

        @Test
        fun `should reject password shorter than 8 characters`() {
            val errors = Password.validate("Abc123")

            errors shouldHaveSize 1
            errors.first() shouldBe "Password must be at least ${Password.MIN_LENGTH} characters"
        }

        @Test
        fun `should reject password without uppercase letter`() {
            val errors = Password.validate("alllowercase1")

            errors shouldHaveSize 1
            errors.first() shouldBe "Password must contain at least one uppercase letter"
        }

        @Test
        fun `should reject password without lowercase letter`() {
            val errors = Password.validate("ALLUPPERCASE1")

            errors shouldHaveSize 1
            errors.first() shouldBe "Password must contain at least one lowercase letter"
        }

        @Test
        fun `should reject password without number`() {
            val errors = Password.validate("NoNumbersHere")

            errors shouldHaveSize 1
            errors.first() shouldBe "Password must contain at least one number"
        }

        @Test
        fun `should return multiple errors for password violating multiple rules`() {
            val errors = Password.validate("short")

            errors shouldHaveSize 3
            errors shouldContain "Password must be at least ${Password.MIN_LENGTH} characters"
            errors shouldContain "Password must contain at least one uppercase letter"
            errors shouldContain "Password must contain at least one number"
        }

        @Test
        fun `should reject empty password with all errors`() {
            val errors = Password.validate("")

            errors shouldHaveSize 4
        }
    }

    @Nested
    inner class IsValid {
        @Test
        fun `should return true for valid password`() {
            Password.isValid("ValidPass123") shouldBe true
        }

        @Test
        fun `should return false for invalid password`() {
            Password.isValid("invalid") shouldBe false
        }

        @Test
        fun `should return false for password too short`() {
            Password.isValid("Ab1") shouldBe false
        }

        @Test
        fun `should return false for password without uppercase`() {
            Password.isValid("lowercase123") shouldBe false
        }

        @Test
        fun `should return false for password without lowercase`() {
            Password.isValid("UPPERCASE123") shouldBe false
        }

        @Test
        fun `should return false for password without number`() {
            Password.isValid("NoNumbers") shouldBe false
        }
    }

    @Nested
    inner class Hashing {
        @Test
        fun `should hash password using BCrypt`() {
            val plaintext = "TestPassword123"

            val hash = Password.hash(plaintext)

            // BCrypt hashes start with $2
            hash.startsWith("\$2") shouldBe true
        }

        @Test
        fun `should produce different hashes for same password`() {
            val plaintext = "TestPassword123"

            val hash1 = Password.hash(plaintext)
            val hash2 = Password.hash(plaintext)

            // BCrypt uses random salt, so hashes should differ
            hash1 shouldNotBe hash2
        }

        @Test
        fun `should produce hash of expected length`() {
            val plaintext = "TestPassword123"

            val hash = Password.hash(plaintext)

            // BCrypt hash is 60 characters
            hash.length shouldBe 60
        }
    }

    @Nested
    inner class Verification {
        @Test
        fun `should verify correct password against hash`() {
            val plaintext = "TestPassword123"
            val hash = Password.hash(plaintext)

            val result = Password.verify(plaintext, hash)

            result shouldBe true
        }

        @Test
        fun `should reject incorrect password against hash`() {
            val plaintext = "TestPassword123"
            val hash = Password.hash(plaintext)

            val result = Password.verify("WrongPassword123", hash)

            result shouldBe false
        }

        @Test
        fun `should return false for invalid hash format`() {
            val result = Password.verify("TestPassword123", "invalid-hash")

            result shouldBe false
        }

        @Test
        fun `should return false for empty hash`() {
            val result = Password.verify("TestPassword123", "")

            result shouldBe false
        }

        @Test
        fun `should return false for empty password`() {
            val hash = Password.hash("TestPassword123")

            val result = Password.verify("", hash)

            result shouldBe false
        }
    }

    @Nested
    inner class Generation {
        @Test
        fun `should generate password of default length`() {
            val password = Password.generate()

            password.length shouldBe 12
        }

        @Test
        fun `should generate password of specified length`() {
            val password = Password.generate(16)

            password.length shouldBe 16
        }

        @Test
        fun `should generate valid password meeting all requirements`() {
            val password = Password.generate()

            Password.isValid(password) shouldBe true
        }

        @RepeatedTest(100)
        fun `should consistently generate valid passwords`() {
            val password = Password.generate()

            Password.isValid(password) shouldBe true
            password shouldHaveMinLength Password.MIN_LENGTH
        }

        @Test
        fun `should generate unique passwords`() {
            val passwords = (1..100).map { Password.generate() }.toSet()

            // All 100 passwords should be unique
            passwords shouldHaveSize 100
        }

        @Test
        fun `should throw for length less than 8`() {
            val exception = runCatching { Password.generate(7) }.exceptionOrNull()

            exception shouldNotBe null
            exception?.message shouldBe "Password length must be at least 8"
        }

        @Test
        fun `should generate password containing uppercase`() {
            val password = Password.generate()

            password.any { it.isUpperCase() } shouldBe true
        }

        @Test
        fun `should generate password containing lowercase`() {
            val password = Password.generate()

            password.any { it.isLowerCase() } shouldBe true
        }

        @Test
        fun `should generate password containing digit`() {
            val password = Password.generate()

            password.any { it.isDigit() } shouldBe true
        }

        @Test
        fun `should not contain ambiguous characters`() {
            // Generate many passwords to ensure ambiguous chars are excluded
            val passwords = (1..100).map { Password.generate() }
            val allChars = passwords.flatMap { it.toList() }

            // Excluded: I, O, 0, 1, i, l, o
            allChars.none { it in listOf('I', 'O', '0', '1', 'i', 'l', 'o') } shouldBe true
        }
    }
}
