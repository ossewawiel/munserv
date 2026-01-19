package com.munserv.verification.domain

/**
 * Enum representing the status of a verification request.
 */
enum class VerificationStatus(private val dbValue: String) {
    /**
     * Verification is waiting for a Ground Admin to respond.
     */
    PENDING("pending"),

    /**
     * Verification has been completed by a Ground Admin.
     */
    COMPLETED("completed"),

    /**
     * Verification request has expired without being completed.
     */
    EXPIRED("expired"),
    ;

    fun toDbValue(): String = dbValue

    companion object {
        fun fromString(value: String): VerificationStatus =
            entries.find { it.dbValue.equals(value, ignoreCase = true) }
                ?: throw IllegalArgumentException("Unknown VerificationStatus: $value")
    }
}
