package com.munserv.messages.api

import com.munserv.messages.service.MessageResult
import com.munserv.messages.service.MessageService
import com.munserv.shared.api.ErrorBody
import com.munserv.shared.api.ErrorCodes
import com.munserv.shared.api.ErrorResponse
import com.munserv.shared.enums.MessageStatus
import com.munserv.shared.enums.MessageType
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.media.Content
import io.swagger.v3.oas.annotations.media.Schema
import io.swagger.v3.oas.annotations.responses.ApiResponse
import io.swagger.v3.oas.annotations.responses.ApiResponses
import io.swagger.v3.oas.annotations.security.SecurityRequirement
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import jakarta.validation.constraints.Max
import jakarta.validation.constraints.Min
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.validation.annotation.Validated
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PatchMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

/**
 * REST controller for message endpoints.
 *
 * Provides endpoints for listing, viewing, and acting on messages.
 */
@RestController
@RequestMapping("/api/v1/messages")
@Tag(name = "Messages", description = "Message management endpoints for viewing and acting on platform messages")
@SecurityRequirement(name = "bearerAuth")
@Validated
class MessageController(
    private val messageService: MessageService,
) {
    companion object {
        private const val ERROR_AUTH_REQUIRED = "Authentication required"
        private const val ERROR_INVALID_AUTH = "Invalid authentication"
    }

    /**
     * GET /api/v1/messages - List messages for the authenticated user.
     */
    @Operation(
        summary = "List messages",
        description = "Retrieve a paginated list of messages for the authenticated user with optional filtering",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Successfully retrieved messages",
                content = [Content(schema = Schema(implementation = MessageListResponse::class))],
            ),
            ApiResponse(responseCode = "401", description = "Unauthorized - invalid or missing token"),
        ],
    )
    @GetMapping
    fun getMessages(
        @Parameter(hidden = true)
        @AuthenticationPrincipal userIdStr: String?,
        @Parameter(description = "Filter by message status")
        @RequestParam(required = false) status: MessageStatus?,
        @Parameter(description = "Filter by message type")
        @RequestParam(required = false) type: MessageType?,
        @Parameter(description = "Page number (1-based)")
        @RequestParam(defaultValue = "1")
        @Min(1, message = "Page must be at least 1")
        page: Int,
        @Parameter(description = "Items per page (max 100)")
        @RequestParam(defaultValue = "20")
        @Min(1, message = "Size must be at least 1")
        @Max(100, message = "Size cannot exceed 100")
        size: Int,
    ): ResponseEntity<*> {
        if (userIdStr == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ErrorResponse(ErrorBody(ErrorCodes.UNAUTHORIZED, ERROR_AUTH_REQUIRED)))
        }

        val userId =
            try {
                UUID.fromString(userIdStr)
            } catch (e: IllegalArgumentException) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse(ErrorBody(ErrorCodes.UNAUTHORIZED, ERROR_INVALID_AUTH)))
            }

        // Determine recipient type based on token claims (simplified - in production would check claims)
        val recipientType = "member"

        val response =
            messageService.getMessages(
                recipientId = userId,
                recipientType = recipientType,
                status = status,
                type = type,
                page = page,
                size = size,
            )

        return ResponseEntity.ok(response)
    }

    /**
     * GET /api/v1/messages/{id} - Get a single message by ID.
     */
    @Operation(
        summary = "Get message",
        description = "Retrieve a single message by its ID",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Successfully retrieved message",
                content = [Content(schema = Schema(implementation = MessageResponse::class))],
            ),
            ApiResponse(responseCode = "401", description = "Unauthorized - invalid or missing token"),
            ApiResponse(responseCode = "404", description = "Message not found"),
        ],
    )
    @GetMapping("/{id}")
    fun getMessage(
        @Parameter(description = "Message UUID", required = true)
        @PathVariable id: UUID,
        @Parameter(hidden = true)
        @AuthenticationPrincipal userIdStr: String?,
    ): ResponseEntity<*> {
        if (userIdStr == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ErrorResponse(ErrorBody(ErrorCodes.UNAUTHORIZED, ERROR_AUTH_REQUIRED)))
        }

        val userId =
            try {
                UUID.fromString(userIdStr)
            } catch (e: IllegalArgumentException) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse(ErrorBody(ErrorCodes.UNAUTHORIZED, ERROR_INVALID_AUTH)))
            }

        val recipientType = "member"

        return when (val result = messageService.getMessage(id, userId, recipientType)) {
            is MessageResult.Success -> ResponseEntity.ok(result.message)
            is MessageResult.NotFound ->
                ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ErrorResponse(ErrorBody(ErrorCodes.NOT_FOUND, result.reason)))
            is MessageResult.Conflict,
            is MessageResult.ValidationError,
            -> throw IllegalStateException("Unexpected result type: ${result::class.simpleName}")
        }
    }

    /**
     * PATCH /api/v1/messages/{id}/read - Mark a message as read.
     */
    @Operation(
        summary = "Mark message as read",
        description = "Mark a message as read, updating its status and setting the read timestamp",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Message marked as read",
                content = [Content(schema = Schema(implementation = MessageResponse::class))],
            ),
            ApiResponse(responseCode = "401", description = "Unauthorized - invalid or missing token"),
            ApiResponse(responseCode = "404", description = "Message not found"),
        ],
    )
    @PatchMapping("/{id}/read")
    fun markAsRead(
        @Parameter(description = "Message UUID", required = true)
        @PathVariable id: UUID,
        @Parameter(hidden = true)
        @AuthenticationPrincipal userIdStr: String?,
    ): ResponseEntity<*> {
        if (userIdStr == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ErrorResponse(ErrorBody(ErrorCodes.UNAUTHORIZED, ERROR_AUTH_REQUIRED)))
        }

        val userId =
            try {
                UUID.fromString(userIdStr)
            } catch (e: IllegalArgumentException) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse(ErrorBody(ErrorCodes.UNAUTHORIZED, ERROR_INVALID_AUTH)))
            }

        val recipientType = "member"

        return when (val result = messageService.markAsRead(id, userId, recipientType)) {
            is MessageResult.Success -> ResponseEntity.ok(result.message)
            is MessageResult.NotFound ->
                ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ErrorResponse(ErrorBody(ErrorCodes.NOT_FOUND, result.reason)))
            is MessageResult.Conflict,
            is MessageResult.ValidationError,
            -> throw IllegalStateException("Unexpected result type: ${result::class.simpleName}")
        }
    }

    /**
     * POST /api/v1/messages/{id}/action - Perform an action on a message.
     */
    @Operation(
        summary = "Perform message action",
        description = "Perform an action on a message (e.g., accept, decline, approve, reject)",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Action performed successfully",
                content = [Content(schema = Schema(implementation = MessageResponse::class))],
            ),
            ApiResponse(responseCode = "400", description = "Invalid action for message type"),
            ApiResponse(responseCode = "401", description = "Unauthorized - invalid or missing token"),
            ApiResponse(responseCode = "404", description = "Message not found"),
            ApiResponse(responseCode = "409", description = "Message already actioned"),
        ],
    )
    @PostMapping("/{id}/action")
    fun performAction(
        @Parameter(description = "Message UUID", required = true)
        @PathVariable id: UUID,
        @io.swagger.v3.oas.annotations.parameters.RequestBody(
            description = "Action request",
            required = true,
            content = [Content(schema = Schema(implementation = MessageActionRequest::class))],
        )
        @Valid
        @RequestBody request: MessageActionRequest,
        @Parameter(hidden = true)
        @AuthenticationPrincipal userIdStr: String?,
    ): ResponseEntity<*> {
        if (userIdStr == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ErrorResponse(ErrorBody(ErrorCodes.UNAUTHORIZED, ERROR_AUTH_REQUIRED)))
        }

        val userId =
            try {
                UUID.fromString(userIdStr)
            } catch (e: IllegalArgumentException) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse(ErrorBody(ErrorCodes.UNAUTHORIZED, ERROR_INVALID_AUTH)))
            }

        val recipientType = "member"

        return when (val result = messageService.performAction(id, userId, recipientType, request)) {
            is MessageResult.Success -> ResponseEntity.ok(result.message)
            is MessageResult.NotFound ->
                ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ErrorResponse(ErrorBody(ErrorCodes.NOT_FOUND, result.reason)))
            is MessageResult.Conflict ->
                ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(ErrorResponse(ErrorBody(ErrorCodes.CONFLICT, result.reason)))
            is MessageResult.ValidationError ->
                ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ErrorResponse(ErrorBody(ErrorCodes.VALIDATION_ERROR, result.errors.joinToString(", "))))
        }
    }
}
