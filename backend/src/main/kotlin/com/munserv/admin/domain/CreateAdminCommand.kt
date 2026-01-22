package com.munserv.admin.domain

import com.munserv.shared.types.SectorId

/**
 * Command object for creating a new admin.
 * Contains validated input data for admin creation.
 */
data class CreateAdminCommand(
    val email: String,
    val displayName: String,
    val role: AdminRole,
    val sectorId: SectorId,
) {
    /**
     * Validate the command and return a list of validation errors.
     * Returns empty list if command is valid.
     */
    fun validate(): List<String> {
        val errors = mutableListOf<String>()

        if (email.isBlank()) {
            errors.add("Email is required")
        } else if (!email.matches(EMAIL_REGEX)) {
            errors.add("Invalid email format")
        }

        if (displayName.isBlank()) {
            errors.add("Display name is required")
        } else if (displayName.length > MAX_DISPLAY_NAME_LENGTH) {
            errors.add("Display name must be $MAX_DISPLAY_NAME_LENGTH characters or less")
        }

        return errors
    }

    companion object {
        private val EMAIL_REGEX = Regex("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")
        private const val MAX_DISPLAY_NAME_LENGTH = 100
    }
}

/**
 * Command object for updating an existing admin.
 * All fields are optional - only provided fields will be updated.
 */
data class UpdateAdminCommand(
    val displayName: String? = null,
) {
    /**
     * Validate the command and return a list of validation errors.
     * Returns empty list if command is valid.
     */
    fun validate(): List<String> {
        val errors = mutableListOf<String>()

        if (displayName != null) {
            if (displayName.isBlank()) {
                errors.add("Display name cannot be blank")
            } else if (displayName.length > MAX_DISPLAY_NAME_LENGTH) {
                errors.add("Display name must be $MAX_DISPLAY_NAME_LENGTH characters or less")
            }
        }

        return errors
    }

    companion object {
        private const val MAX_DISPLAY_NAME_LENGTH = 100
    }
}
