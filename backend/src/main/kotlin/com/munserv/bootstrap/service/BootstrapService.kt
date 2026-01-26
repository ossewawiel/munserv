package com.munserv.bootstrap.service

import com.munserv.admin.repository.AdminRepository
import com.munserv.bootstrap.config.BootstrapConfig
import com.munserv.bootstrap.domain.BootstrapStatus
import com.munserv.shared.types.PodId
import org.springframework.stereotype.Service

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
}
