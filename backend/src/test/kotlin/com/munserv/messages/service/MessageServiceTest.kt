package com.munserv.messages.service

import com.munserv.groundadmin.domain.GroundAdminApplicationId
import com.munserv.groundadmin.service.GroundAdminResult
import com.munserv.groundadmin.service.GroundAdminService
import com.munserv.messages.api.MessageActionRequest
import com.munserv.messages.domain.MessageEntity
import com.munserv.messages.domain.MessageRepository
import com.munserv.shared.enums.MessageStatus
import com.munserv.shared.enums.MessageType
import com.munserv.shared.types.MemberId
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.clearAllMocks
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.springframework.data.domain.PageImpl
import org.springframework.data.domain.Pageable
import java.time.Instant
import java.util.Optional
import java.util.UUID

class MessageServiceTest {
    private lateinit var repository: MessageRepository
    private lateinit var groundAdminService: GroundAdminService
    private lateinit var service: MessageService

    private val recipientId = UUID.randomUUID()
    private val recipientType = "member"

    @BeforeEach
    fun setup() {
        clearAllMocks()
        repository = mockk()
        groundAdminService = mockk()
        service = MessageService(repository, groundAdminService)
    }

    private fun createTestMessage(
        id: UUID = UUID.randomUUID(),
        status: MessageStatus = MessageStatus.UNREAD,
        actionType: String? = "accept_decline",
        type: MessageType = MessageType.GROUND_ADMIN_INVITATION,
        relatedEntityId: UUID? = null,
    ) = MessageEntity(
        id = id,
        type = type,
        title = "Test Title",
        body = "Test Body",
        recipientId = recipientId,
        recipientType = recipientType,
        senderId = UUID.randomUUID(),
        senderType = "admin",
        status = status,
        actionType = actionType,
        relatedEntityId = relatedEntityId,
        relatedEntityType = if (type == MessageType.GROUND_ADMIN_INVITATION) "ground_admin_application" else null,
        createdAt = Instant.now(),
    )

    @Nested
    inner class GetMessages {
        @Test
        fun `should return paginated messages with unread count`() {
            val message = createTestMessage()

            every {
                repository.findByRecipientIdAndRecipientType(recipientId, recipientType, any<Pageable>())
            } returns PageImpl(listOf(message))
            every { repository.countUnread(recipientId, recipientType) } returns 1

            val result = service.getMessages(recipientId, recipientType)

            result.items.size shouldBe 1
            result.unreadCount shouldBe 1
            result.page shouldBe 1
        }

        @Test
        fun `should filter by status when provided`() {
            val message = createTestMessage(status = MessageStatus.UNREAD)

            every {
                repository.findByRecipientIdAndRecipientTypeAndStatus(
                    recipientId,
                    recipientType,
                    "unread",
                    any<Pageable>(),
                )
            } returns PageImpl(listOf(message))
            every { repository.countUnread(recipientId, recipientType) } returns 1

            val result =
                service.getMessages(
                    recipientId = recipientId,
                    recipientType = recipientType,
                    status = MessageStatus.UNREAD,
                )

            result.items.size shouldBe 1
            verify {
                repository.findByRecipientIdAndRecipientTypeAndStatus(
                    recipientId,
                    recipientType,
                    "unread",
                    any<Pageable>(),
                )
            }
        }

        @Test
        fun `should filter by type when provided`() {
            val message = createTestMessage()

            every {
                repository.findByRecipientIdAndRecipientTypeAndType(
                    recipientId,
                    recipientType,
                    "ground_admin_invitation",
                    any<Pageable>(),
                )
            } returns PageImpl(listOf(message))
            every { repository.countUnread(recipientId, recipientType) } returns 0

            val result =
                service.getMessages(
                    recipientId = recipientId,
                    recipientType = recipientType,
                    type = MessageType.GROUND_ADMIN_INVITATION,
                )

            result.items.size shouldBe 1
        }

        @Test
        fun `should filter by both status and type when provided`() {
            val message = createTestMessage()

            every {
                repository.findByRecipientIdAndRecipientTypeAndStatusAndType(
                    recipientId,
                    recipientType,
                    "unread",
                    "ground_admin_invitation",
                    any<Pageable>(),
                )
            } returns PageImpl(listOf(message))
            every { repository.countUnread(recipientId, recipientType) } returns 1

            val result =
                service.getMessages(
                    recipientId = recipientId,
                    recipientType = recipientType,
                    status = MessageStatus.UNREAD,
                    type = MessageType.GROUND_ADMIN_INVITATION,
                )

            result.items.size shouldBe 1
        }
    }

    @Nested
    inner class GetMessage {
        @Test
        fun `should return Success when message exists and recipient matches`() {
            val message = createTestMessage()

            every { repository.findById(message.id) } returns Optional.of(message)

            val result = service.getMessage(message.id, recipientId, recipientType)

            val success = result.shouldBeInstanceOf<MessageResult.Success>()
            success.message.id shouldBe message.id.toString()
        }

        @Test
        fun `should return NotFound when message does not exist`() {
            val id = UUID.randomUUID()

            every { repository.findById(id) } returns Optional.empty()

            val result = service.getMessage(id, recipientId, recipientType)

            result.shouldBeInstanceOf<MessageResult.NotFound>()
        }

        @Test
        fun `should return NotFound when recipient does not match`() {
            val message = createTestMessage()
            val wrongRecipientId = UUID.randomUUID()

            every { repository.findById(message.id) } returns Optional.of(message)

            val result = service.getMessage(message.id, wrongRecipientId, recipientType)

            result.shouldBeInstanceOf<MessageResult.NotFound>()
        }

        @Test
        fun `should return NotFound when recipient type does not match`() {
            val message = createTestMessage()

            every { repository.findById(message.id) } returns Optional.of(message)

            val result = service.getMessage(message.id, recipientId, "admin")

            result.shouldBeInstanceOf<MessageResult.NotFound>()
        }
    }

    @Nested
    inner class MarkAsRead {
        @Test
        fun `should return Success when message is marked as read`() {
            val message = createTestMessage(status = MessageStatus.UNREAD)

            every { repository.findById(message.id) } returns Optional.of(message)
            every { repository.save(any()) } answers { firstArg() }

            val result = service.markAsRead(message.id, recipientId, recipientType)

            val success = result.shouldBeInstanceOf<MessageResult.Success>()
            success.message.status shouldBe MessageStatus.READ
        }

        @Test
        fun `should return NotFound when message does not exist`() {
            val id = UUID.randomUUID()

            every { repository.findById(id) } returns Optional.empty()

            val result = service.markAsRead(id, recipientId, recipientType)

            result.shouldBeInstanceOf<MessageResult.NotFound>()
        }

        @Test
        fun `should return NotFound when recipient does not match`() {
            val message = createTestMessage()
            val wrongRecipientId = UUID.randomUUID()

            every { repository.findById(message.id) } returns Optional.of(message)

            val result = service.markAsRead(message.id, wrongRecipientId, recipientType)

            result.shouldBeInstanceOf<MessageResult.NotFound>()
        }
    }

    @Nested
    inner class PerformAction {
        @Test
        fun `should mark message as actioned with valid action`() {
            // Use a non-GA invitation message to test basic action flow
            val message =
                createTestMessage(
                    type = MessageType.MONTHLY_REPORT,
                    actionType = "accept_decline",
                )

            every { repository.findById(message.id) } returns Optional.of(message)
            every { repository.save(any()) } answers { firstArg() }

            val result =
                service.performAction(
                    message.id,
                    recipientId,
                    recipientType,
                    MessageActionRequest("accept"),
                )

            val success = result.shouldBeInstanceOf<MessageResult.Success>()
            success.message.status shouldBe MessageStatus.ACTIONED
            success.message.actionResult shouldBe "accept"
        }

        @Test
        fun `should return NotFound when message does not exist`() {
            val id = UUID.randomUUID()

            every { repository.findById(id) } returns Optional.empty()

            val result =
                service.performAction(
                    id,
                    recipientId,
                    recipientType,
                    MessageActionRequest("accept"),
                )

            result.shouldBeInstanceOf<MessageResult.NotFound>()
        }

        @Test
        fun `should return NotFound when recipient does not match`() {
            val message = createTestMessage()
            val wrongRecipientId = UUID.randomUUID()

            every { repository.findById(message.id) } returns Optional.of(message)

            val result =
                service.performAction(
                    message.id,
                    wrongRecipientId,
                    recipientType,
                    MessageActionRequest("accept"),
                )

            result.shouldBeInstanceOf<MessageResult.NotFound>()
        }

        @Test
        fun `should return Conflict when message already actioned`() {
            val message = createTestMessage(status = MessageStatus.ACTIONED)
            message.markAsActioned("accept")

            every { repository.findById(message.id) } returns Optional.of(message)

            val result =
                service.performAction(
                    message.id,
                    recipientId,
                    recipientType,
                    MessageActionRequest("decline"),
                )

            result.shouldBeInstanceOf<MessageResult.Conflict>()
        }

        @Test
        fun `should return ValidationError for invalid action`() {
            val message = createTestMessage(actionType = "accept_decline")

            every { repository.findById(message.id) } returns Optional.of(message)

            val result =
                service.performAction(
                    message.id,
                    recipientId,
                    recipientType,
                    MessageActionRequest("invalid_action"),
                )

            result.shouldBeInstanceOf<MessageResult.ValidationError>()
        }

        @Test
        fun `should accept 'approve' for approve_reject action type`() {
            // Use GA application type (not invitation) which uses approve_reject
            val message =
                createTestMessage(
                    type = MessageType.GROUND_ADMIN_APPLICATION,
                    actionType = "approve_reject",
                )

            every { repository.findById(message.id) } returns Optional.of(message)
            every { repository.save(any()) } answers { firstArg() }

            val result =
                service.performAction(
                    message.id,
                    recipientId,
                    recipientType,
                    MessageActionRequest("approve"),
                )

            val success = result.shouldBeInstanceOf<MessageResult.Success>()
            success.message.actionResult shouldBe "approve"
        }

        @Test
        fun `should accept 'confirm' for confirm_verify action type`() {
            val message =
                createTestMessage(
                    type = MessageType.VERIFY_NEW_ISSUE,
                    actionType = "confirm_verify",
                )

            every { repository.findById(message.id) } returns Optional.of(message)
            every { repository.save(any()) } answers { firstArg() }

            val result =
                service.performAction(
                    message.id,
                    recipientId,
                    recipientType,
                    MessageActionRequest("confirm"),
                )

            result.shouldBeInstanceOf<MessageResult.Success>()
        }

        @Test
        fun `should accept 'dismiss' for acknowledge action type`() {
            val message =
                createTestMessage(
                    type = MessageType.GROUND_ADMIN_APPROVED,
                    actionType = "acknowledge",
                )

            every { repository.findById(message.id) } returns Optional.of(message)
            every { repository.save(any()) } answers { firstArg() }

            val result =
                service.performAction(
                    message.id,
                    recipientId,
                    recipientType,
                    MessageActionRequest("dismiss"),
                )

            result.shouldBeInstanceOf<MessageResult.Success>()
        }

        @Test
        fun `should accept 'dismiss' for view action type`() {
            val message =
                createTestMessage(
                    type = MessageType.MONTHLY_REPORT,
                    actionType = "view",
                )

            every { repository.findById(message.id) } returns Optional.of(message)
            every { repository.save(any()) } answers { firstArg() }

            val result =
                service.performAction(
                    message.id,
                    recipientId,
                    recipientType,
                    MessageActionRequest("dismiss"),
                )

            result.shouldBeInstanceOf<MessageResult.Success>()
        }

        @Test
        fun `should call GroundAdminService acceptInvitation when accepting GA invitation`() {
            val applicationId = UUID.randomUUID()
            val message =
                createTestMessage(
                    type = MessageType.GROUND_ADMIN_INVITATION,
                    actionType = "accept_decline",
                    relatedEntityId = applicationId,
                )

            every { repository.findById(message.id) } returns Optional.of(message)
            every { repository.save(any()) } answers { firstArg() }
            every {
                groundAdminService.acceptInvitation(
                    MemberId(recipientId),
                    GroundAdminApplicationId(applicationId),
                )
            } returns GroundAdminResult.Success(mapOf("status" to "accepted"))

            val result =
                service.performAction(
                    message.id,
                    recipientId,
                    recipientType,
                    MessageActionRequest("accept"),
                )

            val success = result.shouldBeInstanceOf<MessageResult.Success>()
            success.message.status shouldBe MessageStatus.ACTIONED
            success.message.actionResult shouldBe "accept"
            verify {
                groundAdminService.acceptInvitation(
                    MemberId(recipientId),
                    GroundAdminApplicationId(applicationId),
                )
            }
        }

        @Test
        fun `should call GroundAdminService declineInvitation when declining GA invitation`() {
            val applicationId = UUID.randomUUID()
            val message =
                createTestMessage(
                    type = MessageType.GROUND_ADMIN_INVITATION,
                    actionType = "accept_decline",
                    relatedEntityId = applicationId,
                )

            every { repository.findById(message.id) } returns Optional.of(message)
            every { repository.save(any()) } answers { firstArg() }
            every {
                groundAdminService.declineInvitation(
                    MemberId(recipientId),
                    GroundAdminApplicationId(applicationId),
                    null,
                )
            } returns GroundAdminResult.Success(mapOf("status" to "declined"))

            val result =
                service.performAction(
                    message.id,
                    recipientId,
                    recipientType,
                    MessageActionRequest("decline"),
                )

            val success = result.shouldBeInstanceOf<MessageResult.Success>()
            success.message.status shouldBe MessageStatus.ACTIONED
            success.message.actionResult shouldBe "decline"
            verify {
                groundAdminService.declineInvitation(
                    MemberId(recipientId),
                    GroundAdminApplicationId(applicationId),
                    null,
                )
            }
        }

        @Test
        fun `should return ValidationError when GA invitation has no relatedEntityId`() {
            val message =
                createTestMessage(
                    type = MessageType.GROUND_ADMIN_INVITATION,
                    actionType = "accept_decline",
                    relatedEntityId = null,
                )

            every { repository.findById(message.id) } returns Optional.of(message)

            val result =
                service.performAction(
                    message.id,
                    recipientId,
                    recipientType,
                    MessageActionRequest("accept"),
                )

            val error = result.shouldBeInstanceOf<MessageResult.ValidationError>()
            error.errors.first() shouldBe "Missing application ID"
        }

        @Test
        fun `should return NotFound when GroundAdminService returns NotFound`() {
            val applicationId = UUID.randomUUID()
            val message =
                createTestMessage(
                    type = MessageType.GROUND_ADMIN_INVITATION,
                    actionType = "accept_decline",
                    relatedEntityId = applicationId,
                )

            every { repository.findById(message.id) } returns Optional.of(message)
            every {
                groundAdminService.acceptInvitation(
                    MemberId(recipientId),
                    GroundAdminApplicationId(applicationId),
                )
            } returns GroundAdminResult.NotFound("Application not found")

            val result =
                service.performAction(
                    message.id,
                    recipientId,
                    recipientType,
                    MessageActionRequest("accept"),
                )

            val notFound = result.shouldBeInstanceOf<MessageResult.NotFound>()
            notFound.reason shouldBe "Application not found"
        }

        @Test
        fun `should return Conflict when GroundAdminService returns Conflict`() {
            val applicationId = UUID.randomUUID()
            val message =
                createTestMessage(
                    type = MessageType.GROUND_ADMIN_INVITATION,
                    actionType = "accept_decline",
                    relatedEntityId = applicationId,
                )

            every { repository.findById(message.id) } returns Optional.of(message)
            every {
                groundAdminService.acceptInvitation(
                    MemberId(recipientId),
                    GroundAdminApplicationId(applicationId),
                )
            } returns GroundAdminResult.Conflict("Invitation already processed")

            val result =
                service.performAction(
                    message.id,
                    recipientId,
                    recipientType,
                    MessageActionRequest("accept"),
                )

            val conflict = result.shouldBeInstanceOf<MessageResult.Conflict>()
            conflict.reason shouldBe "Invitation already processed"
        }

        @Test
        fun `should not call GroundAdminService for non-GA invitation messages`() {
            val message =
                createTestMessage(
                    type = MessageType.VERIFY_NEW_ISSUE,
                    actionType = "confirm_verify",
                )

            every { repository.findById(message.id) } returns Optional.of(message)
            every { repository.save(any()) } answers { firstArg() }

            val result =
                service.performAction(
                    message.id,
                    recipientId,
                    recipientType,
                    MessageActionRequest("confirm"),
                )

            result.shouldBeInstanceOf<MessageResult.Success>()
            verify(exactly = 0) { groundAdminService.acceptInvitation(any(), any()) }
            verify(exactly = 0) { groundAdminService.declineInvitation(any(), any(), any()) }
        }
    }

    @Nested
    inner class CreateMessage {
        @Test
        fun `should save and return message`() {
            val message = createTestMessage()

            every { repository.save(any()) } returns message

            val result = service.createMessage(message)

            result.id shouldBe message.id
            verify { repository.save(message) }
        }
    }

    @Nested
    inner class CreateMessagesForRecipients {
        @Test
        fun `should create message for each recipient`() {
            val recipientIds = listOf(UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID())

            every { repository.save(any()) } answers { firstArg() }

            val results =
                service.createMessagesForRecipients(
                    recipientIds = recipientIds,
                    recipientType = "member",
                ) { id ->
                    MessageEntity(
                        type = MessageType.VERIFY_NEW_ISSUE,
                        title = "Verify Issue",
                        body = "Please verify",
                        recipientId = id,
                        recipientType = "member",
                    )
                }

            results.size shouldBe 3
            verify(exactly = 3) { repository.save(any()) }
        }
    }

    @Nested
    inner class GetUnreadCount {
        @Test
        fun `should return unread count for recipient`() {
            every { repository.countUnread(recipientId, recipientType) } returns 5

            val result = service.getUnreadCount(recipientId, recipientType)

            result shouldBe 5
        }
    }
}
