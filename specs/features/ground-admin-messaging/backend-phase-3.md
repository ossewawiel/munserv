# Ground Admin & Messaging - Backend Phase 3: Messaging Service

## Status: ✅ COMPLETED

**Completed:** 2026-01-19

## Overview

Implement the generic messaging service that handles all platform communications. This is a foundational component used by Ground Admin lifecycle, verification workflows, and system notifications.

## Prerequisites

- Phase 1 complete (all migrations applied)
- `messages` table exists
- `message_type` and `message_status` enums exist

---

## Task List

### 3.1 Create Message Entity

**File:** `src/main/kotlin/com/munserv/messages/domain/MessageEntity.kt`

```kotlin
package com.munserv.messages.domain

import com.munserv.shared.enums.MessageType
import com.munserv.shared.enums.MessageStatus
import jakarta.persistence.*
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "messages")
class MessageEntity(
    @Id
    val id: UUID = UUID.randomUUID(),

    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false)
    val type: MessageType,

    @Column(name = "title", nullable = false, length = 200)
    val title: String,

    @Column(name = "body", nullable = false, columnDefinition = "TEXT")
    val body: String,

    @Column(name = "recipient_id", nullable = false)
    val recipientId: UUID,

    @Column(name = "recipient_type", nullable = false, length = 20)
    val recipientType: String, // "member" or "admin"

    @Column(name = "sender_id")
    val senderId: UUID? = null,

    @Column(name = "sender_type", length = 20)
    val senderType: String? = null, // "member", "admin", "system"

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    var status: MessageStatus = MessageStatus.UNREAD,

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
    val metadata: String? = null, // JSON string

    @Column(name = "created_at", nullable = false)
    val createdAt: Instant = Instant.now(),

    @Column(name = "expires_at")
    val expiresAt: Instant? = null
) {
    fun markAsRead(): MessageEntity {
        if (status == MessageStatus.UNREAD) {
            status = MessageStatus.READ
            readAt = Instant.now()
        }
        return this
    }

    fun markAsActioned(result: String): MessageEntity {
        status = MessageStatus.ACTIONED
        actionedAt = Instant.now()
        actionResult = result
        if (readAt == null) {
            readAt = Instant.now()
        }
        return this
    }

    fun dismiss(): MessageEntity {
        status = MessageStatus.DISMISSED
        if (readAt == null) {
            readAt = Instant.now()
        }
        return this
    }
}
```

---

### 3.2 Create Message Repository

**File:** `src/main/kotlin/com/munserv/messages/domain/MessageRepository.kt`

```kotlin
package com.munserv.messages.domain

import com.munserv.shared.enums.MessageStatus
import com.munserv.shared.enums.MessageType
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import java.util.UUID

@Repository
interface MessageRepository : JpaRepository<MessageEntity, UUID> {
    
    fun findByRecipientIdAndRecipientType(
        recipientId: UUID,
        recipientType: String,
        pageable: Pageable
    ): Page<MessageEntity>

    fun findByRecipientIdAndRecipientTypeAndStatus(
        recipientId: UUID,
        recipientType: String,
        status: MessageStatus,
        pageable: Pageable
    ): Page<MessageEntity>

    fun findByRecipientIdAndRecipientTypeAndType(
        recipientId: UUID,
        recipientType: String,
        type: MessageType,
        pageable: Pageable
    ): Page<MessageEntity>

    fun findByRecipientIdAndRecipientTypeAndStatusAndType(
        recipientId: UUID,
        recipientType: String,
        status: MessageStatus,
        type: MessageType,
        pageable: Pageable
    ): Page<MessageEntity>

    @Query("""
        SELECT COUNT(m) FROM MessageEntity m 
        WHERE m.recipientId = :recipientId 
        AND m.recipientType = :recipientType 
        AND m.status = 'UNREAD'
    """)
    fun countUnread(recipientId: UUID, recipientType: String): Long

    fun findByRelatedEntityIdAndRelatedEntityType(
        relatedEntityId: UUID,
        relatedEntityType: String
    ): List<MessageEntity>
}
```

---

### 3.3 Create Message DTOs

**File:** `src/main/kotlin/com/munserv/messages/api/MessageDto.kt`

```kotlin
package com.munserv.messages.api

import com.munserv.messages.domain.MessageEntity
import com.munserv.shared.enums.MessageStatus
import com.munserv.shared.enums.MessageType
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import java.time.Instant

data class MessageResponse(
    val id: String,
    val type: MessageType,
    val title: String,
    val body: String,
    val recipientId: String,
    val recipientType: String,
    val senderId: String?,
    val senderType: String?,
    val status: MessageStatus,
    val actionType: String?,
    val relatedEntityId: String?,
    val relatedEntityType: String?,
    val actionResult: String?,
    val metadata: Map<String, Any>?,
    val createdAt: Instant,
    val readAt: Instant?,
    val actionedAt: Instant?,
    val expiresAt: Instant?
) {
    companion object {
        private val mapper = jacksonObjectMapper()

        fun from(entity: MessageEntity) = MessageResponse(
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
            metadata = entity.metadata?.let { 
                mapper.readValue(it, Map::class.java) as Map<String, Any> 
            },
            createdAt = entity.createdAt,
            readAt = entity.readAt,
            actionedAt = entity.actionedAt,
            expiresAt = entity.expiresAt
        )
    }
}

data class MessageListResponse(
    val items: List<MessageResponse>,
    val total: Long,
    val page: Int,
    val unreadCount: Long
)

data class MessageActionRequest(
    val action: String,
    val note: String? = null
)
```

---

### 3.4 Create Message Factory

**File:** `src/main/kotlin/com/munserv/messages/service/MessageFactory.kt`

```kotlin
package com.munserv.messages.service

import com.munserv.messages.domain.MessageEntity
import com.munserv.shared.enums.MessageType
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import java.util.UUID

/**
 * Factory for creating different types of messages with appropriate
 * titles, bodies, and action types.
 */
object MessageFactory {
    private val mapper = jacksonObjectMapper()

    // ============ Ground Admin Messages ============

    fun groundAdminInvitation(
        recipientId: UUID,
        invitedBy: UUID,
        inviterName: String,
        sectorName: String,
        customMessage: String? = null
    ) = MessageEntity(
        type = MessageType.GROUND_ADMIN_INVITATION,
        title = "Ground Admin Invitation",
        body = buildString {
            append("$inviterName has invited you to become a Ground Admin for $sectorName.")
            customMessage?.let { append("\n\nMessage: $it") }
        },
        recipientId = recipientId,
        recipientType = "member",
        senderId = invitedBy,
        senderType = "admin",
        actionType = "accept_decline",
        metadata = mapper.writeValueAsString(mapOf(
            "inviterName" to inviterName,
            "sectorName" to sectorName
        ))
    )

    fun groundAdminApplication(
        recipientId: UUID, // Sector admin/chief
        applicantId: UUID,
        applicantName: String,
        applicationId: UUID
    ) = MessageEntity(
        type = MessageType.GROUND_ADMIN_APPLICATION,
        title = "Ground Admin Application",
        body = "$applicantName has applied to become a Ground Admin in your sector.",
        recipientId = recipientId,
        recipientType = "admin",
        senderId = applicantId,
        senderType = "member",
        actionType = "approve_reject",
        relatedEntityId = applicationId,
        relatedEntityType = "ground_admin_application",
        metadata = mapper.writeValueAsString(mapOf(
            "applicantName" to applicantName,
            "applicantId" to applicantId.toString()
        ))
    )

    fun groundAdminApproved(
        recipientId: UUID
    ) = MessageEntity(
        type = MessageType.GROUND_ADMIN_APPROVED,
        title = "Application Approved!",
        body = "Congratulations! Your application to become a Ground Admin has been approved. You can now verify issues in your sector.",
        recipientId = recipientId,
        recipientType = "member",
        senderType = "system",
        actionType = "acknowledge"
    )

    fun groundAdminDeclined(
        recipientId: UUID,
        reason: String?
    ) = MessageEntity(
        type = MessageType.GROUND_ADMIN_DECLINED,
        title = "Application Status Update",
        body = buildString {
            append("Your Ground Admin application was not approved at this time.")
            reason?.let { append("\n\nReason: $it") }
        },
        recipientId = recipientId,
        recipientType = "member",
        senderType = "system",
        actionType = "acknowledge"
    )

    fun groundAdminInvitationDeclined(
        recipientId: UUID,
        memberName: String,
        reason: String?
    ) = MessageEntity(
        type = MessageType.GROUND_ADMIN_INVITATION_DECLINED,
        title = "Invitation Declined",
        body = buildString {
            append("$memberName has declined your Ground Admin invitation.")
            reason?.let { append("\n\nReason: $it") }
        },
        recipientId = recipientId,
        recipientType = "admin",
        senderType = "system",
        actionType = "acknowledge"
    )

    fun groundAdminRevocation(
        recipientId: UUID,
        reason: String
    ) = MessageEntity(
        type = MessageType.GROUND_ADMIN_REVOCATION,
        title = "Ground Admin Status Update",
        body = "Your Ground Admin status has been revoked.\n\nReason: $reason",
        recipientId = recipientId,
        recipientType = "member",
        senderType = "system",
        actionType = "acknowledge"
    )

    fun groundAdminStepdownRequest(
        recipientId: UUID,
        groundAdminId: UUID,
        groundAdminName: String,
        reason: String?
    ) = MessageEntity(
        type = MessageType.GROUND_ADMIN_STEPDOWN_REQUEST,
        title = "Step Down Request",
        body = buildString {
            append("$groundAdminName has requested to step down from their Ground Admin role.")
            reason?.let { append("\n\nReason: $it") }
        },
        recipientId = recipientId,
        recipientType = "admin",
        senderId = groundAdminId,
        senderType = "member",
        actionType = "approve_reject",
        relatedEntityId = groundAdminId,
        relatedEntityType = "member"
    )

    // ============ Verification Messages ============

    fun verifyNewIssue(
        recipientId: UUID,
        issueId: UUID,
        issueType: String,
        issueDescription: String?,
        verificationId: UUID
    ) = MessageEntity(
        type = MessageType.VERIFY_NEW_ISSUE,
        title = "Verify Issue: $issueType",
        body = buildString {
            append("A new $issueType has been reported and needs verification.")
            issueDescription?.let { append("\n\nDescription: $it") }
            append("\n\nPlease visit the location to confirm this issue exists.")
        },
        recipientId = recipientId,
        recipientType = "member",
        senderType = "system",
        actionType = "confirm_verify",
        relatedEntityId = issueId,
        relatedEntityType = "issue",
        metadata = mapper.writeValueAsString(mapOf(
            "verificationId" to verificationId.toString(),
            "issueType" to issueType
        ))
    )

    fun verifyFix(
        recipientId: UUID,
        issueId: UUID,
        issueType: String,
        verificationId: UUID
    ) = MessageEntity(
        type = MessageType.VERIFY_FIX,
        title = "Verify Fix: $issueType",
        body = "A $issueType has been marked as fixed. Please visit the location to verify the fix is complete.",
        recipientId = recipientId,
        recipientType = "member",
        senderType = "system",
        actionType = "confirm_verify",
        relatedEntityId = issueId,
        relatedEntityType = "issue",
        metadata = mapper.writeValueAsString(mapOf(
            "verificationId" to verificationId.toString(),
            "issueType" to issueType
        ))
    )

    // ============ System Messages ============

    fun memberRegistration(
        recipientId: UUID,
        memberId: UUID,
        memberName: String,
        memberPhone: String
    ) = MessageEntity(
        type = MessageType.MEMBER_REGISTRATION,
        title = "New Member Registration",
        body = "A new member has registered: $memberName ($memberPhone)",
        recipientId = recipientId,
        recipientType = "admin",
        senderType = "system",
        actionType = "approve_reject",
        relatedEntityId = memberId,
        relatedEntityType = "member"
    )

    fun monthlyReport(
        recipientId: UUID,
        reportMonth: String,
        summary: String
    ) = MessageEntity(
        type = MessageType.MONTHLY_REPORT,
        title = "Monthly Report: $reportMonth",
        body = summary,
        recipientId = recipientId,
        recipientType = "member",
        senderType = "system",
        actionType = "view"
    )
}
```

---

### 3.5 Create Message Service

**File:** `src/main/kotlin/com/munserv/messages/service/MessageService.kt`

```kotlin
package com.munserv.messages.service

import com.munserv.messages.api.MessageActionRequest
import com.munserv.messages.api.MessageListResponse
import com.munserv.messages.api.MessageResponse
import com.munserv.messages.domain.MessageEntity
import com.munserv.messages.domain.MessageRepository
import com.munserv.shared.enums.MessageStatus
import com.munserv.shared.enums.MessageType
import com.munserv.shared.result.Result
import com.munserv.shared.result.AppError
import org.springframework.data.domain.PageRequest
import org.springframework.data.domain.Sort
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.UUID

@Service
class MessageService(
    private val messageRepository: MessageRepository
) {
    fun getMessages(
        recipientId: UUID,
        recipientType: String,
        status: MessageStatus? = null,
        type: MessageType? = null,
        page: Int = 1,
        size: Int = 20
    ): MessageListResponse {
        val pageable = PageRequest.of(
            page - 1,
            size,
            Sort.by(Sort.Direction.DESC, "createdAt")
        )

        val messagePage = when {
            status != null && type != null -> messageRepository.findByRecipientIdAndRecipientTypeAndStatusAndType(
                recipientId, recipientType, status, type, pageable
            )
            status != null -> messageRepository.findByRecipientIdAndRecipientTypeAndStatus(
                recipientId, recipientType, status, pageable
            )
            type != null -> messageRepository.findByRecipientIdAndRecipientTypeAndType(
                recipientId, recipientType, type, pageable
            )
            else -> messageRepository.findByRecipientIdAndRecipientType(
                recipientId, recipientType, pageable
            )
        }

        val unreadCount = messageRepository.countUnread(recipientId, recipientType)

        return MessageListResponse(
            items = messagePage.content.map { MessageResponse.from(it) },
            total = messagePage.totalElements,
            page = page,
            unreadCount = unreadCount
        )
    }

    fun getMessage(
        id: UUID,
        recipientId: UUID,
        recipientType: String
    ): Result<MessageResponse, AppError> {
        val message = messageRepository.findById(id).orElse(null)
            ?: return Result.failure(AppError.NotFound("Message not found"))

        // Verify recipient matches
        if (message.recipientId != recipientId || message.recipientType != recipientType) {
            return Result.failure(AppError.NotFound("Message not found"))
        }

        return Result.success(MessageResponse.from(message))
    }

    @Transactional
    fun markAsRead(
        id: UUID,
        recipientId: UUID,
        recipientType: String
    ): Result<MessageResponse, AppError> {
        val message = messageRepository.findById(id).orElse(null)
            ?: return Result.failure(AppError.NotFound("Message not found"))

        if (message.recipientId != recipientId || message.recipientType != recipientType) {
            return Result.failure(AppError.NotFound("Message not found"))
        }

        message.markAsRead()
        val saved = messageRepository.save(message)
        return Result.success(MessageResponse.from(saved))
    }

    @Transactional
    fun performAction(
        id: UUID,
        recipientId: UUID,
        recipientType: String,
        request: MessageActionRequest
    ): Result<MessageResponse, AppError> {
        val message = messageRepository.findById(id).orElse(null)
            ?: return Result.failure(AppError.NotFound("Message not found"))

        if (message.recipientId != recipientId || message.recipientType != recipientType) {
            return Result.failure(AppError.NotFound("Message not found"))
        }

        if (message.status == MessageStatus.ACTIONED) {
            return Result.failure(AppError.Conflict("Message already actioned"))
        }

        // Validate action is valid for this message type
        if (!isValidAction(message.actionType, request.action)) {
            return Result.failure(AppError.Validation(listOf("Invalid action: ${request.action}")))
        }

        message.markAsActioned(request.action)
        val saved = messageRepository.save(message)

        return Result.success(MessageResponse.from(saved))
    }

    /**
     * Create and save a message
     */
    @Transactional
    fun createMessage(message: MessageEntity): MessageEntity {
        return messageRepository.save(message)
    }

    /**
     * Create messages for multiple recipients (e.g., all Ground Admins)
     */
    @Transactional
    fun createMessagesForRecipients(
        recipientIds: List<UUID>,
        recipientType: String,
        messageBuilder: (UUID) -> MessageEntity
    ): List<MessageEntity> {
        return recipientIds.map { recipientId ->
            val message = messageBuilder(recipientId)
            messageRepository.save(message)
        }
    }

    /**
     * Get unread count for recipient
     */
    fun getUnreadCount(recipientId: UUID, recipientType: String): Long {
        return messageRepository.countUnread(recipientId, recipientType)
    }

    private fun isValidAction(actionType: String?, action: String): Boolean {
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
```

---

### 3.6 Create Message Controller

**File:** `src/main/kotlin/com/munserv/messages/api/MessageController.kt`

```kotlin
package com.munserv.messages.api

import com.munserv.messages.service.MessageService
import com.munserv.shared.enums.MessageStatus
import com.munserv.shared.enums.MessageType
import com.munserv.shared.security.CurrentUser
import com.munserv.shared.security.AuthenticatedUser
import com.munserv.shared.result.fold
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.util.UUID

@RestController
@RequestMapping("/api/v1/messages")
class MessageController(
    private val messageService: MessageService
) {
    @GetMapping
    fun getMessages(
        @CurrentUser currentUser: AuthenticatedUser,
        @RequestParam status: MessageStatus? = null,
        @RequestParam type: MessageType? = null,
        @RequestParam page: Int = 1,
        @RequestParam size: Int = 20
    ): ResponseEntity<MessageListResponse> {
        val response = messageService.getMessages(
            recipientId = currentUser.id,
            recipientType = currentUser.recipientType,
            status = status,
            type = type,
            page = page,
            size = size
        )
        return ResponseEntity.ok(response)
    }

    @GetMapping("/{id}")
    fun getMessage(
        @PathVariable id: UUID,
        @CurrentUser currentUser: AuthenticatedUser
    ): ResponseEntity<*> {
        return messageService.getMessage(
            id = id,
            recipientId = currentUser.id,
            recipientType = currentUser.recipientType
        ).fold(
            onSuccess = { ResponseEntity.ok(it) },
            onFailure = { it.toResponse() }
        )
    }

    @PatchMapping("/{id}/read")
    fun markAsRead(
        @PathVariable id: UUID,
        @CurrentUser currentUser: AuthenticatedUser
    ): ResponseEntity<*> {
        return messageService.markAsRead(
            id = id,
            recipientId = currentUser.id,
            recipientType = currentUser.recipientType
        ).fold(
            onSuccess = { ResponseEntity.ok(it) },
            onFailure = { it.toResponse() }
        )
    }

    @PostMapping("/{id}/action")
    fun performAction(
        @PathVariable id: UUID,
        @RequestBody request: MessageActionRequest,
        @CurrentUser currentUser: AuthenticatedUser
    ): ResponseEntity<*> {
        return messageService.performAction(
            id = id,
            recipientId = currentUser.id,
            recipientType = currentUser.recipientType,
            request = request
        ).fold(
            onSuccess = { ResponseEntity.ok(it) },
            onFailure = { it.toResponse() }
        )
    }
}
```

---

### 3.7 Create Unit Tests

**File:** `src/test/kotlin/com/munserv/messages/service/MessageServiceTest.kt`

```kotlin
package com.munserv.messages.service

import com.munserv.messages.api.MessageActionRequest
import com.munserv.messages.domain.MessageEntity
import com.munserv.messages.domain.MessageRepository
import com.munserv.shared.enums.MessageStatus
import com.munserv.shared.enums.MessageType
import com.munserv.shared.result.isSuccess
import com.munserv.shared.result.isFailure
import io.mockk.*
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.Assertions.*
import org.springframework.data.domain.PageImpl
import org.springframework.data.domain.Pageable
import java.util.*

class MessageServiceTest {
    private lateinit var repository: MessageRepository
    private lateinit var service: MessageService

    @BeforeEach
    fun setup() {
        repository = mockk()
        service = MessageService(repository)
    }

    @Test
    fun `getMessages returns paginated messages with unread count`() {
        val recipientId = UUID.randomUUID()
        val message = createTestMessage(recipientId)
        
        every { repository.findByRecipientIdAndRecipientType(recipientId, "member", any()) } returns 
            PageImpl(listOf(message))
        every { repository.countUnread(recipientId, "member") } returns 1

        val result = service.getMessages(recipientId, "member")

        assertEquals(1, result.items.size)
        assertEquals(1, result.unreadCount)
    }

    @Test
    fun `markAsRead updates message status`() {
        val recipientId = UUID.randomUUID()
        val message = createTestMessage(recipientId)
        
        every { repository.findById(message.id) } returns Optional.of(message)
        every { repository.save(any()) } answers { firstArg() }

        val result = service.markAsRead(message.id, recipientId, "member")

        assertTrue(result.isSuccess())
        assertEquals(MessageStatus.READ, result.getOrNull()?.status)
    }

    @Test
    fun `markAsRead returns NotFound for wrong recipient`() {
        val message = createTestMessage(UUID.randomUUID())
        val wrongRecipient = UUID.randomUUID()
        
        every { repository.findById(message.id) } returns Optional.of(message)

        val result = service.markAsRead(message.id, wrongRecipient, "member")

        assertTrue(result.isFailure())
    }

    @Test
    fun `performAction marks message as actioned`() {
        val recipientId = UUID.randomUUID()
        val message = createTestMessage(recipientId, actionType = "accept_decline")
        
        every { repository.findById(message.id) } returns Optional.of(message)
        every { repository.save(any()) } answers { firstArg() }

        val result = service.performAction(
            message.id, 
            recipientId, 
            "member",
            MessageActionRequest("accept")
        )

        assertTrue(result.isSuccess())
        assertEquals(MessageStatus.ACTIONED, result.getOrNull()?.status)
        assertEquals("accept", result.getOrNull()?.actionResult)
    }

    @Test
    fun `performAction rejects invalid action`() {
        val recipientId = UUID.randomUUID()
        val message = createTestMessage(recipientId, actionType = "accept_decline")
        
        every { repository.findById(message.id) } returns Optional.of(message)

        val result = service.performAction(
            message.id, 
            recipientId, 
            "member",
            MessageActionRequest("invalid_action")
        )

        assertTrue(result.isFailure())
    }

    @Test
    fun `performAction rejects already actioned message`() {
        val recipientId = UUID.randomUUID()
        val message = createTestMessage(recipientId, actionType = "accept_decline")
        message.markAsActioned("accept")
        
        every { repository.findById(message.id) } returns Optional.of(message)

        val result = service.performAction(
            message.id, 
            recipientId, 
            "member",
            MessageActionRequest("decline")
        )

        assertTrue(result.isFailure())
    }

    private fun createTestMessage(
        recipientId: UUID,
        actionType: String? = null
    ) = MessageEntity(
        type = MessageType.GROUND_ADMIN_INVITATION,
        title = "Test",
        body = "Test body",
        recipientId = recipientId,
        recipientType = "member",
        actionType = actionType
    )
}
```

---

### 3.8 Create Integration Tests

**File:** `src/test/kotlin/com/munserv/integration/MessagingScenarioTest.kt`

```kotlin
package com.munserv.integration

import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.http.MediaType
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.patch
import org.springframework.test.web.servlet.post

@SpringBootTest
@AutoConfigureMockMvc
class MessagingScenarioTest {

    @Autowired
    private lateinit var mockMvc: MockMvc

    @Test
    fun `member can list their messages`() {
        val memberToken = getTestMemberToken()

        mockMvc.get("/api/v1/messages") {
            header("Authorization", "Bearer $memberToken")
        }.andExpect {
            status { isOk() }
            jsonPath("$.items") { isArray() }
            jsonPath("$.unreadCount") { isNumber() }
        }
    }

    @Test
    fun `member can filter messages by status`() {
        val memberToken = getTestMemberToken()

        mockMvc.get("/api/v1/messages") {
            header("Authorization", "Bearer $memberToken")
            param("status", "UNREAD")
        }.andExpect {
            status { isOk() }
        }
    }

    @Test
    fun `member can mark message as read`() {
        val memberToken = getTestMemberToken()
        val messageId = createTestMessage(memberToken)

        mockMvc.patch("/api/v1/messages/$messageId/read") {
            header("Authorization", "Bearer $memberToken")
        }.andExpect {
            status { isOk() }
            jsonPath("$.status") { value("READ") }
        }
    }

    @Test
    fun `member can perform action on message`() {
        val memberToken = getTestMemberToken()
        val messageId = createTestInvitationMessage(memberToken)

        mockMvc.post("/api/v1/messages/$messageId/action") {
            header("Authorization", "Bearer $memberToken")
            contentType = MediaType.APPLICATION_JSON
            content = """{"action": "accept"}"""
        }.andExpect {
            status { isOk() }
            jsonPath("$.status") { value("ACTIONED") }
            jsonPath("$.actionResult") { value("accept") }
        }
    }

    @Test
    fun `cannot action message twice`() {
        val memberToken = getTestMemberToken()
        val messageId = createTestInvitationMessage(memberToken)

        // First action
        mockMvc.post("/api/v1/messages/$messageId/action") {
            header("Authorization", "Bearer $memberToken")
            contentType = MediaType.APPLICATION_JSON
            content = """{"action": "accept"}"""
        }.andExpect {
            status { isOk() }
        }

        // Second action should fail
        mockMvc.post("/api/v1/messages/$messageId/action") {
            header("Authorization", "Bearer $memberToken")
            contentType = MediaType.APPLICATION_JSON
            content = """{"action": "decline"}"""
        }.andExpect {
            status { isConflict() }
        }
    }

    @Test
    fun `member cannot see other member's messages`() {
        val member1Token = getTestMemberToken(memberId = "member-1")
        val member2Token = getTestMemberToken(memberId = "member-2")
        val messageId = createTestMessage(member1Token)

        mockMvc.get("/api/v1/messages/$messageId") {
            header("Authorization", "Bearer $member2Token")
        }.andExpect {
            status { isNotFound() }
        }
    }
}
```

---

## Verification Commands

```bash
# Run unit tests
./gradlew test --tests "*MessageServiceTest*"
./gradlew test --tests "*MessageFactoryTest*"

# Run integration tests
./gradlew test --tests "*MessagingScenarioTest*"

# Start server and test manually
./gradlew bootRun

# Test list messages
curl http://localhost:8080/api/v1/messages \
  -H "Authorization: Bearer $TOKEN"

# Test get single message
curl http://localhost:8080/api/v1/messages/{id} \
  -H "Authorization: Bearer $TOKEN"

# Test mark as read
curl -X PATCH http://localhost:8080/api/v1/messages/{id}/read \
  -H "Authorization: Bearer $TOKEN"

# Test perform action
curl -X POST http://localhost:8080/api/v1/messages/{id}/action \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action": "accept"}'
```

---

## Definition of Done

- [x] MessageEntity with all fields and state methods
- [x] MessageRepository with all query methods
- [x] MessageDto for request/response
- [x] MessageFactory for creating all message types
- [x] MessageService with CRUD and action handling
- [x] MessageController with all endpoints
- [x] Action validation per message type
- [x] Unit tests passing
- [x] Integration tests passing
- [x] Commit: `feat(backend): Add messaging service for platform communications`

### Implementation Notes

**PostgreSQL Enum Handling:** The implementation uses `@ColumnTransformer` with String fields instead of `@Enumerated(EnumType.STRING)` to properly handle PostgreSQL custom enum types which use lowercase values. The entity has:
- Private `typeValue` and `statusValue` String fields with `@ColumnTransformer(write = "?::enum_type")`
- Public `type` and `status` computed properties that convert to/from enum types
- JPQL queries must reference `statusValue` (not `status`) with lowercase values (e.g., `'unread'`)

**Sealed Result Pattern:** Uses `MessageResult` sealed interface for error handling instead of the `Result<T, AppError>` pattern shown in the spec template.

---

## Handoff Notes

```bash
cd backend
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/backend-phase-3.md

# MessageFactory is used by other services to create messages
# The action handlers in MessageService are called, but the actual
# business logic (e.g., making someone a Ground Admin) happens in
# the calling service (GroundAdminService), not here.
```
