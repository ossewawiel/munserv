package com.munserv.auth.service

import com.munserv.shared.types.MemberId

/**
 * Sealed interface for authentication operation results.
 * Follows the Result pattern for error handling.
 */
sealed interface AuthResult {
    // Registration results
    data object OtpSent : AuthResult

    data object OtpVerified : AuthResult

    data class RegistrationComplete(
        val memberId: MemberId,
        val tokens: TokenPair,
    ) : AuthResult

    data object PhoneAlreadyRegistered : AuthResult

    data object InvalidPhoneNumber : AuthResult

    data object InvalidOtp : AuthResult

    data object InvalidPin : AuthResult

    data object InvalidSectorId : AuthResult

    // Phone check result
    data class PhoneCheckResult(
        val isRegistered: Boolean,
    ) : AuthResult

    // Login results
    data class LoginSuccess(
        val memberId: MemberId,
        val tokens: TokenPair,
    ) : AuthResult

    // Admin login result
    data class AdminLoginSuccess(
        val adminId: String,
        val email: String,
        val displayName: String,
        val sectorId: String,
        val role: String,
        val sectorName: String,
        val sectorCenterLat: Double,
        val sectorCenterLng: Double,
        val tokens: TokenPair,
    ) : AuthResult

    data object InvalidCredentials : AuthResult

    data object AccountSuspended : AuthResult

    // Token results
    data class TokenRefreshed(
        val tokens: TokenPair,
    ) : AuthResult

    data object InvalidToken : AuthResult

    // Email+password login results
    data class MemberLoginSuccess(
        val memberId: MemberId,
        val tokens: TokenPair,
        val mustChangePassword: Boolean,
    ) : AuthResult

    // Password change results
    data class PasswordChanged(
        val memberId: MemberId,
    ) : AuthResult

    // Member not found
    data object MemberNotFound : AuthResult

    // Registration pending admin approval
    data object PendingApproval : AuthResult

    // Validation errors
    data class ValidationError(
        val errors: List<String>,
    ) : AuthResult
}
