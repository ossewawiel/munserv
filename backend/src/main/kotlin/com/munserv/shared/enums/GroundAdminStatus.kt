package com.munserv.shared.enums

/**
 * Enum representing the status of a Ground Admin.
 * Matches database enum: ground_admin_status
 */
enum class GroundAdminStatus(private val apiString: String) {
    ACTIVE("active"),
    ON_HOLD("on_hold"),
    INACTIVE("inactive"),
    ;

    fun toApiString(): String = apiString

    companion object {
        fun fromString(value: String): GroundAdminStatus =
            entries.find { it.apiString.equals(value, ignoreCase = true) }
                ?: throw IllegalArgumentException("Unknown GroundAdminStatus: $value")
    }
}
