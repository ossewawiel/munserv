package com.munserv.pod.api

import com.fasterxml.jackson.annotation.JsonProperty
import com.munserv.pod.domain.PodSettings
import com.munserv.pod.domain.PodSetupStatus
import com.munserv.pod.service.UpdatePodSettingsCommand
import io.swagger.v3.oas.annotations.media.Schema
import jakarta.validation.constraints.Size

/**
 * Response DTO for pod setup status.
 */
@Schema(description = "Pod setup status")
data class PodSetupStatusResponse(
    @get:JsonProperty("isComplete")
    @get:Schema(description = "Whether setup is complete", example = "false")
    val isComplete: Boolean,
    @field:Schema(description = "List of missing setup steps", example = "[\"pod_boundaries\", \"first_admin\"]")
    val missingSteps: List<String>,
) {
    companion object {
        fun from(status: PodSetupStatus): PodSetupStatusResponse =
            PodSetupStatusResponse(
                isComplete = status.isComplete,
                missingSteps = status.missingStepsList.map { it.toDbValue() },
            )
    }
}

/**
 * Response DTO for pod settings.
 */
@Schema(description = "Pod settings")
data class PodSettingsResponse(
    @field:Schema(description = "Pod name", example = "Ward42")
    val name: String,
    @field:Schema(description = "Display name shown in UI", example = "Munserv Pod Ward42")
    val displayName: String,
    @field:Schema(description = "URL to pod logo image", example = "https://example.com/logo.png")
    val logoUrl: String?,
) {
    companion object {
        fun from(settings: PodSettings): PodSettingsResponse =
            PodSettingsResponse(
                name = settings.name,
                displayName = settings.displayName,
                logoUrl = settings.logoUrl,
            )
    }
}

/**
 * Request DTO for updating pod settings.
 */
@Schema(description = "Update pod settings request")
data class UpdatePodSettingsRequest(
    @field:Size(min = 2, max = 100, message = "Pod name must be between 2 and 100 characters")
    @field:Schema(description = "New pod name", example = "Ward42", minLength = 2, maxLength = 100)
    val name: String?,
    @field:Size(max = 500, message = "Logo URL must be at most 500 characters")
    @field:Schema(description = "URL to pod logo image", example = "https://example.com/logo.png", maxLength = 500)
    val logoUrl: String?,
) {
    /**
     * Convert to service command.
     */
    fun toCommand(): UpdatePodSettingsCommand =
        UpdatePodSettingsCommand(
            name = name,
            logoUrl = logoUrl,
        )
}

/**
 * Response DTO for a pod logo upload.
 */
@Schema(description = "Pod logo upload response")
data class PodLogoResponse(
    @field:Schema(
        description = "Public URL of the stored logo image",
        example = "http://localhost:8080/uploads/8f14e45f-ea1e-4d0e-9c6b-2a1c6f1b7d10.png",
    )
    val logoUrl: String,
)
