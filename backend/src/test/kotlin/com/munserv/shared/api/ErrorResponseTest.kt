package com.munserv.shared.api

import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for ErrorResponse and helper functions.
 */
class ErrorResponseTest {
    @Nested
    inner class ErrorBodyTest {
        @Test
        fun `ErrorBody should contain code and message`() {
            val body = ErrorBody("TEST_CODE", "Test message")

            body.code shouldBe "TEST_CODE"
            body.message shouldBe "Test message"
            body.details shouldBe null
        }

        @Test
        fun `ErrorBody should support optional details`() {
            val details = mapOf("field" to "email", "reason" to "invalid format")
            val body = ErrorBody("TEST_CODE", "Test message", details)

            body.details shouldNotBe null
            body.details?.get("field") shouldBe "email"
            body.details?.get("reason") shouldBe "invalid format"
        }
    }

    @Nested
    inner class ErrorResponseTest {
        @Test
        fun `ErrorResponse should wrap ErrorBody`() {
            val body = ErrorBody("TEST", "message")
            val response = ErrorResponse(body)

            response.error shouldBe body
        }
    }

    @Nested
    inner class ErrorCodesTest {
        @Test
        fun `ErrorCodes should contain standard codes`() {
            ErrorCodes.VALIDATION_ERROR shouldBe "VALIDATION_ERROR"
            ErrorCodes.UNAUTHORIZED shouldBe "UNAUTHORIZED"
            ErrorCodes.FORBIDDEN shouldBe "FORBIDDEN"
            ErrorCodes.NOT_FOUND shouldBe "NOT_FOUND"
            ErrorCodes.CONFLICT shouldBe "CONFLICT"
            ErrorCodes.INVALID_STATE_TRANSITION shouldBe "INVALID_STATE_TRANSITION"
            ErrorCodes.INTERNAL_ERROR shouldBe "INTERNAL_ERROR"
        }
    }

    @Nested
    inner class ValidationErrorHelperTest {
        @Test
        fun `validationError should create error with VALIDATION_ERROR code`() {
            val error = validationError("Invalid input")

            error.error.code shouldBe ErrorCodes.VALIDATION_ERROR
            error.error.message shouldBe "Invalid input"
            error.error.details shouldBe null
        }

        @Test
        fun `validationError should support details`() {
            val details = mapOf("field" to "email")
            val error = validationError("Invalid input", details)

            error.error.details shouldBe details
        }
    }

    @Nested
    inner class NotFoundErrorHelperTest {
        @Test
        fun `notFoundError should create error with NOT_FOUND code`() {
            val error = notFoundError("Issue", "123")

            error.error.code shouldBe ErrorCodes.NOT_FOUND
            error.error.message shouldBe "Issue not found"
            error.error.details?.get("id") shouldBe "123"
            error.error.details?.get("type") shouldBe "Issue"
        }
    }

    @Nested
    inner class UnauthorizedErrorHelperTest {
        @Test
        fun `unauthorizedError should create error with UNAUTHORIZED code`() {
            val error = unauthorizedError()

            error.error.code shouldBe ErrorCodes.UNAUTHORIZED
            error.error.message shouldBe "Authentication required"
        }

        @Test
        fun `unauthorizedError should support custom message`() {
            val error = unauthorizedError("Token expired")

            error.error.message shouldBe "Token expired"
        }
    }

    @Nested
    inner class ForbiddenErrorHelperTest {
        @Test
        fun `forbiddenError should create error with FORBIDDEN code`() {
            val error = forbiddenError()

            error.error.code shouldBe ErrorCodes.FORBIDDEN
            error.error.message shouldBe "Access denied"
        }

        @Test
        fun `forbiddenError should support custom message`() {
            val error = forbiddenError("Insufficient permissions")

            error.error.message shouldBe "Insufficient permissions"
        }
    }

    @Nested
    inner class ConflictErrorHelperTest {
        @Test
        fun `conflictError should create error with CONFLICT code`() {
            val error = conflictError("Resource already exists")

            error.error.code shouldBe ErrorCodes.CONFLICT
            error.error.message shouldBe "Resource already exists"
        }

        @Test
        fun `conflictError should support details`() {
            val details = mapOf("existingId" to "456")
            val error = conflictError("Resource already exists", details)

            error.error.details shouldBe details
        }
    }

    @Nested
    inner class InvalidStateTransitionErrorHelperTest {
        @Test
        fun `invalidStateTransitionError should create error with transition details`() {
            val error = invalidStateTransitionError("reported", "fixed")

            error.error.code shouldBe ErrorCodes.INVALID_STATE_TRANSITION
            error.error.message shouldBe "Cannot transition from reported to fixed"
            error.error.details?.get("from") shouldBe "reported"
            error.error.details?.get("to") shouldBe "fixed"
        }
    }

    @Nested
    inner class InternalErrorHelperTest {
        @Test
        fun `internalError should create error with INTERNAL_ERROR code`() {
            val error = internalError()

            error.error.code shouldBe ErrorCodes.INTERNAL_ERROR
            error.error.message shouldBe "An unexpected error occurred"
        }

        @Test
        fun `internalError should support custom message`() {
            val error = internalError("Database connection failed")

            error.error.message shouldBe "Database connection failed"
        }
    }
}
