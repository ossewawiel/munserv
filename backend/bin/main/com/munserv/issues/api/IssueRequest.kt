package com.munserv.issues.api

import io.swagger.v3.oas.annotations.media.Schema
import jakarta.validation.constraints.DecimalMax
import jakarta.validation.constraints.DecimalMin
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Pattern
import jakarta.validation.constraints.Size

/**
 * Request body for creating a new issue.
 */
data class CreateIssueRequest(
    @field:NotBlank(message = "Issue type is required")
    @field:Pattern(
        regexp = "^(pothole|water_leak|street_light|sewage_leak|illegal_dumping|road_damage|other)$",
        message = "Invalid issue type",
    )
    @Schema(
        description = "Type of issue",
        example = "pothole",
        allowableValues = ["pothole", "water_leak", "street_light", "sewage_leak", "illegal_dumping", "road_damage", "other"],
    )
    val type: String,
    @field:NotBlank(message = "Sector ID is required")
    @field:Pattern(
        regexp = "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$",
        message = "Invalid sector ID format",
    )
    @Schema(description = "Sector UUID where the issue is located", example = "550e8400-e29b-41d4-a716-446655440001")
    val sectorId: String,
    @field:DecimalMin(value = "-90.0", message = "Latitude must be between -90 and 90")
    @field:DecimalMax(value = "90.0", message = "Latitude must be between -90 and 90")
    @Schema(description = "GPS latitude", example = "-26.1350")
    val latitude: Double,
    @field:DecimalMin(value = "-180.0", message = "Longitude must be between -180 and 180")
    @field:DecimalMax(value = "180.0", message = "Longitude must be between -180 and 180")
    @Schema(description = "GPS longitude", example = "27.9800")
    val longitude: Double,
    @field:Size(max = 1000, message = "Description cannot exceed 1000 characters")
    @Schema(description = "Optional description of the issue", maxLength = 1000)
    val description: String? = null,
)

/**
 * Request body for updating issue state.
 */
data class UpdateIssueStateRequest(
    @field:NotBlank(message = "State is required")
    @field:Pattern(
        regexp = "^(reported|confirmed|in_progress|fixed|rejected|reopened)$",
        message = "Invalid issue state",
    )
    @Schema(
        description = "New issue state",
        example = "confirmed",
        allowableValues = ["reported", "confirmed", "in_progress", "fixed", "rejected", "reopened"],
    )
    val state: String,
    @field:Size(max = 500, message = "Note cannot exceed 500 characters")
    @Schema(description = "Optional note explaining the state change", maxLength = 500)
    val note: String? = null,
)

/**
 * Location in request/response.
 */
data class LocationRequest(
    @field:DecimalMin(value = "-90.0", message = "Latitude must be between -90 and 90")
    @field:DecimalMax(value = "90.0", message = "Latitude must be between -90 and 90")
    val latitude: Double,
    @field:DecimalMin(value = "-180.0", message = "Longitude must be between -180 and 180")
    @field:DecimalMax(value = "180.0", message = "Longitude must be between -180 and 180")
    val longitude: Double,
)
