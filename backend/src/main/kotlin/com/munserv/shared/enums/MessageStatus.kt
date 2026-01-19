package com.munserv.shared.enums

/**
 * Enum representing the status of a message.
 * Matches database enum: message_status
 */
enum class MessageStatus(private val apiString: String) {
    UNREAD("unread"),
    READ("read"),
    ACTIONED("actioned"),
    DISMISSED("dismissed"),
    ;

    fun toApiString(): String = apiString

    companion object {
        fun fromString(value: String): MessageStatus =
            entries.find { it.apiString.equals(value, ignoreCase = true) }
                ?: throw IllegalArgumentException("Unknown MessageStatus: $value")
    }
}
