package com.munserv.messages.domain

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
    @Query(
        value = """
        SELECT * FROM messages m
        WHERE m.recipient_id = :recipientId
        AND m.recipient_type = :recipientType
        AND m.status = CAST(:status AS message_status)
        ORDER BY m.created_at DESC
        """,
        countQuery = """
        SELECT COUNT(*) FROM messages m
        WHERE m.recipient_id = :recipientId
        AND m.recipient_type = :recipientType
        AND m.status = CAST(:status AS message_status)
        """,
        nativeQuery = true,
    )
    fun findByRecipientIdAndRecipientTypeAndStatus(
        recipientId: UUID,
        recipientType: String,
        status: String,
        pageable: Pageable,
    ): Page<MessageEntity>

    /**
     * Find messages by recipient filtered by message type.
     */
    @Query(
        value = """
        SELECT * FROM messages m
        WHERE m.recipient_id = :recipientId
        AND m.recipient_type = :recipientType
        AND m.type = CAST(:type AS message_type)
        ORDER BY m.created_at DESC
        """,
        countQuery = """
        SELECT COUNT(*) FROM messages m
        WHERE m.recipient_id = :recipientId
        AND m.recipient_type = :recipientType
        AND m.type = CAST(:type AS message_type)
        """,
        nativeQuery = true,
    )
    fun findByRecipientIdAndRecipientTypeAndType(
        recipientId: UUID,
        recipientType: String,
        type: String,
        pageable: Pageable,
    ): Page<MessageEntity>

    /**
     * Find messages by recipient filtered by both status and type.
     */
    @Query(
        value = """
        SELECT * FROM messages m
        WHERE m.recipient_id = :recipientId
        AND m.recipient_type = :recipientType
        AND m.status = CAST(:status AS message_status)
        AND m.type = CAST(:type AS message_type)
        ORDER BY m.created_at DESC
        """,
        countQuery = """
        SELECT COUNT(*) FROM messages m
        WHERE m.recipient_id = :recipientId
        AND m.recipient_type = :recipientType
        AND m.status = CAST(:status AS message_status)
        AND m.type = CAST(:type AS message_type)
        """,
        nativeQuery = true,
    )
    fun findByRecipientIdAndRecipientTypeAndStatusAndType(
        recipientId: UUID,
        recipientType: String,
        status: String,
        type: String,
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
        AND m.statusValue = 'unread'
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
