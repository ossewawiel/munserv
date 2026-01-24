package com.munserv.admin.domain

/**
 * Represents the onboarding status of an administrator.
 * New administrators go through a flow: PENDING -> PASSWORD_CHANGED -> PROFILE_COMPLETE -> ACTIVE
 */
enum class OnboardingStatus {
    /**
     * Administrator has been created but hasn't logged in yet.
     * Has a temporary password.
     */
    PENDING,

    /**
     * Administrator has changed their temporary password.
     * Can now complete their profile.
     */
    PASSWORD_CHANGED,

    /**
     * Administrator has completed their profile.
     * Receives welcome message and becomes active.
     */
    PROFILE_COMPLETE,

    /**
     * Administrator is fully onboarded and active.
     */
    ACTIVE,
    ;

    fun toDbValue(): String = name.lowercase()

    /**
     * Returns the next status in the onboarding flow.
     * Returns null if already at final status (ACTIVE).
     */
    val nextStatus: OnboardingStatus?
        get() =
            when (this) {
                PENDING -> PASSWORD_CHANGED
                PASSWORD_CHANGED -> PROFILE_COMPLETE
                PROFILE_COMPLETE -> ACTIVE
                ACTIVE -> null
            }

    /**
     * Returns true if the administrator needs to change their password.
     */
    val requiresPasswordChange: Boolean
        get() = this == PENDING

    /**
     * Returns true if the administrator needs to complete their profile.
     */
    val requiresProfileCompletion: Boolean
        get() = this == PASSWORD_CHANGED

    /**
     * Returns true if onboarding is complete.
     */
    val isOnboarded: Boolean
        get() = this == ACTIVE

    companion object {
        fun fromDbValue(value: String): OnboardingStatus =
            when (value.lowercase()) {
                "pending" -> PENDING
                "password_changed" -> PASSWORD_CHANGED
                "profile_complete" -> PROFILE_COMPLETE
                "active" -> ACTIVE
                else -> throw IllegalArgumentException("Unknown onboarding status: $value")
            }
    }
}
