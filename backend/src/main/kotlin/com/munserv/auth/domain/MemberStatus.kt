package com.munserv.auth.domain

/**
 * Sealed class representing member account status.
 * Defines valid status transitions.
 */
sealed class MemberStatus {
    abstract val allowedTransitions: Set<MemberStatus>

    fun canTransitionTo(newStatus: MemberStatus): Boolean = allowedTransitions.contains(newStatus)

    object PendingApproval : MemberStatus() {
        override val allowedTransitions: Set<MemberStatus> = setOf(Active, Deleted)

        override fun toString(): String = "pending_approval"
    }

    object Active : MemberStatus() {
        override val allowedTransitions: Set<MemberStatus> = setOf(Suspended, Deleted)

        override fun toString(): String = "active"
    }

    object Suspended : MemberStatus() {
        override val allowedTransitions: Set<MemberStatus> = setOf(Active, Deleted)

        override fun toString(): String = "suspended"
    }

    object Deleted : MemberStatus() {
        override val allowedTransitions: Set<MemberStatus> = emptySet()

        override fun toString(): String = "deleted"
    }

    companion object {
        fun fromString(value: String): MemberStatus =
            when (value.lowercase()) {
                "pending_approval" -> PendingApproval
                "active" -> Active
                "suspended" -> Suspended
                "deleted" -> Deleted
                else -> throw IllegalArgumentException("Unknown member status: $value")
            }
    }
}
