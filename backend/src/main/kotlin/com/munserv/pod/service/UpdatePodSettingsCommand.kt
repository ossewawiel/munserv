package com.munserv.pod.service

/**
 * Command for updating pod settings.
 * All fields are optional - only non-null fields will be applied.
 */
data class UpdatePodSettingsCommand(
    val name: String?,
    val logoUrl: String?,
) {
    /**
     * Validate the command and return any errors.
     */
    fun validate(): List<String> {
        val errors = mutableListOf<String>()

        name?.let {
            when {
                it.isBlank() -> errors.add("Pod name cannot be blank")
                it.length < 2 -> errors.add("Pod name must be at least 2 characters")
                it.length > 100 -> errors.add("Pod name must be at most 100 characters")
                else -> { /* valid */ }
            }
        }

        logoUrl?.let {
            if (it.isNotBlank() && it.length > 500) {
                errors.add("Logo URL must be at most 500 characters")
            }
        }

        return errors
    }

    /**
     * Check if this command would make any changes.
     */
    val hasChanges: Boolean get() = name != null || logoUrl != null
}
