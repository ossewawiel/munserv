package com.munserv.bootstrap.service

import com.munserv.admin.domain.Admin
import com.munserv.admin.domain.AdminRole
import com.munserv.admin.domain.OnboardingStatus
import com.munserv.admin.repository.AdminRepository
import com.munserv.bootstrap.config.BootstrapConfig
import com.munserv.bootstrap.domain.BootstrapStatus
import com.munserv.shared.email.EmailService
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.PodId
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.security.SecureRandom
import java.time.Clock
import java.time.Instant

/**
 * Service for managing pod bootstrap operations.
 *
 * Handles bootstrap eligibility checks to determine if a super user
 * can create the first Pod Chief on a fresh pod deployment.
 */
@Service
class BootstrapService(
    private val adminRepository: AdminRepository,
    private val bootstrapConfig: BootstrapConfig,
    private val passwordEncoder: PasswordEncoder,
    private val emailService: EmailService,
    private val clock: Clock = Clock.systemUTC(),
) {
    /**
     * Get the bootstrap eligibility status for a pod.
     *
     * Rules:
     * - If no Pod Chief exists: Eligible
     * - If Pod Chief exists but not onboarded: PodChiefOnboarding
     * - If Pod Chief exists and onboarded (ACTIVE): NotEligible
     *
     * @param podId The pod to check eligibility for
     * @return Bootstrap status indicating eligibility
     */
    fun getStatus(podId: PodId): BootstrapStatus {
        // Check if Pod Chief exists and is onboarded (most common case after initial setup)
        if (adminRepository.existsPodChiefOnboarded(podId)) {
            return BootstrapStatus.NotEligible
        }

        // Check if Pod Chief exists (but not onboarded)
        val podChief = adminRepository.findPodChief(podId)
        if (podChief != null) {
            return BootstrapStatus.PodChiefOnboarding
        }

        // No Pod Chief exists - eligible for bootstrap
        return BootstrapStatus.Eligible
    }

    /**
     * Check if super user bootstrap is enabled in configuration.
     *
     * @return true if bootstrap is configured and enabled
     */
    fun isBootstrapEnabled(): Boolean = bootstrapConfig.isConfigured()

    /**
     * Create the first Pod Chief for a pod.
     *
     * This is used by the super user during the bootstrap flow to create
     * the initial administrator for a fresh pod deployment.
     *
     * @param email Pod Chief's email address
     * @param displayName Pod Chief's display name
     * @param podId The pod to create Pod Chief for
     * @return BootstrapResult indicating success or failure
     */
    @Transactional
    fun createPodChief(
        email: String,
        displayName: String,
        podId: PodId,
    ): BootstrapResult {
        // Validate inputs
        val errors = mutableListOf<String>()
        if (email.isBlank()) {
            errors.add("Email is required")
        } else if (!EMAIL_REGEX.matches(email)) {
            errors.add("Invalid email format")
        }
        if (displayName.isBlank()) {
            errors.add("Display name is required")
        }
        if (errors.isNotEmpty()) {
            return BootstrapResult.ValidationError(errors)
        }

        // Check if Pod Chief already exists
        if (adminRepository.findPodChief(podId) != null) {
            return BootstrapResult.PodAlreadyBootstrapped
        }

        // Check if email is already in use
        if (adminRepository.existsByEmail(email)) {
            return BootstrapResult.EmailAlreadyExists(email)
        }

        // Generate temporary password
        val temporaryPassword = generateTemporaryPassword()
        val passwordHash = passwordEncoder.encode(temporaryPassword)

        // Create Pod Chief
        val now = Instant.now(clock)
        val admin =
            Admin(
                id = AdminId.generate(),
                podId = podId,
                wardId = null,
                sectorId = null,
                email = email,
                displayName = displayName,
                role = AdminRole.POD_CHIEF,
                onboardingStatus = OnboardingStatus.PENDING,
                createdAt = now,
                updatedAt = now,
            )

        val savedAdmin = adminRepository.save(admin, passwordHash, temporaryPassword)

        // Send welcome email
        emailService.sendPodChiefWelcomeEmail(
            toEmail = email,
            displayName = displayName,
            tempPassword = temporaryPassword,
        )

        return BootstrapResult.PodChiefCreated(savedAdmin, temporaryPassword)
    }

    private fun generateTemporaryPassword(): String {
        val random = SecureRandom()
        return (1..TEMP_PASSWORD_LENGTH)
            .map { TEMP_PASSWORD_CHARS[random.nextInt(TEMP_PASSWORD_CHARS.size)] }
            .joinToString("")
    }

    companion object {
        private val EMAIL_REGEX = Regex("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")
        private const val TEMP_PASSWORD_LENGTH = 12
        private val TEMP_PASSWORD_CHARS = ('A'..'Z') + ('a'..'z') + ('0'..'9')
    }
}
