package com.munserv.issues.repository

import com.munserv.issues.domain.IssueId
import com.munserv.issues.domain.IssueState
import com.munserv.issues.domain.IssueStateHistoryEntry
import com.munserv.issues.domain.IssueStateHistoryId
import com.munserv.shared.types.AdminId
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import org.hibernate.annotations.ColumnTransformer
import java.time.Instant
import java.util.UUID

/**
 * JPA Entity for issue_state_history table.
 * Converts between database representation and domain model.
 */
@Entity
@Table(name = "issue_state_history")
class IssueStateHistoryEntity(
    @Id
    val id: UUID,
    @Column(name = "issue_id", nullable = false)
    val issueId: UUID,
    @Column(nullable = false, columnDefinition = "issue_state")
    @ColumnTransformer(write = "?::issue_state")
    val state: String,
    @Column(name = "changed_at", nullable = false)
    val changedAt: Instant,
    @Column(name = "changed_by")
    val changedBy: UUID?,
    @Column
    val note: String?,
) {
    /**
     * Convert JPA entity to domain model.
     */
    fun toDomain(): IssueStateHistoryEntry =
        IssueStateHistoryEntry(
            id = IssueStateHistoryId(id),
            issueId = IssueId(issueId),
            state = IssueState.fromString(state),
            changedAt = changedAt,
            changedBy = changedBy?.let { AdminId(it) },
            note = note,
        )

    companion object {
        /**
         * Convert domain model to JPA entity.
         */
        fun fromDomain(entry: IssueStateHistoryEntry): IssueStateHistoryEntity =
            IssueStateHistoryEntity(
                id = entry.id.value,
                issueId = entry.issueId.value,
                state = entry.state.toApiString(),
                changedAt = entry.changedAt,
                changedBy = entry.changedBy?.value,
                note = entry.note,
            )
    }
}
