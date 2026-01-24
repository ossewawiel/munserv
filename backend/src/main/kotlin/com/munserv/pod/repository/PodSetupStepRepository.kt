package com.munserv.pod.repository

import com.munserv.pod.domain.SetupStep
import com.munserv.shared.types.PodId

/**
 * Repository interface for Pod setup step tracking.
 */
interface PodSetupStepRepository {
    /**
     * Find all completed setup steps for a pod.
     */
    fun findCompletedSteps(podId: PodId): Set<SetupStep>

    /**
     * Check if a specific step has been completed.
     */
    fun isStepCompleted(podId: PodId, step: SetupStep): Boolean

    /**
     * Mark a setup step as completed.
     * If already completed, this is a no-op.
     */
    fun markComplete(podId: PodId, step: SetupStep)

    /**
     * Check if all required setup steps are completed.
     */
    fun isSetupComplete(podId: PodId): Boolean
}
