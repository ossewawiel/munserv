package com.munserv.members.api

import com.munserv.auth.domain.Member
import io.swagger.v3.oas.annotations.media.Schema

/**
 * Response DTO for registration location coordinates.
 */
@Schema(description = "Geographic coordinates")
data class GeoPointResponse(
    @field:Schema(description = "Latitude coordinate", example = "-26.1350")
    val latitude: Double,
    @field:Schema(description = "Longitude coordinate", example = "27.9800")
    val longitude: Double,
)

/**
 * Response DTO for member profile.
 * Used by GET /api/v1/members/me
 */
@Schema(description = "Member profile information")
data class MemberProfileResponse(
    @field:Schema(description = "Member UUID", example = "550e8400-e29b-41d4-a716-446655440001")
    val id: String,
    @field:Schema(description = "First name", example = "John")
    val firstName: String,
    @field:Schema(description = "Last name", example = "Doe")
    val surname: String,
    @field:Schema(description = "Masked phone number", example = "***-***-4567")
    val phoneNumber: String,
    @field:Schema(description = "Home address", example = "42 Doreen Road, Northcliff")
    val address: String,
    @field:Schema(description = "Registration location coordinates")
    val registrationLocation: GeoPointResponse,
    @field:Schema(description = "Assigned sector UUID", example = "550e8400-e29b-41d4-a716-446655440001")
    val sectorId: String,
    @field:Schema(description = "Account status", example = "active")
    val status: String,
    @field:Schema(description = "Registration timestamp", example = "2025-01-15T10:00:00Z")
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
        phoneNumber = maskedPhonePlaceholder(),
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
 * Return masked phone placeholder for privacy.
 * Since we store hash, we cannot recover the original number.
 */
private fun maskedPhonePlaceholder(): String = "***-***-****"
