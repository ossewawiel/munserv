package com.munserv.shared.enums

import com.fasterxml.jackson.annotation.JsonCreator
import com.fasterxml.jackson.annotation.JsonValue

/**
 * Enum representing how Ground Admins are notified about verification requests.
 * Matches database enum: verification_mode
 */
enum class VerificationMode(
    @JsonValue private val apiString: String,
) {
    ALL_NOTIFIED("all_notified"),
    ADMIN_ASSIGNS("admin_assigns"),
    NEAREST_AUTO("nearest_auto"),
    FIRST_COME("first_come"),
    ;

    fun toApiString(): String = apiString

    companion object {
        @JsonCreator
        @JvmStatic
        fun fromString(value: String): VerificationMode =
            entries.find { it.apiString.equals(value, ignoreCase = true) }
                ?: throw IllegalArgumentException("Unknown VerificationMode: $value")
    }
}
