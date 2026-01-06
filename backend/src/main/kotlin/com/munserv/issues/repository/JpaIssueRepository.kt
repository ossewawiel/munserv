package com.munserv.issues.repository

import com.munserv.issues.domain.Issue
import com.munserv.issues.domain.IssueId
import com.munserv.issues.domain.IssueState
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import jakarta.persistence.LockModeType
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Lock
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.findByIdOrNull
import org.springframework.stereotype.Repository
import java.util.UUID

/**
 * Spring Data JPA repository for IssueEntity.
 */
interface IssueJpaRepository : JpaRepository<IssueEntity, UUID> {
    fun findBySectorId(sectorId: UUID): List<IssueEntity>

    fun findByReporterId(reporterId: UUID): List<IssueEntity>

    fun findByState(state: String): List<IssueEntity>

    @Query(
        """
        SELECT i FROM IssueEntity i
        WHERE i.state IN ('reported', 'confirmed', 'in_progress', 'reopened')
        AND i.deletedAt IS NULL
        ORDER BY i.heat DESC, i.createdAt DESC
        """,
    )
    fun findOpenIssues(): List<IssueEntity>

    @Query("SELECT i FROM IssueEntity i WHERE i.deletedAt IS NULL ORDER BY i.createdAt DESC")
    fun findAllActive(): List<IssueEntity>

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT i FROM IssueEntity i WHERE i.id = :id")
    fun findByIdForUpdate(id: UUID): IssueEntity?
}

/**
 * Implementation of IssueRepository using Spring Data JPA.
 */
@Repository
class JpaIssueRepositoryImpl(
    private val jpa: IssueJpaRepository,
) : IssueRepository {
    override fun findById(id: IssueId): Issue? = jpa.findByIdOrNull(id.value)?.toDomain()

    override fun save(issue: Issue): Issue = jpa.save(IssueEntity.fromDomain(issue)).toDomain()

    override fun findAll(): List<Issue> = jpa.findAllActive().map { it.toDomain() }

    override fun findBySectorId(sectorId: SectorId): List<Issue> = jpa.findBySectorId(sectorId.value).map { it.toDomain() }

    override fun findByReporterId(reporterId: MemberId): List<Issue> = jpa.findByReporterId(reporterId.value).map { it.toDomain() }

    override fun findByState(state: IssueState): List<Issue> = jpa.findByState(state.toApiString()).map { it.toDomain() }

    override fun findOpenIssues(): List<Issue> = jpa.findOpenIssues().map { it.toDomain() }

    override fun findByIdForUpdate(id: IssueId): Issue? = jpa.findByIdForUpdate(id.value)?.toDomain()

    override fun deleteById(id: IssueId) {
        jpa.deleteById(id.value)
    }
}
