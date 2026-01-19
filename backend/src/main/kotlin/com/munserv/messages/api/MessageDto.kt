package com.munserv.messages.api

import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.munserv.messages.domain.MessageEntity
import com.munserv.shared.enums.MessageStatus
import com.munserv.shared.enums.MessageType
import io.swagger.v3.oas.annotations.media.Schema
import java.time.Instant

/**
 * Response DTO for a single message.
 */
@Schema(description = "Message details")
data class MessageResponse(
    @Schema(description = "Unique message ID", example = "550e8400-e29b-41d4-a716-446655440000")
    val id: String,
    @Schema(description = "Message type")
    val type: MessageType,
    @Schema(description = "Message title", example = "Ground Admin Invitation")
    val title: String,
    @Schema(description = "Message body content")
    val body: String,
    @Schema(description = "Recipient ID")
    val recipientId: String,
    @Schema(description = "Recipient type", example = "member")
    val recipientType: String,
    @Schema(description = "Sender ID (if applicable)")
    val senderId: String?,
    @Schema(description = "Sender type", example = "admin")
    val senderType: String?,
    @Schema(description = "Message status")
    val status: MessageStatus,
    @Schema(description = "Type of action available for this message", example = "accept_decline")
    val actionType: String?,
    @Schema(description = "Related entity ID")
    val relatedEntityId: String?,
    @Schema(description = "Related entity type", example = "issue")
    val relatedEntityType: String?,
    @Schema(description = "Result of action taken")
    val actionResult: String?,
    @Schema(description = "Additional metadata as JSON object")
    val metadata: Map<String, Any>?,
    @Schema(description = "Message creation timestamp")
    val createdAt: Instant,
    @Schema(description = "Timestamp when message was read")
    val readAt: Instant?,
    @Schema(description = "Timestamp when action was taken")
    val actionedAt: Instant?,
    @Schema(description = "Message expiration timestamp")
    val expiresAt: Instant?,
) {
    companion object {
        private val mapper = jacksonObjectMapper()

        /**
         * Creates a MessageResponse from a MessageEntity.
         */
        @Suppress("UNCHECKED_CAST")
        fun from(entity: MessageEntity) =
            MessageResponse(
                id = entity.id.toString(),
                type = entity.type,
                title = entity.title,
                body = entity.body,
                recipientId = entity.recipientId.toString(),
                recipientType = entity.recipientType,
                senderId = entity.senderId?.toString(),
                senderType = entity.senderType,
                status = entity.status,
                actionType = entity.actionType,
                relatedEntityId = entity.relatedEntityId?.toString(),
                relatedEntityType = entity.relatedEntityType,
                actionResult = entity.actionResult,
                metadata =
                    entity.metadata?.let {
                        mapper.readValue(it, Map::class.java) as Map<String, Any>
                    },
                createdAt = entity.createdAt,
                readAt = entity.readAt,
                actionedAt = entity.actionedAt,
                expiresAt = entity.expiresAt,
            )
    }
}

/**
 * Response DTO for a paginated list of messages.
 */
@Schema(description = "Paginated message list response")
data class MessageListResponse(
    @Schema(description = "List of messages")
    val items: List<MessageResponse>,
    @Schema(description = "Total number of messages")
    val total: Long,
    @Schema(description = "Current page number (1-based)")
    val page: Int,
    @Schema(description = "Count of unread messages for this recipient")
    val unreadCount: Long,
)

/**
 * Request DTO for performing an action on a message.
 */
@Schema(description = "Message action request")
data class MessageActionRequest(
    @Schema(
        description = "Action to perform",
        example = "accept",
        allowableValues = ["accept", "decline", "approve", "reject", "confirm", "cannot_verify", "dismiss", "acknowledge"],
    )
    val action: String,
    @Schema(description = "Optional note for the action")
    val note: String? = null,
)
