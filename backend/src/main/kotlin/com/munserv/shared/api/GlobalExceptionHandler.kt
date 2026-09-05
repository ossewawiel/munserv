package com.munserv.shared.api

import jakarta.validation.ConstraintViolationException
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.http.converter.HttpMessageNotReadableException
import org.springframework.security.access.AccessDeniedException
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.MissingServletRequestParameterException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException
import org.springframework.web.multipart.MaxUploadSizeExceededException
import org.springframework.web.servlet.resource.NoResourceFoundException

@RestControllerAdvice
class GlobalExceptionHandler {
    private val logger = LoggerFactory.getLogger(javaClass)

    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidationException(ex: MethodArgumentNotValidException): ResponseEntity<ErrorResponse> {
        val errors =
            ex.bindingResult.fieldErrors.associate { error ->
                error.field to (error.defaultMessage ?: "Invalid value")
            }

        val message =
            if (errors.size == 1) {
                errors.values.first()
            } else {
                "Validation failed"
            }

        return ResponseEntity
            .status(HttpStatus.BAD_REQUEST)
            .body(validationError(message, errors))
    }

    @ExceptionHandler(ConstraintViolationException::class)
    fun handleConstraintViolation(ex: ConstraintViolationException): ResponseEntity<ErrorResponse> {
        val errors =
            ex.constraintViolations.associate { violation ->
                violation.propertyPath.toString() to violation.message
            }

        return ResponseEntity
            .status(HttpStatus.BAD_REQUEST)
            .body(validationError("Validation failed", errors))
    }

    @ExceptionHandler(HttpMessageNotReadableException::class)
    fun handleHttpMessageNotReadable(ex: HttpMessageNotReadableException): ResponseEntity<ErrorResponse> {
        logger.debug("Request body not readable", ex)
        return ResponseEntity
            .status(HttpStatus.BAD_REQUEST)
            .body(validationError("Invalid request body"))
    }

    @ExceptionHandler(MissingServletRequestParameterException::class)
    fun handleMissingParameter(ex: MissingServletRequestParameterException): ResponseEntity<ErrorResponse> =
        ResponseEntity
            .status(HttpStatus.BAD_REQUEST)
            .body(
                validationError(
                    "Missing required parameter: ${ex.parameterName}",
                    mapOf("parameter" to ex.parameterName),
                ),
            )

    @ExceptionHandler(MethodArgumentTypeMismatchException::class)
    fun handleTypeMismatch(ex: MethodArgumentTypeMismatchException): ResponseEntity<ErrorResponse> =
        ResponseEntity
            .status(HttpStatus.BAD_REQUEST)
            .body(
                validationError(
                    "Invalid value for parameter: ${ex.name}",
                    mapOf("parameter" to (ex.name ?: "unknown"), "value" to (ex.value?.toString() ?: "null")),
                ),
            )

    @ExceptionHandler(NoResourceFoundException::class)
    fun handleNotFound(ex: NoResourceFoundException): ResponseEntity<ErrorResponse> =
        ResponseEntity
            .status(HttpStatus.NOT_FOUND)
            .body(notFoundError("Resource", ex.resourcePath))

    @ExceptionHandler(IllegalArgumentException::class)
    fun handleIllegalArgument(ex: IllegalArgumentException): ResponseEntity<ErrorResponse> {
        logger.debug("Illegal argument", ex)
        return ResponseEntity
            .status(HttpStatus.BAD_REQUEST)
            .body(validationError(ex.message ?: "Invalid argument"))
    }

    @ExceptionHandler(MaxUploadSizeExceededException::class)
    fun handleMaxUploadSize(ex: MaxUploadSizeExceededException): ResponseEntity<ErrorResponse> {
        logger.debug("File size exceeded", ex)
        return ResponseEntity
            .status(HttpStatus.BAD_REQUEST)
            .body(validationError("File size exceeds maximum allowed (5MB)"))
    }

    @ExceptionHandler(AccessDeniedException::class)
    fun handleAccessDenied(ex: AccessDeniedException): ResponseEntity<ErrorResponse> {
        logger.debug("Access denied", ex)
        return ResponseEntity
            .status(HttpStatus.FORBIDDEN)
            .body(forbiddenError(ex.message ?: "Forbidden"))
    }

    @ExceptionHandler(Exception::class)
    fun handleGenericException(ex: Exception): ResponseEntity<ErrorResponse> {
        logger.error("Unhandled exception", ex)
        return ResponseEntity
            .status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(internalError())
    }
}
