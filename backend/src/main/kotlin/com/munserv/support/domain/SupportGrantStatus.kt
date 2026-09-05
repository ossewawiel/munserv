package com.munserv.support.domain

/**
 * Lifecycle status of a [SupportGrant].
 *
 * `active` is the only non-terminal status; a grant transitions to `expired` or `revoked`
 * and is never reopened.
 */
enum class SupportGrantStatus {
    ACTIVE,
    EXPIRED,
    REVOKED,
    ;

    fun toDbValue(): String = name.lowercase()

    /**
     * Statuses this status may legally transition to.
     */
    val allowedTransitions: Set<SupportGrantStatus>
        get() =
            when (this) {
                ACTIVE -> setOf(EXPIRED, REVOKED)
                EXPIRED, REVOKED -> emptySet()
            }

    /**
     * Check whether this status may transition to [target].
     */
    fun canTransitionTo(target: SupportGrantStatus): Boolean = allowedTransitions.contains(target)

    companion object {
        fun fromDbValue(value: String): SupportGrantStatus =
            when (value.lowercase()) {
                "active" -> ACTIVE
                "expired" -> EXPIRED
                "revoked" -> REVOKED
                else -> throw IllegalArgumentException("Unknown support grant status: $value")
            }
    }
}
