package com.munserv.issues.domain

import com.munserv.shared.types.AdminId
import java.time.Instant

/**
 * Domain model representing a state change entry in an issue's history.
 * Each state transition is recorded for audit trail purposes.
 */
data class IssueStateHistoryEntry(
    val id: IssueStateHistoryId,
    val issueId: IssueId,
    val state: IssueState,
    val changedAt: Instant,
    val changedBy: AdminId?,
    val note: String?,
)
