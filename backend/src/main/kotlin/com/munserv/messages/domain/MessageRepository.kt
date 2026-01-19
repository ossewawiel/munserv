package com.munserv.messages.domain

import com.munserv.shared.enums.MessageStatus
import com.munserv.shared.enums.MessageType
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import java.util.UUID

/**
 * Repository for message persistence operations.
 */
@Repository
interface MessageRepository : JpaRepository<MessageEntity, UUID> {
    /**
     * Find all messages for a recipient with pagination.
     */
    fun findByRecipientIdAndRecipientType(
        recipientId: UUID,
        recipientType: String,
        pageable: Pageable,
    ): Page<MessageEntity>

    /**
     * Find messages by recipient filtered by status.
     */
    fun findByRecipientIdAndRecipientTypeAndStatus(
        recipientId: UUID,
        recipientType: String,
        status: MessageStatus,
        pageable: Pageable,
    ): Page<MessageEntity>

    /**
     * Find messages by recipient filtered by message type.
     */
    fun findByRecipientIdAndRecipientTypeAndType(
        recipientId: UUID,
        recipientType: String,
        type: MessageType,
        pageable: Pageable,
    ): Page<MessageEntity>

    /**
     * Find messages by recipient filtered by both status and type.
     */
    fun findByRecipientIdAndRecipientTypeAndStatusAndType(
        recipientId: UUID,
        recipientType: String,
        status: MessageStatus,
        type: MessageType,
        pageable: Pageable,
    ): Page<MessageEntity>

    /**
     * Count unread messages for a recipient.
     */
    @Query(
        """
        SELECT COUNT(m) FROM MessageEntity m
        WHERE m.recipientId = :recipientId
        AND m.recipientType = :recipientType
        AND m.status = 'UNREAD'
        """,
    )
    fun countUnread(
        recipientId: UUID,
        recipientType: String,
    ): Long

    /**
     * Find messages related to a specific entity (e.g., issue, application).
     */
    fun findByRelatedEntityIdAndRelatedEntityType(
        relatedEntityId: UUID,
        relatedEntityType: String,
    ): List<MessageEntity>
}
