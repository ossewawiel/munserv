package com.munserv.shared.enums

import com.fasterxml.jackson.annotation.JsonCreator
import com.fasterxml.jackson.annotation.JsonValue

/**
 * Enum representing the status of a message.
 * Matches database enum: message_status
 */
enum class MessageStatus(
    @JsonValue private val apiString: String,
) {
    UNREAD("unread"),
    READ("read"),
    ACTIONED("actioned"),
    DISMISSED("dismissed"),
    ;

    fun toApiString(): String = apiString

    companion object {
        @JsonCreator
        @JvmStatic
        fun fromString(value: String): MessageStatus =
            entries.find { it.apiString.equals(value, ignoreCase = true) }
                ?: throw IllegalArgumentException("Unknown MessageStatus: $value")
    }
}
