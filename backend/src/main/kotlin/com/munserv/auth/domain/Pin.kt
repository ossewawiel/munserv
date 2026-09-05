package com.munserv.auth.domain

import java.security.MessageDigest

/**
 * Value object representing a validated 4-digit PIN.
 * PINs are stored as SHA-256 hashes, never in plain text.
 */
@JvmInline
value class Pin private constructor(
    private val value: String,
) {
    /**
     * Generate SHA-256 hash of the PIN for storage.
     */
    fun hash(): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val hashBytes = digest.digest(value.toByteArray())
        return hashBytes.joinToString("") { "%02x".format(it) }
    }

    /**
     * toString returns masked value to prevent accidental logging of raw PIN.
     */
    override fun toString(): String = "****"

    companion object {
        private const val PIN_LENGTH = 4
        private val DIGITS_ONLY_REGEX = Regex("^[0-9]+$")

        /**
         * Create a Pin from a string.
         * PIN must be exactly 4 digits.
         *
         * @throws IllegalArgumentException if the PIN is invalid
         */
        fun fromString(value: String): Pin {
            require(value.isNotBlank()) { "PIN cannot be blank" }
            require(DIGITS_ONLY_REGEX.matches(value)) { "PIN must contain only digits" }
            require(value.length == PIN_LENGTH) { "PIN must be exactly $PIN_LENGTH digits" }

            return Pin(value)
        }

        /**
         * Verify a raw PIN against a stored hash.
         * Returns false for invalid PIN formats (instead of throwing).
         */
        fun verify(
            rawPin: String,
            storedHash: String,
        ): Boolean =
            try {
                val pin = fromString(rawPin)
                pin.hash() == storedHash
            } catch (e: IllegalArgumentException) {
                false
            }
    }
}
