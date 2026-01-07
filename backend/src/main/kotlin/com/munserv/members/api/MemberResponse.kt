package com.munserv.members.api

import com.munserv.auth.domain.Member
import io.swagger.v3.oas.annotations.media.Schema

/**
 * Response DTO for registration location coordinates.
 */
@Schema(description = "Geographic coordinates")
data class GeoPointResponse(
    @Schema(description = "Latitude coordinate", example = "-26.1350")
    val latitude: Double,
    @Schema(description = "Longitude coordinate", example = "27.9800")
    val longitude: Double,
)

/**
 * Response DTO for member profile.
 * Used by GET /api/v1/members/me
 */
@Schema(description = "Member profile information")
data class MemberProfileResponse(
    @Schema(description = "Member UUID", example = "550e8400-e29b-41d4-a716-446655440001")
    val id: String,
    @Schema(description = "First name", example = "John")
    val firstName: String,
    @Schema(description = "Last name", example = "Doe")
    val surname: String,
    @Schema(description = "Masked phone number", example = "***-***-4567")
    val phoneNumber: String,
    @Schema(description = "Home address", example = "42 Doreen Road, Northcliff")
    val address: String,
    @Schema(description = "Registration location coordinates")
    val registrationLocation: GeoPointResponse,
    @Schema(description = "Assigned sector UUID", example = "550e8400-e29b-41d4-a716-446655440001")
    val sectorId: String,
    @Schema(description = "Account status", example = "active")
    val status: String,
    @Schema(description = "Registration timestamp", example = "2025-01-15T10:00:00Z")
    val createdAt: String,
)

/**
 * Extension function to convert domain Member to API response.
 * Phone number is masked for privacy.
 */
fun Member.toResponse(): MemberProfileResponse =
    MemberProfileResponse(
        id = id.value.toString(),
        firstName = firstName,
        surname = surname,
        phoneNumber = maskPhone(phoneHash), // Phone hash can't be reversed, show masked placeholder
        address = address,
        registrationLocation =
            GeoPointResponse(
                latitude = registrationLocation.latitude,
                longitude = registrationLocation.longitude,
            ),
        sectorId = sectorId.value.toString(),
        status = status.toString(),
        createdAt = createdAt.toString(),
    )

/**
 * Mask phone number for privacy (shows only last 4 digits).
 * Since we store hash, we show a generic mask.
 */
private fun maskPhone(phoneHash: String): String = "***-***-****"
