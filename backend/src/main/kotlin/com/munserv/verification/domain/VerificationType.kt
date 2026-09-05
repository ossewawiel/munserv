package com.munserv.verification.domain

/**
 * Enum representing the type of verification being performed.
 */
enum class VerificationType(
    private val dbValue: String,
) {
    /**
     * Verification that a reported issue actually exists.
     */
    EXISTENCE("existence"),

    /**
     * Verification that a fix has been completed.
     */
    FIX("fix"),
    ;

    fun toDbValue(): String = dbValue

    companion object {
        fun fromString(value: String): VerificationType =
            entries.find { it.dbValue.equals(value, ignoreCase = true) }
                ?: throw IllegalArgumentException("Unknown VerificationType: $value")
    }
}
