package com.munserv.verification.domain

/**
 * Enum representing the outcome of a completed verification.
 */
enum class VerificationOutcome(private val dbValue: String) {
    /**
     * Issue existence or fix has been confirmed.
     */
    CONFIRMED("confirmed"),

    /**
     * Issue was not found at the reported location.
     */
    NOT_FOUND("not_found"),

    /**
     * Fix was not complete (issue still exists).
     */
    NOT_FIXED("not_fixed"),

    /**
     * Ground Admin could not verify for some reason.
     */
    CANNOT_VERIFY("cannot_verify"),
    ;

    fun toDbValue(): String = dbValue

    companion object {
        fun fromString(value: String): VerificationOutcome =
            entries.find { it.dbValue.equals(value, ignoreCase = true) }
                ?: throw IllegalArgumentException("Unknown VerificationOutcome: $value")
    }
}
