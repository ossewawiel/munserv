package com.munserv.sectors.service

import com.munserv.shared.enums.VerificationMode

/**
 * Command for updating sector settings.
 * All fields are optional - only provided fields will be updated.
 */
data class UpdateSectorSettingsCommand(
    val newIssueVerificationMode: VerificationMode? = null,
    val fixVerificationMode: VerificationMode? = null,
    val daysFixedBeforeClosed: Int? = null,
    val minimumGroundAdmins: Int? = null,
) {
    companion object {
        private const val MIN_DAYS_FIXED = 1
        private const val MAX_DAYS_FIXED = 365
        private const val MIN_GROUND_ADMINS = 0
        private const val MAX_GROUND_ADMINS = 100
    }

    /**
     * Validate the command values.
     * Returns list of validation error messages (empty if valid).
     */
    fun validate(): List<String> {
        val errors = mutableListOf<String>()

        daysFixedBeforeClosed?.let { days ->
            if (days < MIN_DAYS_FIXED) {
                errors.add("daysFixedBeforeClosed must be at least $MIN_DAYS_FIXED")
            }
            if (days > MAX_DAYS_FIXED) {
                errors.add("daysFixedBeforeClosed must be at most $MAX_DAYS_FIXED")
            }
        }

        minimumGroundAdmins?.let { count ->
            if (count < MIN_GROUND_ADMINS) {
                errors.add("minimumGroundAdmins cannot be negative")
            }
            if (count > MAX_GROUND_ADMINS) {
                errors.add("minimumGroundAdmins must be at most $MAX_GROUND_ADMINS")
            }
        }

        return errors
    }
}
