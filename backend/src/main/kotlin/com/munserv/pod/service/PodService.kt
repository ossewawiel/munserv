package com.munserv.pod.service

import com.munserv.pod.domain.PodSetupStatus
import com.munserv.pod.domain.PodSettings
import com.munserv.pod.domain.SetupStep
import com.munserv.pod.repository.PodRepository
import com.munserv.pod.repository.PodSetupStepRepository
import com.munserv.shared.types.PodId
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.time.Instant

/**
 * Service layer for pod operations.
 * Handles business logic for pod setup status and settings management.
 */
@Service
class PodService(
    private val podRepository: PodRepository,
    private val setupStepRepository: PodSetupStepRepository,
    private val clock: Clock,
) {
    /**
     * Get the setup status for a pod.
     * Returns Complete if all required steps are done, otherwise Incomplete with missing steps.
     */
    @Transactional(readOnly = true)
    fun getSetupStatus(podId: PodId): PodResult<PodSetupStatus> {
        if (!podRepository.existsById(podId)) {
            return PodResult.NotFound(podId)
        }

        val completedSteps = setupStepRepository.findCompletedSteps(podId)
        val status = PodSetupStatus.fromCompletedSteps(completedSteps)

        return PodResult.Success(status)
    }

    /**
     * Get settings for a pod.
     */
    @Transactional(readOnly = true)
    fun getSettings(podId: PodId): PodResult<PodSettings> {
        val pod = podRepository.findById(podId)
            ?: return PodResult.NotFound(podId)

        return PodResult.Success(PodSettings.fromPod(pod))
    }

    /**
     * Update settings for a pod.
     * Only non-null fields in the command will be applied.
     * If the name is updated, the POD_NAME setup step is marked complete.
     */
    @Transactional
    fun updateSettings(podId: PodId, command: UpdatePodSettingsCommand): PodResult<PodSettings> {
        // Validate command first
        val errors = command.validate()
        if (errors.isNotEmpty()) {
            return PodResult.ValidationError(errors)
        }

        // Check pod exists
        val pod = podRepository.findById(podId)
            ?: return PodResult.NotFound(podId)

        // Apply updates if any
        if (!command.hasChanges) {
            return PodResult.Success(PodSettings.fromPod(pod))
        }

        val now = Instant.now(clock)
        var updated = pod

        command.name?.let {
            updated = updated.withName(it, now)
        }

        command.logoUrl?.let {
            updated = updated.withLogoUrl(it.ifBlank { null }, now)
        }

        // Save the updated pod
        val saved = podRepository.save(updated)

        // Mark setup step as complete if name was set
        if (command.name != null) {
            setupStepRepository.markComplete(podId, SetupStep.POD_NAME)
            checkAndMarkSetupComplete(podId, now)
        }

        return PodResult.Success(PodSettings.fromPod(saved))
    }

    /**
     * Mark a specific setup step as complete.
     */
    @Transactional
    fun completeSetupStep(podId: PodId, step: SetupStep): PodResult<PodSetupStatus> {
        if (!podRepository.existsById(podId)) {
            return PodResult.NotFound(podId)
        }

        setupStepRepository.markComplete(podId, step)
        val now = Instant.now(clock)
        checkAndMarkSetupComplete(podId, now)

        return getSetupStatus(podId)
    }

    /**
     * Check if all setup steps are complete and mark the pod accordingly.
     */
    private fun checkAndMarkSetupComplete(podId: PodId, now: Instant) {
        if (setupStepRepository.isSetupComplete(podId)) {
            val pod = podRepository.findById(podId)
            if (pod != null && !pod.isSetupComplete) {
                podRepository.save(pod.markSetupComplete(now))
            }
        }
    }
}
