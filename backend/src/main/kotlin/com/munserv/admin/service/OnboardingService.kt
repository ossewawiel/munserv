package com.munserv.admin.service

import com.munserv.admin.domain.Admin
import com.munserv.admin.domain.OnboardingStatus
import com.munserv.admin.repository.AdminRepository
import com.munserv.shared.types.AdminId
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.time.Instant

/**
 * Service for administrator onboarding flow.
 * Handles password change and profile completion for new administrators.
 */
@Service
class OnboardingService(
    private val adminRepository: AdminRepository,
    private val passwordEncoder: PasswordEncoder,
    private val clock: Clock = Clock.systemUTC(),
) {
    /**
     * Change password for an administrator during onboarding.
     * Transitions status from PENDING to PASSWORD_CHANGED.
     *
     * @param adminId The administrator to update
     * @param newPassword The new password
     * @return Success with updated admin, or error
     */
    @Transactional
    fun changePassword(
        adminId: AdminId,
        newPassword: String,
    ): OnboardingResult {
        val admin =
            adminRepository.findById(adminId)
                ?: return OnboardingResult.AdminNotFound(adminId)

        // Validate password
        val passwordErrors = validatePassword(newPassword)
        if (passwordErrors.isNotEmpty()) {
            return OnboardingResult.ValidationError(passwordErrors)
        }

        // Check onboarding status
        if (!admin.requiresPasswordChange) {
            return OnboardingResult.InvalidStep(
                current = admin.onboardingStatus,
                expected = OnboardingStatus.PENDING,
            )
        }

        // Update password and onboarding status
        val now = Instant.now(clock)
        val updatedAdmin =
            admin.copy(
                onboardingStatus = OnboardingStatus.PASSWORD_CHANGED,
                updatedAt = now,
            )

        // Save with new password hash
        val passwordHash = requireNotNull(passwordEncoder.encode(newPassword))
        val saved = adminRepository.updateWithPassword(updatedAdmin, passwordHash)

        return OnboardingResult.Success(saved)
    }

    /**
     * Complete profile for an administrator during onboarding.
     * Transitions status from PASSWORD_CHANGED to PROFILE_COMPLETE (or ACTIVE).
     *
     * @param adminId The administrator to update
     * @param displayName Optional new display name
     * @param knownAs Optional nickname or preferred name
     * @param contactPhone Optional contact phone number
     * @param address Optional physical address
     * @return Success with updated admin, or error
     */
    @Transactional
    fun completeProfile(
        adminId: AdminId,
        displayName: String?,
        knownAs: String? = null,
        contactPhone: String? = null,
        address: String? = null,
    ): OnboardingResult {
        val admin =
            adminRepository.findById(adminId)
                ?: return OnboardingResult.AdminNotFound(adminId)

        // Check onboarding status
        if (!admin.requiresProfileCompletion) {
            return OnboardingResult.InvalidStep(
                current = admin.onboardingStatus,
                expected = OnboardingStatus.PASSWORD_CHANGED,
            )
        }

        // Validate display name if provided
        if (displayName != null && displayName.isBlank()) {
            return OnboardingResult.ValidationError(listOf("Display name cannot be blank"))
        }

        // Update profile and complete onboarding
        val now = Instant.now(clock)
        val updatedAdmin =
            admin.copy(
                displayName = displayName ?: admin.displayName,
                knownAs = knownAs,
                contactPhone = contactPhone,
                address = address,
                onboardingStatus = OnboardingStatus.ACTIVE,
                onboardingCompletedAt = now,
                updatedAt = now,
            )

        val saved = adminRepository.update(updatedAdmin)

        return OnboardingResult.Completed(saved)
    }

    /**
     * Get the current onboarding status for an administrator.
     *
     * @param adminId The administrator to check
     * @return Success with admin, or not found
     */
    @Transactional(readOnly = true)
    fun getOnboardingStatus(adminId: AdminId): OnboardingResult {
        val admin =
            adminRepository.findById(adminId)
                ?: return OnboardingResult.AdminNotFound(adminId)

        return OnboardingResult.Success(admin)
    }

    private fun validatePassword(password: String): List<String> {
        val errors = mutableListOf<String>()

        if (password.length < MIN_PASSWORD_LENGTH) {
            errors.add("Password must be at least $MIN_PASSWORD_LENGTH characters")
        }
        if (!password.any { it.isUpperCase() }) {
            errors.add("Password must contain at least one uppercase letter")
        }
        if (!password.any { it.isLowerCase() }) {
            errors.add("Password must contain at least one lowercase letter")
        }
        if (!password.any { it.isDigit() }) {
            errors.add("Password must contain at least one digit")
        }

        return errors
    }

    companion object {
        private const val MIN_PASSWORD_LENGTH = 8
    }
}

/**
 * Sealed interface for onboarding operation results.
 */
sealed interface OnboardingResult {
    /**
     * Operation succeeded.
     */
    data class Success(
        val admin: Admin,
    ) : OnboardingResult

    /**
     * Onboarding completed successfully.
     */
    data class Completed(
        val admin: Admin,
    ) : OnboardingResult

    /**
     * Administrator not found.
     */
    data class AdminNotFound(
        val id: AdminId,
    ) : OnboardingResult

    /**
     * Validation errors occurred.
     */
    data class ValidationError(
        val errors: List<String>,
    ) : OnboardingResult

    /**
     * Invalid onboarding step - admin is not at the expected status.
     */
    data class InvalidStep(
        val current: OnboardingStatus,
        val expected: OnboardingStatus,
    ) : OnboardingResult
}
