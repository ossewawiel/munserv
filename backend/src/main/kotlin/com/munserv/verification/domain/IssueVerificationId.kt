package com.munserv.verification.domain

import java.util.UUID

/**
 * Type-safe wrapper for Issue Verification IDs.
 * Prevents accidentally mixing verification IDs with other UUID types.
 */
@JvmInline
value class IssueVerificationId(
    val value: UUID,
) {
    override fun toString(): String = value.toString()

    companion object {
        fun fromString(value: String): IssueVerificationId = IssueVerificationId(UUID.fromString(value))

        fun generate(): IssueVerificationId = IssueVerificationId(UUID.randomUUID())
    }
}
