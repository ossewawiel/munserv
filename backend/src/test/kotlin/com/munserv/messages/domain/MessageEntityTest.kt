package com.munserv.messages.domain

import com.munserv.shared.enums.MessageStatus
import com.munserv.shared.enums.MessageType
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import java.time.Instant
import java.util.UUID

class MessageEntityTest {
    private val recipientId = UUID.randomUUID()
    private val senderId = UUID.randomUUID()

    private fun createTestMessage(
        status: MessageStatus = MessageStatus.UNREAD,
        actionType: String? = "accept_decline",
    ) = MessageEntity(
        id = UUID.randomUUID(),
        type = MessageType.GROUND_ADMIN_INVITATION,
        title = "Test Title",
        body = "Test Body",
        recipientId = recipientId,
        recipientType = "member",
        senderId = senderId,
        senderType = "admin",
        status = status,
        actionType = actionType,
        createdAt = Instant.now(),
    )

    @Nested
    inner class MarkAsRead {
        @Test
        fun `should transition UNREAD to READ`() {
            val message = createTestMessage(status = MessageStatus.UNREAD)

            val result = message.markAsRead()

            result.status shouldBe MessageStatus.READ
            result.readAt.shouldNotBeNull()
        }

        @Test
        fun `should not change status if already READ`() {
            val message = createTestMessage(status = MessageStatus.READ)
            val originalReadAt = Instant.now().minusSeconds(60)
            message.readAt = originalReadAt

            val result = message.markAsRead()

            result.status shouldBe MessageStatus.READ
            result.readAt shouldBe originalReadAt
        }

        @Test
        fun `should not change status if ACTIONED`() {
            val message = createTestMessage(status = MessageStatus.ACTIONED)

            val result = message.markAsRead()

            result.status shouldBe MessageStatus.ACTIONED
        }
    }

    @Nested
    inner class MarkAsActioned {
        @Test
        fun `should transition to ACTIONED with result`() {
            val message = createTestMessage(status = MessageStatus.UNREAD)

            val result = message.markAsActioned("accept")

            result.status shouldBe MessageStatus.ACTIONED
            result.actionResult shouldBe "accept"
            result.actionedAt.shouldNotBeNull()
            result.readAt.shouldNotBeNull()
        }

        @Test
        fun `should set readAt if not already read`() {
            val message = createTestMessage(status = MessageStatus.UNREAD)
            message.readAt.shouldBeNull()

            val result = message.markAsActioned("decline")

            result.readAt.shouldNotBeNull()
        }

        @Test
        fun `should preserve existing readAt`() {
            val message = createTestMessage(status = MessageStatus.READ)
            val originalReadAt = Instant.now().minusSeconds(60)
            message.readAt = originalReadAt

            val result = message.markAsActioned("accept")

            result.readAt shouldBe originalReadAt
        }
    }

    @Nested
    inner class Dismiss {
        @Test
        fun `should transition to DISMISSED`() {
            val message = createTestMessage(status = MessageStatus.UNREAD)

            val result = message.dismiss()

            result.status shouldBe MessageStatus.DISMISSED
            result.readAt.shouldNotBeNull()
        }

        @Test
        fun `should preserve existing readAt`() {
            val message = createTestMessage(status = MessageStatus.READ)
            val originalReadAt = Instant.now().minusSeconds(60)
            message.readAt = originalReadAt

            val result = message.dismiss()

            result.status shouldBe MessageStatus.DISMISSED
            result.readAt shouldBe originalReadAt
        }
    }

    @Nested
    inner class EntityCreation {
        @Test
        fun `should create with default values`() {
            val message =
                MessageEntity(
                    type = MessageType.GROUND_ADMIN_INVITATION,
                    title = "Title",
                    body = "Body",
                    recipientId = recipientId,
                    recipientType = "member",
                )

            message.id.shouldNotBeNull()
            message.status shouldBe MessageStatus.UNREAD
            message.readAt.shouldBeNull()
            message.actionedAt.shouldBeNull()
            message.createdAt.shouldNotBeNull()
        }

        @Test
        fun `should support all optional fields`() {
            val relatedId = UUID.randomUUID()
            val expiresAt = Instant.now().plusSeconds(3600)

            val message =
                MessageEntity(
                    type = MessageType.VERIFY_NEW_ISSUE,
                    title = "Verify Issue",
                    body = "Please verify",
                    recipientId = recipientId,
                    recipientType = "member",
                    senderId = senderId,
                    senderType = "system",
                    actionType = "confirm_verify",
                    relatedEntityId = relatedId,
                    relatedEntityType = "issue",
                    metadata = """{"issueType": "pothole"}""",
                    expiresAt = expiresAt,
                )

            message.senderId shouldBe senderId
            message.senderType shouldBe "system"
            message.actionType shouldBe "confirm_verify"
            message.relatedEntityId shouldBe relatedId
            message.relatedEntityType shouldBe "issue"
            message.metadata shouldBe """{"issueType": "pothole"}"""
            message.expiresAt shouldBe expiresAt
        }
    }
}
