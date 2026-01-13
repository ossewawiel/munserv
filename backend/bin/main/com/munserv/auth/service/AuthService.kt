package com.munserv.auth.service

import com.munserv.auth.config.AdminConfig
import com.munserv.auth.domain.Email
import com.munserv.auth.domain.Member
import com.munserv.auth.domain.MemberStatus
import com.munserv.auth.domain.Password
import com.munserv.auth.domain.PhoneNumber
import com.munserv.auth.domain.Pin
import com.munserv.auth.repository.MemberRepository
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.UUID

/**
 * Service for handling authentication flows.
 * Coordinates OTP, JWT, and Member operations.
 */
@Service
class AuthService(
    private val memberRepository: MemberRepository,
    private val otpService: OtpService,
    private val jwtService: JwtService,
    private val adminConfig: AdminConfig,
) {
    companion object {
        private const val MEMBER_ROLE = "member"
        private const val ADMIN_ROLE = "admin"
    }

    /**
     * Start registration flow by sending OTP.
     */
    @Transactional(readOnly = true)
    fun register(phoneString: String): AuthResult {
        val phone =
            try {
                PhoneNumber.fromString(phoneString)
            } catch (e: IllegalArgumentException) {
                return AuthResult.InvalidPhoneNumber
            }

        if (memberRepository.existsByPhoneHash(phone.hash())) {
            return AuthResult.PhoneAlreadyRegistered
        }

        otpService.generate(phone)
        return AuthResult.OtpSent
    }

    /**
     * Verify OTP code.
     */
    fun verifyOtp(
        phoneString: String,
        code: String,
    ): AuthResult {
        val phone =
            try {
                PhoneNumber.fromString(phoneString)
            } catch (e: IllegalArgumentException) {
                return AuthResult.InvalidPhoneNumber
            }

        return if (otpService.verify(phone, code)) {
            AuthResult.OtpVerified
        } else {
            AuthResult.InvalidOtp
        }
    }

    /**
     * Complete registration by creating member account.
     */
    @Transactional
    fun completeRegistration(command: CompleteRegistrationCommand): AuthResult {
        val phoneNumber =
            try {
                PhoneNumber.fromString(command.phone)
            } catch (e: IllegalArgumentException) {
                return AuthResult.InvalidPhoneNumber
            }

        val pinValue =
            try {
                Pin.fromString(command.pin)
            } catch (e: IllegalArgumentException) {
                return AuthResult.InvalidPin
            }

        val sectorIdValue =
            try {
                SectorId(UUID.fromString(command.sectorId))
            } catch (e: IllegalArgumentException) {
                return AuthResult.InvalidSectorId
            }

        // Generate unique email placeholder for legacy phone registration
        val memberId = MemberId.generate()
        val placeholderEmail = "legacy-${memberId.value}@pending-migration.local"
        val emailHash =
            java.security.MessageDigest.getInstance("SHA-256")
                .digest(placeholderEmail.lowercase().toByteArray())
                .joinToString("") { "%02x".format(it) }

        val member =
            Member(
                id = memberId,
                sectorId = sectorIdValue,
                email = placeholderEmail,
                emailHash = emailHash,
                passwordHash = null,
                mustChangePassword = false,
                phoneHash = phoneNumber.hash(),
                pinHash = pinValue.hash(),
                phone = command.phone,
                firstName = command.firstName,
                surname = command.surname,
                address = command.address,
                registrationLocation = command.location,
            )

        val savedMember = memberRepository.save(member)
        val tokens = jwtService.generateTokenPair(savedMember.id, MEMBER_ROLE)

        return AuthResult.RegistrationComplete(
            memberId = savedMember.id,
            tokens = tokens,
        )
    }

    /**
     * Login with phone and PIN.
     */
    @Transactional(readOnly = true)
    fun login(
        phoneString: String,
        pinString: String,
    ): AuthResult {
        val phone =
            try {
                PhoneNumber.fromString(phoneString)
            } catch (e: IllegalArgumentException) {
                return AuthResult.InvalidCredentials
            }

        val member =
            memberRepository.findByPhoneHash(phone.hash())
                ?: return AuthResult.InvalidCredentials

        // Check account status
        if (member.status != MemberStatus.Active) {
            return AuthResult.AccountSuspended
        }

        // Verify PIN (pinHash may be null for web-registered members)
        val pinHash = member.pinHash ?: return AuthResult.InvalidCredentials
        if (!Pin.verify(pinString, pinHash)) {
            return AuthResult.InvalidCredentials
        }

        val tokens = jwtService.generateTokenPair(member.id, MEMBER_ROLE)

        return AuthResult.LoginSuccess(
            memberId = member.id,
            tokens = tokens,
        )
    }

    /**
     * Admin login with email and password.
     *
     * WARNING: MVP implementation using configuration-based credentials.
     * TODO: Replace with proper admin table and secure authentication in production.
     */
    fun adminLogin(
        email: String,
        password: String,
    ): AuthResult {
        if (email != adminConfig.email || password != adminConfig.password) {
            return AuthResult.InvalidCredentials
        }

        val adminId = MemberId.fromString(adminConfig.id)
        val tokens = jwtService.generateTokenPair(adminId, ADMIN_ROLE)

        return AuthResult.AdminLoginSuccess(
            adminId = adminConfig.id,
            email = adminConfig.email,
            displayName = adminConfig.displayName,
            sectorId = adminConfig.sectorId,
            role = adminConfig.role,
            sectorName = adminConfig.sectorName,
            sectorCenterLat = adminConfig.sectorCenterLat,
            sectorCenterLng = adminConfig.sectorCenterLng,
            tokens = tokens,
        )
    }

    /**
     * Check if a phone number is registered.
     */
    @Transactional(readOnly = true)
    fun checkPhone(phoneString: String): AuthResult {
        val phone =
            try {
                PhoneNumber.fromString(phoneString)
            } catch (e: IllegalArgumentException) {
                return AuthResult.InvalidPhoneNumber
            }

        val isRegistered = memberRepository.existsByPhoneHash(phone.hash())
        return AuthResult.PhoneCheckResult(isRegistered = isRegistered)
    }

    /**
     * Refresh tokens using a valid refresh token.
     */
    @Transactional(readOnly = true)
    fun refreshToken(refreshToken: String): AuthResult {
        val validation = jwtService.validateToken(refreshToken)

        if (!validation.isValid || validation.tokenType != TokenType.REFRESH) {
            return AuthResult.InvalidToken
        }

        val memberId =
            jwtService.extractMemberId(refreshToken)
                ?: return AuthResult.InvalidToken

        val member =
            memberRepository.findById(memberId)
                ?: return AuthResult.InvalidToken

        val tokens = jwtService.generateTokenPair(member.id, MEMBER_ROLE)

        return AuthResult.TokenRefreshed(tokens)
    }

    /**
     * Authenticates a member using email and password.
     * Used by mobile app after admin approval.
     */
    @Transactional(readOnly = true)
    fun loginWithEmail(
        emailString: String,
        password: String,
    ): AuthResult {
        // Validate email format
        val email =
            Email.fromStringOrNull(emailString)
                ?: return AuthResult.InvalidCredentials

        // Find member by email
        val member =
            memberRepository.findByEmailHash(email.hash())
                ?: return AuthResult.InvalidCredentials

        // Check member status
        when (member.status) {
            MemberStatus.PendingApproval -> return AuthResult.PendingApproval
            MemberStatus.Suspended -> return AuthResult.AccountSuspended
            MemberStatus.Deleted -> return AuthResult.InvalidCredentials
            MemberStatus.Active -> { /* OK */ }
        }

        // Must have password set (approved by admin)
        val passwordHash =
            member.passwordHash
                ?: return AuthResult.PendingApproval

        // Verify password
        if (!Password.verify(password, passwordHash)) {
            return AuthResult.InvalidCredentials
        }

        // Generate tokens
        val tokens = jwtService.generateTokenPair(member.id, MEMBER_ROLE)

        return AuthResult.MemberLoginSuccess(
            memberId = member.id,
            tokens = tokens,
            mustChangePassword = member.mustChangePassword,
        )
    }

    /**
     * Changes a member's password.
     * Used for first-time password change after approval.
     */
    @Transactional
    fun changePassword(
        memberId: MemberId,
        currentPassword: String,
        newPassword: String,
    ): AuthResult {
        val member =
            memberRepository.findById(memberId)
                ?: return AuthResult.MemberNotFound

        // Must have existing password
        val currentHash =
            member.passwordHash
                ?: return AuthResult.InvalidCredentials

        // Verify current password
        if (!Password.verify(currentPassword, currentHash)) {
            return AuthResult.InvalidCredentials
        }

        // Validate new password
        val validationErrors = Password.validate(newPassword)
        if (validationErrors.isNotEmpty()) {
            return AuthResult.ValidationError(validationErrors)
        }

        // Update password
        val updated =
            member
                .withPassword(Password.hash(newPassword), mustChange = false)
        memberRepository.save(updated)

        return AuthResult.PasswordChanged(memberId)
    }
}
