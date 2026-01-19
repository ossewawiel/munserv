package com.munserv.groundadmin.domain

/**
 * Type of Ground Admin application/invitation.
 */
enum class ApplicationType(private val dbValue: String) {
    APPLICATION("application"),
    INVITATION("invitation"),
    ;

    fun toDbValue(): String = dbValue

    companion object {
        fun fromString(value: String): ApplicationType =
            entries.find { it.dbValue.equals(value, ignoreCase = true) }
                ?: throw IllegalArgumentException("Unknown ApplicationType: $value")
    }
}
