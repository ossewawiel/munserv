package com.munserv.issues.service

import com.munserv.issues.domain.Issue
import com.munserv.issues.domain.IssueId
import com.munserv.issues.domain.IssueState

/**
 * Sealed interface representing the possible results of issue operations.
 * Used instead of exceptions for business logic flow control.
 */
sealed interface IssueResult {
    /**
     * Operation completed successfully.
     */
    data class Success(val issue: Issue) : IssueResult

    /**
     * Issue was not found.
     */
    data class NotFound(val id: IssueId) : IssueResult

    /**
     * State transition is not allowed.
     */
    data class InvalidTransition(
        val from: IssueState,
        val to: IssueState,
    ) : IssueResult

    /**
     * Validation errors occurred.
     */
    data class ValidationError(val errors: List<String>) : IssueResult

    /**
     * Operation not authorized.
     */
    data class Unauthorized(val reason: String) : IssueResult
}
