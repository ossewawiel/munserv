package com.munserv.issues.repository

import com.munserv.issues.domain.IssueId
import com.munserv.issues.domain.IssueStateHistoryEntry
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.util.UUID

/**
 * Spring Data JPA repository for IssueStateHistoryEntity.
 */
interface IssueStateHistoryJpaRepository : JpaRepository<IssueStateHistoryEntity, UUID> {
    fun findByIssueIdOrderByChangedAtAsc(issueId: UUID): List<IssueStateHistoryEntity>
}

/**
 * Domain-level repository interface for issue state history.
 */
interface IssueStateHistoryRepository {
    fun save(entry: IssueStateHistoryEntry): IssueStateHistoryEntry

    fun findByIssueId(issueId: IssueId): List<IssueStateHistoryEntry>
}

/**
 * JPA implementation of IssueStateHistoryRepository.
 * Converts between domain and JPA entity representations.
 */
@Repository
class JpaIssueStateHistoryRepository(
    private val jpa: IssueStateHistoryJpaRepository,
) : IssueStateHistoryRepository {
    override fun save(entry: IssueStateHistoryEntry): IssueStateHistoryEntry =
        jpa.save(IssueStateHistoryEntity.fromDomain(entry)).toDomain()

    override fun findByIssueId(issueId: IssueId): List<IssueStateHistoryEntry> =
        jpa.findByIssueIdOrderByChangedAtAsc(issueId.value).map { it.toDomain() }
}
