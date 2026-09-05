package com.munserv.auth.api

import com.munserv.auth.service.TokenPair

/**
 * Response for OTP sent/verified operations.
 */
data class OtpResponse(
    val message: String,
)

/**
 * Response containing authentication tokens.
 */
data class TokenResponse(
    val accessToken: String,
    val refreshToken: String,
    val expiresIn: Long,
    val tokenType: String = "Bearer",
)

/**
 * Response for registration completion.
 */
data class RegistrationResponse(
    val memberId: String,
    val accessToken: String,
    val refreshToken: String,
    val expiresIn: Long,
    val tokenType: String = "Bearer",
)

/**
 * Response for login success.
 */
data class LoginResponse(
    val memberId: String,
    val accessToken: String,
    val refreshToken: String,
    val expiresIn: Long,
    val tokenType: String = "Bearer",
)

/**
 * Response for admin login success.
 * Matches frontend expected contract with nested tokens and profile.
 */
data class AdminLoginResponse(
    val tokens: AdminTokens,
    val profile: AdminProfile,
)

data class AdminTokens(
    val accessToken: String,
    val refreshToken: String,
    val expiresAt: String,
)

data class AdminProfile(
    val admin: AdminUser,
    val sector: AdminSector? = null,
    val bootstrapStatus: String? = null,
    val supportGrant: SupportGrantInfo? = null,
)

/**
 * Support grant carried on an admin login response when the super user logged in
 * under a pod chief's support grant, instead of via bootstrap.
 */
data class SupportGrantInfo(
    val grantId: String,
    val grantedRole: String,
    val expiresAt: String,
)

data class AdminUser(
    val id: String,
    val email: String,
    val displayName: String,
    val role: String,
    val level: String,
    val podId: String? = null,
    val wardId: String? = null,
    val sectorId: String? = null,
    val onboardingStatus: String? = null,
)

data class AdminSector(
    val id: String,
    val name: String,
    val center: GeoPointResponse,
)

data class GeoPointResponse(
    val lat: Double,
    val lng: Double,
)

/**
 * Response for phone registration check.
 */
data class CheckPhoneResponse(
    val isRegistered: Boolean,
)

/**
 * Error response format.
 */
data class ErrorResponse(
    val error: String,
    val message: String,
)

/**
 * Extension to convert TokenPair to TokenResponse.
 */
fun TokenPair.toResponse(): TokenResponse =
    TokenResponse(
        accessToken = accessToken,
        refreshToken = refreshToken,
        expiresIn = expiresIn,
    )

/**
 * Response for web registration submission.
 */
data class WebRegisterResponse(
    val message: String,
    val memberId: String,
)

/**
 * Response for member email+password login.
 */
data class MemberLoginResponse(
    val memberId: String,
    val accessToken: String,
    val refreshToken: String,
    val expiresIn: Long,
    val mustChangePassword: Boolean,
    val tokenType: String = "Bearer",
)

/**
 * Response for member approval by admin.
 */
data class MemberApprovedResponse(
    val memberId: String,
    val email: String,
    val message: String,
)

/**
 * Simple message response.
 */
data class MessageResponse(
    val message: String,
)
