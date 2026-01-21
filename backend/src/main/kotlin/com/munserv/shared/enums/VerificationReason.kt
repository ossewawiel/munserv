package com.munserv.shared.enums

import com.fasterxml.jackson.annotation.JsonCreator
import com.fasterxml.jackson.annotation.JsonValue

/**
 * Enum representing reasons why a Ground Admin cannot verify an issue.
 * Matches database enum: verification_reason
 */
enum class VerificationReason(
    @JsonValue private val apiString: String,
) {
    BUSY("busy"),
    AWAY("away"),
    CANNOT_FIND("cannot_find"),
    WRONG_LOCATION("wrong_location"),
    NOT_AN_ISSUE("not_an_issue"),
    ;

    fun toApiString(): String = apiString

    companion object {
        @JsonCreator
        @JvmStatic
        fun fromString(value: String): VerificationReason =
            entries.find { it.apiString.equals(value, ignoreCase = true) }
                ?: throw IllegalArgumentException("Unknown VerificationReason: $value")
    }
}
