package com.munserv.issues.domain

import java.util.UUID

/**
 * Value class for IssueStateHistory IDs to ensure type safety.
 */
@JvmInline
value class IssueStateHistoryId(val value: UUID) {
    companion object {
        fun generate(): IssueStateHistoryId = IssueStateHistoryId(UUID.randomUUID())
    }
}
