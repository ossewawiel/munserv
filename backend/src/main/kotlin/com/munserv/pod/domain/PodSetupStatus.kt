package com.munserv.pod.domain

/**
 * Sealed class representing the setup status of a pod.
 * A pod is either incomplete (with missing steps) or complete.
 */
sealed class PodSetupStatus {
    /**
     * Pod setup is incomplete with the given missing steps.
     */
    data class Incomplete(val missingSteps: List<SetupStep>) : PodSetupStatus() {
        init {
            require(missingSteps.isNotEmpty()) { "Incomplete status must have at least one missing step" }
        }
    }

    /**
     * Pod setup is complete - all required steps have been finished.
     */
    data object Complete : PodSetupStatus()

    /**
     * Whether the setup is complete.
     */
    val isComplete: Boolean get() = this is Complete

    /**
     * Get the list of missing steps, or empty list if complete.
     */
    val missingStepsList: List<SetupStep>
        get() =
            when (this) {
                is Incomplete -> missingSteps
                is Complete -> emptyList()
            }

    companion object {
        /**
         * Determine setup status from the set of completed steps.
         */
        fun fromCompletedSteps(completedSteps: Set<SetupStep>): PodSetupStatus {
            val missing = SetupStep.allRequired - completedSteps
            return if (missing.isEmpty()) {
                Complete
            } else {
                Incomplete(missing.toList().sortedBy { it.ordinal })
            }
        }
    }
}
