package com.munserv.auth.domain

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder
import java.security.SecureRandom

/**
 * Password utilities for hashing, validation, and generation.
 * Uses BCrypt with cost factor 12 for secure hashing.
 */
object Password {
    private val encoder = BCryptPasswordEncoder(12)
    private val secureRandom = SecureRandom()

    /** Minimum required password length. */
    const val MIN_LENGTH = 8

    private val UPPERCASE_REGEX = Regex("[A-Z]")
    private val LOWERCASE_REGEX = Regex("[a-z]")
    private val DIGIT_REGEX = Regex("[0-9]")

    /**
     * Hashes a plain-text password using BCrypt.
     */
    fun hash(plaintext: String): String = requireNotNull(encoder.encode(plaintext))

    /**
     * Verifies a plain-text password against a BCrypt hash.
     * Returns false for invalid input instead of throwing.
     */
    fun verify(
        plaintext: String,
        hash: String,
    ): Boolean =
        runCatching {
            encoder.matches(plaintext, hash)
        }.getOrDefault(false)

    /**
     * Validates password meets requirements.
     * Returns list of validation errors (empty if valid).
     */
    fun validate(password: String): List<String> {
        val errors = mutableListOf<String>()

        if (password.length < MIN_LENGTH) {
            errors.add("Password must be at least $MIN_LENGTH characters")
        }
        if (!UPPERCASE_REGEX.containsMatchIn(password)) {
            errors.add("Password must contain at least one uppercase letter")
        }
        if (!LOWERCASE_REGEX.containsMatchIn(password)) {
            errors.add("Password must contain at least one lowercase letter")
        }
        if (!DIGIT_REGEX.containsMatchIn(password)) {
            errors.add("Password must contain at least one number")
        }

        return errors
    }

    /**
     * Checks if password is valid (meets all requirements).
     */
    fun isValid(password: String): Boolean = validate(password).isEmpty()

    /**
     * Generates a secure random password that meets all requirements.
     * Excludes ambiguous characters (I, O, 0, 1, i, l, o) for readability.
     *
     * @param length Password length (minimum 8)
     * @return Generated password meeting all requirements
     * @throws IllegalArgumentException if length is less than 8
     */
    fun generate(length: Int = 12): String {
        require(length >= MIN_LENGTH) { "Password length must be at least $MIN_LENGTH" }

        // Character sets excluding ambiguous characters (I, O, 0, 1, i, l, o)
        val uppercase = "ABCDEFGHJKLMNPQRSTUVWXYZ"
        val lowercase = "abcdefghjkmnpqrstuvwxyz"
        val digits = "23456789"

        val password = StringBuilder()

        // Ensure at least one of each required type
        password.append(uppercase[secureRandom.nextInt(uppercase.length)])
        password.append(lowercase[secureRandom.nextInt(lowercase.length)])
        password.append(digits[secureRandom.nextInt(digits.length)])
        password.append(digits[secureRandom.nextInt(digits.length)])

        // Fill remaining with mixed characters
        val allChars = uppercase + lowercase + digits
        repeat(length - 4) {
            password.append(allChars[secureRandom.nextInt(allChars.length)])
        }

        // Shuffle to randomize position of required characters
        return password
            .toString()
            .toList()
            .shuffled(secureRandom)
            .joinToString("")
    }
}
