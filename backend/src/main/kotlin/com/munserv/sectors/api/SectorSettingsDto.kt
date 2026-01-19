package com.munserv.sectors.api

import com.munserv.sectors.domain.SectorSettings
import com.munserv.sectors.service.UpdateSectorSettingsCommand
import com.munserv.shared.enums.VerificationMode
import io.swagger.v3.oas.annotations.media.Schema
import java.time.Instant

/**
 * Response DTO for sector settings.
 */
@Schema(description = "Sector settings configuration")
data class SectorSettingsResponse(
    @Schema(description = "Settings unique identifier", example = "550e8400-e29b-41d4-a716-446655440010")
    val id: String,
    @Schema(description = "Sector unique identifier", example = "550e8400-e29b-41d4-a716-446655440001")
    val sectorId: String,
    @Schema(
        description = "How Ground Admins are notified about new issue verification",
        example = "ALL_NOTIFIED",
    )
    val newIssueVerificationMode: VerificationMode,
    @Schema(
        description = "How Ground Admins are notified about fix verification",
        example = "ALL_NOTIFIED",
    )
    val fixVerificationMode: VerificationMode,
    @Schema(
        description = "Days an issue stays in Fixed state before auto-closing",
        example = "7",
        minimum = "1",
        maximum = "365",
    )
    val daysFixedBeforeClosed: Int,
    @Schema(
        description = "Minimum number of Ground Admins required for the sector",
        example = "2",
        minimum = "0",
        maximum = "100",
    )
    val minimumGroundAdmins: Int,
    @Schema(description = "When the settings were created")
    val createdAt: Instant,
    @Schema(description = "When the settings were last updated")
    val updatedAt: Instant,
) {
    companion object {
        fun from(settings: SectorSettings) =
            SectorSettingsResponse(
                id = settings.id.toString(),
                sectorId = settings.sectorId.toString(),
                newIssueVerificationMode = settings.newIssueVerificationMode,
                fixVerificationMode = settings.fixVerificationMode,
                daysFixedBeforeClosed = settings.daysFixedBeforeClosed,
                minimumGroundAdmins = settings.minimumGroundAdmins,
                createdAt = settings.createdAt,
                updatedAt = settings.updatedAt,
            )
    }
}

/**
 * Request DTO for updating sector settings.
 * All fields are optional - only provided fields will be updated.
 */
@Schema(description = "Partial update request for sector settings")
data class UpdateSectorSettingsRequest(
    @Schema(
        description = "How Ground Admins are notified about new issue verification",
        example = "ADMIN_ASSIGNS",
        nullable = true,
    )
    val newIssueVerificationMode: VerificationMode? = null,
    @Schema(
        description = "How Ground Admins are notified about fix verification",
        example = "NEAREST_AUTO",
        nullable = true,
    )
    val fixVerificationMode: VerificationMode? = null,
    @Schema(
        description = "Days an issue stays in Fixed state before auto-closing (1-365)",
        example = "14",
        minimum = "1",
        maximum = "365",
        nullable = true,
    )
    val daysFixedBeforeClosed: Int? = null,
    @Schema(
        description = "Minimum number of Ground Admins required (0-100)",
        example = "3",
        minimum = "0",
        maximum = "100",
        nullable = true,
    )
    val minimumGroundAdmins: Int? = null,
) {
    /**
     * Convert to service command.
     */
    fun toCommand() =
        UpdateSectorSettingsCommand(
            newIssueVerificationMode = newIssueVerificationMode,
            fixVerificationMode = fixVerificationMode,
            daysFixedBeforeClosed = daysFixedBeforeClosed,
            minimumGroundAdmins = minimumGroundAdmins,
        )
}
