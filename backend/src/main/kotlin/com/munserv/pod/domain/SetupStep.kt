package com.munserv.pod.domain

/**
 * Enumeration of setup steps required for a pod to be fully configured.
 * Pod Chiefs must complete all steps before the pod is considered ready.
 */
enum class SetupStep {
    POD_NAME,
    POD_BOUNDARIES,
    WARDS_SECTORS,
    FIRST_ADMIN,
    ;

    fun toDbValue(): String = name.lowercase()

    companion object {
        fun fromDbValue(value: String): SetupStep = entries.first { it.name.equals(value, ignoreCase = true) }

        /**
         * All steps that must be completed for setup to be considered complete.
         */
        val allRequired: Set<SetupStep> = entries.toSet()
    }
}
