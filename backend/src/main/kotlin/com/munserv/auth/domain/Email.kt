package com.munserv.auth.domain

import java.security.MessageDigest

/**
 * Value object representing a validated email address.
 * Provides hashing for privacy-preserving lookups and masking for display.
 */
@JvmInline
value class Email private constructor(val value: String) {
    /**
     * Returns SHA-256 hash for database lookups.
     * Never store plain email for query purposes.
     */
    fun hash(): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val hashBytes = digest.digest(value.toByteArray())
        return hashBytes.joinToString("") { "%02x".format(it) }
    }

    /**
     * Returns masked email for display: j***e@example.com
     */
    fun masked(): String {
        val parts = value.split("@")
        if (parts.size != 2) return "***@***"

        val local = parts[0]
        val domain = parts[1]

        val maskedLocal =
            when {
                local.length <= 1 -> "*".repeat(local.length)
                local.length == 2 -> "**"
                else -> local.first() + "*".repeat(local.length - 2) + local.last()
            }

        return "$maskedLocal@$domain"
    }

    override fun toString(): String = masked()

    companion object {
        private val EMAIL_REGEX =
            Regex(
                "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$",
            )

        /**
         * Creates Email from string, validating format.
         * @throws IllegalArgumentException if email format is invalid
         */
        fun fromString(value: String): Email {
            val trimmed = value.trim().lowercase()
            require(isValid(trimmed)) { "Invalid email format: $value" }
            return Email(trimmed)
        }

        /**
         * Validates email format without creating instance.
         */
        fun isValid(email: String): Boolean = email.isNotBlank() && EMAIL_REGEX.matches(email.trim())

        /**
         * Attempts to create Email, returning null if invalid.
         */
        fun fromStringOrNull(value: String): Email? = runCatching { fromString(value) }.getOrNull()
    }
}
