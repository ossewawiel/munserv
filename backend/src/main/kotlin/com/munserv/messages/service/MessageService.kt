package com.munserv.messages.service

import com.munserv.groundadmin.domain.GroundAdminApplicationId
import com.munserv.groundadmin.service.GroundAdminResult
import com.munserv.groundadmin.service.GroundAdminService
import com.munserv.messages.api.MessageActionRequest
import com.munserv.messages.api.MessageListResponse
import com.munserv.messages.api.MessageResponse
import com.munserv.messages.domain.MessageEntity
import com.munserv.messages.domain.MessageRepository
import com.munserv.shared.enums.MessageStatus
import com.munserv.shared.enums.MessageType
import com.munserv.shared.types.MemberId
import org.springframework.context.annotation.Lazy
import org.springframework.data.domain.PageRequest
import org.springframework.data.domain.Sort
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.UUID

/**
 * Service for managing messages.
 *
 * Handles message retrieval, status updates, and action processing.
 * Uses sealed Result pattern for error handling.
 */
@Service
class MessageService(
    private val messageRepository: MessageRepository,
    @Lazy private val groundAdminService: GroundAdminService,
) {
    companion object {
        private const val MESSAGE_NOT_FOUND = "Message not found"
    }

    /**
     * Retrieves paginated messages for a recipient with optional filtering.
     */
    fun getMessages(
        recipientId: UUID,
        recipientType: String,
        status: MessageStatus? = null,
        type: MessageType? = null,
        page: Int = 1,
        size: Int = 20,
    ): MessageListResponse {
        // Native queries have ORDER BY in SQL, so don't add sort to pageable
        val nativePageable = PageRequest.of(page - 1, size)
        // JPA-derived queries need sort in pageable
        val jpaPageable =
            PageRequest.of(
                page - 1,
                size,
                Sort.by(Sort.Direction.DESC, "createdAt"),
            )

        val messagePage =
            when {
                status != null && type != null ->
                    messageRepository.findByRecipientIdAndRecipientTypeAndStatusAndType(
                        recipientId,
                        recipientType,
                        status.toApiString(),
                        type.toApiString(),
                        nativePageable,
                    )
                status != null ->
                    messageRepository.findByRecipientIdAndRecipientTypeAndStatus(
                        recipientId,
                        recipientType,
                        status.toApiString(),
                        nativePageable,
                    )
                type != null ->
                    messageRepository.findByRecipientIdAndRecipientTypeAndType(
                        recipientId,
                        recipientType,
                        type.toApiString(),
                        nativePageable,
                    )
                else ->
                    messageRepository.findByRecipientIdAndRecipientType(
                        recipientId,
                        recipientType,
                        jpaPageable,
                    )
            }

        val unreadCount = messageRepository.countUnread(recipientId, recipientType)

        return MessageListResponse(
            items = messagePage.content.map { MessageResponse.from(it) },
            total = messagePage.totalElements,
            page = page,
            unreadCount = unreadCount,
        )
    }

    /**
     * Retrieves a single message by ID, verifying recipient access.
     */
    fun getMessage(
        id: UUID,
        recipientId: UUID,
        recipientType: String,
    ): MessageResult {
        val message =
            messageRepository.findById(id).orElse(null)
                ?: return MessageResult.NotFound(MESSAGE_NOT_FOUND)

        if (message.recipientId != recipientId || message.recipientType != recipientType) {
            return MessageResult.NotFound(MESSAGE_NOT_FOUND)
        }

        return MessageResult.Success(MessageResponse.from(message))
    }

    /**
     * Marks a message as read.
     */
    @Transactional
    fun markAsRead(
        id: UUID,
        recipientId: UUID,
        recipientType: String,
    ): MessageResult {
        val message =
            messageRepository.findById(id).orElse(null)
                ?: return MessageResult.NotFound(MESSAGE_NOT_FOUND)

        if (message.recipientId != recipientId || message.recipientType != recipientType) {
            return MessageResult.NotFound(MESSAGE_NOT_FOUND)
        }

        message.markAsRead()
        val saved = messageRepository.save(message)
        return MessageResult.Success(MessageResponse.from(saved))
    }

    /**
     * Performs an action on a message.
     *
     * Validates that:
     * - Message exists and recipient has access
     * - Message hasn't already been actioned
     * - Action is valid for the message's action type
     *
     * For Ground Admin invitation messages, delegates to GroundAdminService
     * to process the acceptance/decline before marking the message as actioned.
     */
    @Transactional
    fun performAction(
        id: UUID,
        recipientId: UUID,
        recipientType: String,
        request: MessageActionRequest,
    ): MessageResult {
        val message =
            messageRepository.findById(id).orElse(null)
                ?: return MessageResult.NotFound(MESSAGE_NOT_FOUND)

        if (message.recipientId != recipientId || message.recipientType != recipientType) {
            return MessageResult.NotFound(MESSAGE_NOT_FOUND)
        }

        if (message.status == MessageStatus.ACTIONED) {
            return MessageResult.Conflict("Message already actioned")
        }

        if (!isValidAction(message.actionType, request.action)) {
            return MessageResult.ValidationError(listOf("Invalid action: ${request.action}"))
        }

        // Handle Ground Admin invitation actions
        if (message.type == MessageType.GROUND_ADMIN_INVITATION) {
            val applicationId =
                message.relatedEntityId
                    ?: return MessageResult.ValidationError(listOf("Missing application ID"))

            val gaResult =
                when (request.action) {
                    "accept" ->
                        groundAdminService.acceptInvitation(
                            MemberId(recipientId),
                            GroundAdminApplicationId(applicationId),
                        )
                    "decline" ->
                        groundAdminService.declineInvitation(
                            MemberId(recipientId),
                            GroundAdminApplicationId(applicationId),
                            request.note,
                        )
                    else -> return MessageResult.ValidationError(listOf("Invalid action for invitation"))
                }

            // Map GroundAdminResult to MessageResult if failed
            if (gaResult !is GroundAdminResult.Success) {
                return when (gaResult) {
                    is GroundAdminResult.NotFound -> MessageResult.NotFound(gaResult.message)
                    is GroundAdminResult.Conflict -> MessageResult.Conflict(gaResult.message)
                    is GroundAdminResult.ValidationError -> MessageResult.ValidationError(gaResult.errors)
                    is GroundAdminResult.Forbidden -> MessageResult.ValidationError(listOf(gaResult.message))
                    else -> MessageResult.ValidationError(listOf("Failed to process invitation"))
                }
            }
        }

        message.markAsActioned(request.action)
        val saved = messageRepository.save(message)

        return MessageResult.Success(MessageResponse.from(saved))
    }

    /**
     * Creates and saves a new message.
     */
    @Transactional
    fun createMessage(message: MessageEntity): MessageEntity {
        return messageRepository.save(message)
    }

    /**
     * Creates messages for multiple recipients.
     *
     * @param recipientIds List of recipient IDs
     * @param recipientType Type of recipients (member/admin)
     * @param messageBuilder Function to create a message for each recipient
     */
    @Transactional
    fun createMessagesForRecipients(
        recipientIds: List<UUID>,
        recipientType: String,
        messageBuilder: (UUID) -> MessageEntity,
    ): List<MessageEntity> {
        return recipientIds.map { recipientId ->
            val message = messageBuilder(recipientId)
            messageRepository.save(message)
        }
    }

    /**
     * Gets the count of unread messages for a recipient.
     */
    fun getUnreadCount(
        recipientId: UUID,
        recipientType: String,
    ): Long {
        return messageRepository.countUnread(recipientId, recipientType)
    }

    /**
     * Validates that an action is allowed for a given action type.
     */
    private fun isValidAction(
        actionType: String?,
        action: String,
    ): Boolean {
        return when (actionType) {
            "accept_decline" -> action in listOf("accept", "decline")
            "approve_reject" -> action in listOf("approve", "reject")
            "confirm_verify" -> action in listOf("confirm", "cannot_verify")
            "acknowledge" -> action in listOf("dismiss", "acknowledge")
            "view" -> action in listOf("dismiss")
            else -> false
        }
    }
}
