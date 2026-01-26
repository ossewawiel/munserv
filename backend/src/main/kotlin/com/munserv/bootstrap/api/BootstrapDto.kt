package com.munserv.bootstrap.api

import io.swagger.v3.oas.annotations.media.Schema

/**
 * Request to create the first Pod Chief for a pod.
 */
@Schema(description = "Request to create a Pod Chief")
data class CreatePodChiefRequest(
    @field:Schema(
        description = "Email address for the Pod Chief",
        example = "podchief@example.com",
        required = true,
    )
    val email: String,
    @field:Schema(
        description = "Display name for the Pod Chief",
        example = "John Doe",
        required = true,
    )
    val displayName: String,
)

/**
 * Response after successfully creating a Pod Chief.
 */
@Schema(description = "Pod Chief creation response")
data class CreatePodChiefResponse(
    @field:Schema(description = "Unique identifier of the created Pod Chief")
    val id: String,
    @field:Schema(description = "Email address of the Pod Chief")
    val email: String,
    @field:Schema(description = "Display name of the Pod Chief")
    val displayName: String,
    @field:Schema(description = "Role assigned to the Pod Chief")
    val role: String,
    @field:Schema(description = "Temporary password (one-time view)")
    val temporaryPassword: String,
    @field:Schema(description = "Timestamp when the Pod Chief was created")
    val createdAt: String,
)

/**
 * Error response for bootstrap operations.
 */
@Schema(description = "Error response")
data class BootstrapErrorResponse(
    @field:Schema(description = "Error code")
    val error: String,
    @field:Schema(description = "Human-readable error message")
    val message: String,
)

/**
 * Validation error response.
 */
@Schema(description = "Validation error response")
data class BootstrapValidationErrorResponse(
    @field:Schema(description = "Error code")
    val error: String = "validation_error",
    @field:Schema(description = "List of validation error messages")
    val messages: List<String>,
)
