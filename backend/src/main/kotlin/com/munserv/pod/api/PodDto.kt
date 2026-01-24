package com.munserv.pod.api

import com.munserv.pod.domain.PodSetupStatus
import com.munserv.pod.domain.PodSettings
import com.munserv.pod.service.UpdatePodSettingsCommand
import io.swagger.v3.oas.annotations.media.Schema
import jakarta.validation.constraints.Size

/**
 * Response DTO for pod setup status.
 */
@Schema(description = "Pod setup status")
data class PodSetupStatusResponse(
    @Schema(description = "Whether setup is complete", example = "false")
    val isComplete: Boolean,
    @Schema(description = "List of missing setup steps", example = "[\"pod_boundaries\", \"first_admin\"]")
    val missingSteps: List<String>,
) {
    companion object {
        fun from(status: PodSetupStatus): PodSetupStatusResponse = PodSetupStatusResponse(
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
    @Schema(description = "Pod name", example = "Ward42")
    val name: String,
    @Schema(description = "Display name shown in UI", example = "Munserv Pod Ward42")
    val displayName: String,
    @Schema(description = "URL to pod logo image", example = "https://example.com/logo.png")
    val logoUrl: String?,
) {
    companion object {
        fun from(settings: PodSettings): PodSettingsResponse = PodSettingsResponse(
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
    @Schema(description = "New pod name", example = "Ward42", minLength = 2, maxLength = 100)
    val name: String?,
    @field:Size(max = 500, message = "Logo URL must be at most 500 characters")
    @Schema(description = "URL to pod logo image", example = "https://example.com/logo.png", maxLength = 500)
    val logoUrl: String?,
) {
    /**
     * Convert to service command.
     */
    fun toCommand(): UpdatePodSettingsCommand = UpdatePodSettingsCommand(
        name = name,
        logoUrl = logoUrl,
    )
}
