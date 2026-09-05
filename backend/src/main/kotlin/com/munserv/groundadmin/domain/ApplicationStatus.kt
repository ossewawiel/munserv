package com.munserv.groundadmin.domain

/**
 * Status of a Ground Admin application/invitation.
 */
enum class ApplicationStatus(
    private val dbValue: String,
) {
    PENDING("pending"),
    APPROVED("approved"),
    DECLINED("declined"),
    ACCEPTED("accepted"),
    REJECTED("rejected"),
    WITHDRAWN("withdrawn"),
    ;

    fun toDbValue(): String = dbValue

    companion object {
        fun fromString(value: String): ApplicationStatus =
            entries.find { it.dbValue.equals(value, ignoreCase = true) }
                ?: throw IllegalArgumentException("Unknown ApplicationStatus: $value")
    }
}
