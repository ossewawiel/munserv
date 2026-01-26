package com.munserv.auth.service

import com.munserv.admin.repository.AdminRepository
import com.munserv.auth.config.AdminConfig
import com.munserv.auth.domain.Email
import com.munserv.auth.domain.Member
import com.munserv.auth.domain.MemberStatus
import com.munserv.auth.domain.Password
import com.munserv.auth.domain.PhoneNumber
import com.munserv.auth.domain.Pin
import com.munserv.auth.repository.MemberRepository
import com.munserv.bootstrap.config.BootstrapConfig
import com.munserv.bootstrap.domain.BootstrapStatus
import com.munserv.bootstrap.service.BootstrapService
import com.munserv.pod.repository.PodRepository
import com.munserv.sectors.repository.SectorRepository
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.PodId
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
    private val adminRepository: AdminRepository,
    private val sectorRepository: SectorRepository,
    private val bootstrapConfig: BootstrapConfig,
    private val bootstrapService: BootstrapService,
    private val podRepository: PodRepository,
) {
    companion object {
        private const val MEMBER_ROLE = "member"
        private const val ADMIN_ROLE = "admin"
        private const val SUPER_USER_ROLE = "super_user"
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
     * Checks super user credentials first, then falls back to database admin.
     */
    @Transactional(readOnly = true)
    fun adminLogin(
        email: String,
        password: String,
    ): AuthResult {
        // Get the current pod (MVP: single pod deployment)
        val pod = podRepository.findFirst()
        val podId = pod?.let { PodId(it.id.value) }

        // 1. Check if this is a super user login attempt
        if (podId != null &&
            bootstrapConfig.isConfigured() &&
            email == bootstrapConfig.email &&
            password == bootstrapConfig.password
        ) {
            return handleSuperUserLogin(podId)
        }

        // 2. Fall back to database admin lookup
        val adminWithPassword =
            adminRepository.findByEmailWithPasswordHash(email)
                ?: return AuthResult.InvalidCredentials

        val admin = adminWithPassword.admin

        // Verify password
        if (!Password.verify(password, adminWithPassword.passwordHash)) {
            return AuthResult.InvalidCredentials
        }

        // Get sector details if admin has a sector
        val sector = admin.sectorId?.let { sectorRepository.findById(it) }

        val adminId = MemberId(admin.id.value)
        val tokens = jwtService.generateTokenPair(adminId, ADMIN_ROLE)

        return AuthResult.AdminLoginSuccess(
            adminId = admin.id.value.toString(),
            email = admin.email,
            displayName = admin.displayName,
            role = admin.role.toDbValue().uppercase(),
            level = admin.level.name.lowercase(),
            tokens = tokens,
            podId = admin.podId?.value?.toString(),
            wardId = admin.wardId?.value?.toString(),
            sectorId = admin.sectorId?.value?.toString(),
            sectorName = sector?.name,
            sectorCenterLat = sector?.center?.latitude,
            sectorCenterLng = sector?.center?.longitude,
            onboardingStatus = admin.onboardingStatus.toDbValue(),
        )
    }

    /**
     * Handle super user login for bootstrap.
     */
    private fun handleSuperUserLogin(podId: PodId): AuthResult {
        // Check bootstrap eligibility
        val status = bootstrapService.getStatus(podId)

        return when (status) {
            is BootstrapStatus.NotEligible -> {
                // Pod already bootstrapped - super user cannot log in
                AuthResult.InvalidCredentials
            }
            is BootstrapStatus.Eligible,
            is BootstrapStatus.PodChiefOnboarding,
            -> {
                // Super user can log in
                val memberId = MemberId(UUID.randomUUID())
                val tokens = jwtService.generateTokenPair(memberId, SUPER_USER_ROLE)

                val bootstrapStatus =
                    when (status) {
                        is BootstrapStatus.Eligible -> "requires_bootstrap"
                        is BootstrapStatus.PodChiefOnboarding -> "pod_chief_pending"
                        else -> "unknown"
                    }

                AuthResult.SuperUserLoginSuccess(
                    tokens = tokens,
                    podId = podId.value.toString(),
                    bootstrapStatus = bootstrapStatus,
                )
            }
        }
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
