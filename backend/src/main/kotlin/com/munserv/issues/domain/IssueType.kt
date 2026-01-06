package com.munserv.issues.domain

/**
 * Enum representing types of infrastructure issues.
 * Matches database enum: issue_type
 */
enum class IssueType(val displayName: String, private val apiString: String) {
    POTHOLE("Pothole", "pothole"),
    WATER_LEAK("Water Leak", "water_leak"),
    SEWAGE_LEAK("Sewage Leak", "sewage_leak"),
    TRAFFIC_LIGHT("Traffic Light", "traffic_light"),
    STREET_LIGHT("Street Light", "street_light"),
    ILLEGAL_DUMPING("Illegal Dumping", "illegal_dumping"),
    OTHER("Other", "other"),
    ;

    fun toApiString(): String = apiString

    companion object {
        fun fromString(value: String): IssueType =
            entries.find { it.apiString.equals(value, ignoreCase = true) }
                ?: throw IllegalArgumentException("Unknown issue type: $value")
    }
}
