package com.munserv.auth.domain

import java.security.MessageDigest

/**
 * Value object representing a validated E.164 phone number.
 * Phone numbers are normalized to include the + prefix.
 */
@JvmInline
value class PhoneNumber private constructor(val value: String) {
    /**
     * Generate SHA-256 hash of the phone number for storage.
     * The hash is used instead of storing raw phone numbers.
     */
    fun hash(): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val hashBytes = digest.digest(value.toByteArray())
        return hashBytes.joinToString("") { "%02x".format(it) }
    }

    /**
     * Returns a masked version of the phone number for display.
     * Example: +27821234567 -> +278****567
     */
    fun masked(): String {
        if (value.length < 8) return "****"
        val prefix = value.take(4)
        val suffix = value.takeLast(3)
        return "$prefix****$suffix"
    }

    /**
     * toString returns masked value to prevent accidental logging of raw phone numbers.
     */
    override fun toString(): String = masked()

    companion object {
        private const val MIN_LENGTH = 10
        private const val MAX_LENGTH = 15
        private val E164_REGEX = Regex("^\\+?[0-9]+$")

        /**
         * Create a PhoneNumber from a string.
         * Normalizes the number to E.164 format (with + prefix).
         *
         * @throws IllegalArgumentException if the phone number is invalid
         */
        fun fromString(value: String): PhoneNumber {
            require(value.isNotBlank()) { "Phone number cannot be blank" }
            require(E164_REGEX.matches(value)) {
                "Phone number must contain only digits (optionally starting with +)"
            }

            val normalized = if (value.startsWith("+")) value else "+$value"
            val digitsOnly = normalized.drop(1)

            require(digitsOnly.length >= MIN_LENGTH - 1) {
                "Phone number too short (min $MIN_LENGTH digits including country code)"
            }
            require(digitsOnly.length <= MAX_LENGTH - 1) {
                "Phone number too long (max $MAX_LENGTH digits including country code)"
            }

            return PhoneNumber(normalized)
        }
    }
}
