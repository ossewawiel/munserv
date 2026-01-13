package com.munserv.auth.api

import jakarta.validation.constraints.DecimalMax
import jakarta.validation.constraints.DecimalMin
import jakarta.validation.constraints.Email
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
    @field:Size(max = 200, message = "Address must be at most 200 characters")
    val address: String,
    @field:NotBlank(message = "Sector ID is required")
    @field:Pattern(
        regexp = "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$",
        message = "Invalid sector ID format",
    )
    val sectorId: String,
    @field:DecimalMin(value = "-90.0", message = "Latitude must be between -90 and 90")
    @field:DecimalMax(value = "90.0", message = "Latitude must be between -90 and 90")
    val latitude: Double,
    @field:DecimalMin(value = "-180.0", message = "Longitude must be between -180 and 180")
    @field:DecimalMax(value = "180.0", message = "Longitude must be between -180 and 180")
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
    @field:Email(message = "Invalid email format")
    val email: String,
    @field:NotBlank(message = "Password is required")
    @field:Size(min = 6, message = "Password must be at least 6 characters")
    val password: String,
)

/**
 * Request for web-based member registration.
 */
data class WebRegisterRequest(
    @field:NotBlank(message = "Email is required")
    @field:Email(message = "Invalid email format")
    val email: String,
    @field:NotBlank(message = "First name is required")
    @field:Size(max = 50, message = "First name too long")
    val firstName: String,
    @field:NotBlank(message = "Surname is required")
    @field:Size(max = 50, message = "Surname too long")
    val surname: String,
    @field:NotBlank(message = "Phone is required")
    @field:Size(max = 20, message = "Phone number too long")
    val phone: String,
    @field:NotBlank(message = "Address is required")
    @field:Size(max = 500, message = "Address too long")
    val address: String,
    @field:DecimalMin("-90.0")
    @field:DecimalMax("90.0")
    val latitude: Double,
    @field:DecimalMin("-180.0")
    @field:DecimalMax("180.0")
    val longitude: Double,
    @field:NotBlank(message = "Sector ID is required")
    val sectorId: String,
)

/**
 * Request for member login with email and password.
 */
data class MemberLoginRequest(
    @field:NotBlank(message = "Email is required")
    @field:Email(message = "Invalid email format")
    val email: String,
    @field:NotBlank(message = "Password is required")
    val password: String,
)

/**
 * Request to change member password.
 */
data class ChangePasswordRequest(
    @field:NotBlank(message = "Current password is required")
    val currentPassword: String,
    @field:NotBlank(message = "New password is required")
    @field:Size(min = 8, message = "Password must be at least 8 characters")
    val newPassword: String,
)
