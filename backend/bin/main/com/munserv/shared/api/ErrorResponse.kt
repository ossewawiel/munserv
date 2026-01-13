package com.munserv.shared.api

import com.fasterxml.jackson.annotation.JsonInclude

/**
 * Standard error response format matching the API contract.
 *
 * Example:
 * ```json
 * {
 *   "error": {
 *     "code": "VALIDATION_ERROR",
 *     "message": "Invalid phone number format",
 *     "details": {
 *       "field": "phoneNumber",
 *       "reason": "Must be E.164 format"
 *     }
 *   }
 * }
 * ```
 */
data class ErrorResponse(
    val error: ErrorBody,
)

@JsonInclude(JsonInclude.Include.NON_NULL)
data class ErrorBody(
    val code: String,
    val message: String,
    val details: Map<String, Any>? = null,
)

/**
 * Standard error codes matching the API contract.
 */
object ErrorCodes {
    const val VALIDATION_ERROR = "VALIDATION_ERROR"
    const val UNAUTHORIZED = "UNAUTHORIZED"
    const val FORBIDDEN = "FORBIDDEN"
    const val NOT_FOUND = "NOT_FOUND"
    const val CONFLICT = "CONFLICT"
    const val INVALID_STATE_TRANSITION = "INVALID_STATE_TRANSITION"
    const val INTERNAL_ERROR = "INTERNAL_ERROR"
}

/**
 * Helper functions to create error responses.
 */
fun validationError(
    message: String,
    details: Map<String, Any>? = null,
) = ErrorResponse(ErrorBody(ErrorCodes.VALIDATION_ERROR, message, details))

fun notFoundError(
    resourceType: String,
    id: String,
) = ErrorResponse(
    ErrorBody(
        ErrorCodes.NOT_FOUND,
        "$resourceType not found",
        mapOf("id" to id, "type" to resourceType),
    ),
)

fun unauthorizedError(message: String = "Authentication required") = ErrorResponse(ErrorBody(ErrorCodes.UNAUTHORIZED, message))

fun forbiddenError(message: String = "Access denied") = ErrorResponse(ErrorBody(ErrorCodes.FORBIDDEN, message))

fun conflictError(
    message: String,
    details: Map<String, Any>? = null,
) = ErrorResponse(ErrorBody(ErrorCodes.CONFLICT, message, details))

fun invalidStateTransitionError(
    from: String,
    to: String,
) = ErrorResponse(
    ErrorBody(
        ErrorCodes.INVALID_STATE_TRANSITION,
        "Cannot transition from $from to $to",
        mapOf("from" to from, "to" to to),
    ),
)

fun internalError(message: String = "An unexpected error occurred") = ErrorResponse(ErrorBody(ErrorCodes.INTERNAL_ERROR, message))
