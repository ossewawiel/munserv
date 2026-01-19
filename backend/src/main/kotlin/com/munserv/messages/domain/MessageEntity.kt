package com.munserv.messages.domain

import com.munserv.shared.enums.MessageStatus
import com.munserv.shared.enums.MessageType
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import org.hibernate.annotations.ColumnTransformer
import java.time.Instant
import java.util.UUID

/**
 * JPA Entity representing a message in the messaging system.
 *
 * Messages are used for platform communications including:
 * - Ground Admin lifecycle (invitations, applications, approvals)
 * - Verification workflows (issue verification requests)
 * - System notifications (member registration, reports)
 */
@Entity
@Table(name = "messages")
class MessageEntity(
    @Id
    val id: UUID = UUID.randomUUID(),
    @Column(name = "type", nullable = false, columnDefinition = "message_type")
    @ColumnTransformer(write = "?::message_type")
    private val typeValue: String,
    @Column(name = "title", nullable = false, length = 200)
    val title: String,
    @Column(name = "body", nullable = false, columnDefinition = "TEXT")
    val body: String,
    @Column(name = "recipient_id", nullable = false)
    val recipientId: UUID,
    @Column(name = "recipient_type", nullable = false, length = 20)
    val recipientType: String,
    @Column(name = "sender_id")
    val senderId: UUID? = null,
    @Column(name = "sender_type", length = 20)
    val senderType: String? = null,
    @Column(name = "status", nullable = false, columnDefinition = "message_status")
    @ColumnTransformer(write = "?::message_status")
    private var statusValue: String = "unread",
    @Column(name = "read_at")
    var readAt: Instant? = null,
    @Column(name = "actioned_at")
    var actionedAt: Instant? = null,
    @Column(name = "action_result", length = 50)
    var actionResult: String? = null,
    @Column(name = "related_entity_id")
    val relatedEntityId: UUID? = null,
    @Column(name = "related_entity_type", length = 50)
    val relatedEntityType: String? = null,
    @Column(name = "action_type", length = 50)
    val actionType: String? = null,
    @Column(name = "metadata", columnDefinition = "JSONB")
    val metadata: String? = null,
    @Column(name = "created_at", nullable = false)
    val createdAt: Instant = Instant.now(),
    @Column(name = "expires_at")
    val expiresAt: Instant? = null,
) {
    /**
     * Primary constructor for creating messages with enum types.
     */
    constructor(
        id: UUID = UUID.randomUUID(),
        type: MessageType,
        title: String,
        body: String,
        recipientId: UUID,
        recipientType: String,
        senderId: UUID? = null,
        senderType: String? = null,
        status: MessageStatus = MessageStatus.UNREAD,
        readAt: Instant? = null,
        actionedAt: Instant? = null,
        actionResult: String? = null,
        relatedEntityId: UUID? = null,
        relatedEntityType: String? = null,
        actionType: String? = null,
        metadata: String? = null,
        createdAt: Instant = Instant.now(),
        expiresAt: Instant? = null,
    ) : this(
        id = id,
        typeValue = type.toApiString(),
        title = title,
        body = body,
        recipientId = recipientId,
        recipientType = recipientType,
        senderId = senderId,
        senderType = senderType,
        statusValue = status.toApiString(),
        readAt = readAt,
        actionedAt = actionedAt,
        actionResult = actionResult,
        relatedEntityId = relatedEntityId,
        relatedEntityType = relatedEntityType,
        actionType = actionType,
        metadata = metadata,
        createdAt = createdAt,
        expiresAt = expiresAt,
    )

    /**
     * Get the message type as enum.
     */
    val type: MessageType
        get() = MessageType.fromString(typeValue)

    /**
     * Get the message status as enum.
     */
    val status: MessageStatus
        get() = MessageStatus.fromString(statusValue)

    /**
     * Set the message status.
     */
    internal fun setStatus(value: MessageStatus) {
        statusValue = value.toApiString()
    }

    /**
     * Marks the message as read if currently unread.
     * Sets readAt timestamp to now.
     */
    fun markAsRead(): MessageEntity {
        if (status == MessageStatus.UNREAD) {
            setStatus(MessageStatus.READ)
            readAt = Instant.now()
        }
        return this
    }

    /**
     * Marks the message as actioned with the given result.
     * Sets actionedAt timestamp and readAt if not already set.
     */
    fun markAsActioned(result: String): MessageEntity {
        setStatus(MessageStatus.ACTIONED)
        actionedAt = Instant.now()
        actionResult = result
        if (readAt == null) {
            readAt = Instant.now()
        }
        return this
    }

    /**
     * Dismisses the message.
     * Sets readAt timestamp if not already set.
     */
    fun dismiss(): MessageEntity {
        setStatus(MessageStatus.DISMISSED)
        if (readAt == null) {
            readAt = Instant.now()
        }
        return this
    }
}
