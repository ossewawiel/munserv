package com.munserv.issues.domain

/**
 * Sealed class representing the lifecycle states of an issue.
 * Each state defines its valid transitions and properties.
 *
 * State machine:
 * ```
 * Reported → Confirmed → InProgress → Fixed
 *    ↓          ↓            ↓          ↓
 * Rejected  Rejected    Rejected   Reopened → Confirmed
 * ```
 */
sealed class IssueState {
    /**
     * Set of states this state can transition to.
     */
    abstract val allowedTransitions: Set<IssueState>

    /**
     * Whether this state represents an open (active) issue.
     */
    abstract val isOpen: Boolean

    /**
     * Whether this state represents a closed (resolved) issue.
     */
    val isClosed: Boolean get() = !isOpen

    /**
     * Check if this state can transition to the given new state.
     */
    fun canTransitionTo(newState: IssueState): Boolean = allowedTransitions.contains(newState)

    /**
     * Returns the API string representation (snake_case).
     */
    abstract fun toApiString(): String

    /**
     * Initial state when an issue is first reported by a member.
     */
    data object Reported : IssueState() {
        override val allowedTransitions: Set<IssueState> by lazy { setOf(Confirmed, Rejected) }
        override val isOpen: Boolean = true

        override fun toApiString(): String = "reported"
    }

    /**
     * Issue has been reviewed and confirmed as valid by admin.
     */
    data object Confirmed : IssueState() {
        override val allowedTransitions: Set<IssueState> by lazy { setOf(InProgress, Rejected) }
        override val isOpen: Boolean = true

        override fun toApiString(): String = "confirmed"
    }

    /**
     * Work is actively being done to resolve the issue.
     */
    data object InProgress : IssueState() {
        override val allowedTransitions: Set<IssueState> by lazy { setOf(Fixed, Rejected) }
        override val isOpen: Boolean = true

        override fun toApiString(): String = "in_progress"
    }

    /**
     * Issue has been resolved.
     */
    data object Fixed : IssueState() {
        override val allowedTransitions: Set<IssueState> by lazy { setOf(Reopened) }
        override val isOpen: Boolean = false

        override fun toApiString(): String = "fixed"
    }

    /**
     * Issue was rejected (invalid, duplicate, out of scope, etc.).
     * This is a terminal state.
     */
    data object Rejected : IssueState() {
        override val allowedTransitions: Set<IssueState> = emptySet()
        override val isOpen: Boolean = false

        override fun toApiString(): String = "rejected"
    }

    /**
     * Previously fixed issue has been reopened.
     */
    data object Reopened : IssueState() {
        override val allowedTransitions: Set<IssueState> by lazy { setOf(Confirmed) }
        override val isOpen: Boolean = true

        override fun toApiString(): String = "reopened"
    }

    companion object {
        /**
         * All possible issue states.
         */
        val entries: List<IssueState> =
            listOf(
                Reported,
                Confirmed,
                InProgress,
                Fixed,
                Rejected,
                Reopened,
            )

        /**
         * Parse a state from its API string representation.
         * @throws IllegalArgumentException if the value doesn't match any state
         */
        fun fromString(value: String): IssueState =
            when (value.lowercase()) {
                "reported" -> Reported
                "confirmed" -> Confirmed
                "in_progress" -> InProgress
                "fixed" -> Fixed
                "rejected" -> Rejected
                "reopened" -> Reopened
                else -> throw IllegalArgumentException("Unknown issue state: $value")
            }
    }
}
