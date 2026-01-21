package com.munserv.shared.config

import com.munserv.shared.enums.MessageStatus
import com.munserv.shared.enums.MessageType
import org.springframework.core.convert.converter.Converter
import org.springframework.stereotype.Component

/**
 * Converter for MessageStatus query parameters.
 * Accepts lowercase snake_case values (e.g., "unread" → UNREAD).
 */
@Component
class MessageStatusConverter : Converter<String, MessageStatus> {
    override fun convert(source: String): MessageStatus = MessageStatus.fromString(source)
}

/**
 * Converter for MessageType query parameters.
 * Accepts lowercase snake_case values (e.g., "ground_admin_invitation" → GROUND_ADMIN_INVITATION).
 */
@Component
class MessageTypeConverter : Converter<String, MessageType> {
    override fun convert(source: String): MessageType = MessageType.fromString(source)
}
