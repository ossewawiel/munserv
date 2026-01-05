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
