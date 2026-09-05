package com.munserv.messages.service

import com.munserv.messages.api.MessageResponse

/**
 * Sealed interface representing the possible results of message operations.
 * Used instead of exceptions for business logic flow control.
 */
sealed interface MessageResult {
    /**
     * Operation completed successfully.
     */
    data class Success(
        val message: MessageResponse,
    ) : MessageResult

    /**
     * Message was not found or recipient doesn't have access.
     */
    data class NotFound(
        val reason: String,
    ) : MessageResult

    /**
     * Action conflicts with current message state (e.g., already actioned).
     */
    data class Conflict(
        val reason: String,
    ) : MessageResult

    /**
     * Validation errors occurred (e.g., invalid action for message type).
     */
    data class ValidationError(
        val errors: List<String>,
    ) : MessageResult
}
