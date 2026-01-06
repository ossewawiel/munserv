package com.munserv.issues.domain

import java.util.UUID

/**
 * Type-safe wrapper for Issue IDs.
 * Prevents accidentally mixing issue IDs with other UUID types.
 */
@JvmInline
value class IssueId(val value: UUID) {
    override fun toString(): String = value.toString()

    companion object {
        fun fromString(value: String): IssueId = IssueId(UUID.fromString(value))

        fun generate(): IssueId = IssueId(UUID.randomUUID())
    }
}
