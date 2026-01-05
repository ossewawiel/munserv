package com.munserv.auth.api

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Pattern
import jakarta.validation.constraints.Size

/**
 * Request to start registration with phone number.
 */
data class RegisterRequest(
    @field:NotBlank(message = "Phone number is required")
    val phone: String,
)

/**
 * Request to verify OTP code.
 */
data class VerifyOtpRequest(
    @field:NotBlank(message = "Phone number is required")
    val phone: String,
    @field:NotBlank(message = "OTP code is required")
    @field:Size(min = 6, max = 6, message = "OTP must be 6 digits")
    @field:Pattern(regexp = "^[0-9]{6}$", message = "OTP must contain only digits")
    val code: String,
)

/**
 * Request to complete registration with member details.
 */
data class CompleteRegistrationRequest(
    @field:NotBlank(message = "Phone number is required")
    val phone: String,
    @field:NotBlank(message = "PIN is required")
    @field:Size(min = 4, max = 4, message = "PIN must be 4 digits")
    @field:Pattern(regexp = "^[0-9]{4}$", message = "PIN must contain only digits")
    val pin: String,
    @field:NotBlank(message = "First name is required")
    @field:Size(max = 50, message = "First name must be at most 50 characters")
    val firstName: String,
    @field:NotBlank(message = "Surname is required")
    @field:Size(max = 50, message = "Surname must be at most 50 characters")
    val surname: String,
    @field:NotBlank(message = "Address is required")
    val address: String,
    @field:NotBlank(message = "Sector ID is required")
    val sectorId: String,
    val latitude: Double,
    val longitude: Double,
)

/**
 * Request to login with phone and PIN.
 */
data class LoginRequest(
    @field:NotBlank(message = "Phone number is required")
    val phone: String,
    @field:NotBlank(message = "PIN is required")
    @field:Size(min = 4, max = 4, message = "PIN must be 4 digits")
    val pin: String,
)

/**
 * Request to refresh tokens.
 */
data class RefreshTokenRequest(
    @field:NotBlank(message = "Refresh token is required")
    val refreshToken: String,
)

/**
 * Request for admin login.
 */
data class AdminLoginRequest(
    @field:NotBlank(message = "Email is required")
    val email: String,
    @field:NotBlank(message = "Password is required")
    val password: String,
)
