package com.munserv.verification.repository

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import java.util.UUID

/**
 * Spring Data JPA repository for Issue Verification entities.
 */
@Repository
interface JpaIssueVerificationRepository : JpaRepository<IssueVerificationEntity, UUID> {
    fun findByIssueId(issueId: UUID): List<IssueVerificationEntity>

    fun findByIssueIdAndStatus(
        issueId: UUID,
        status: String,
    ): List<IssueVerificationEntity>

    fun findByAssignedToAndStatus(
        assignedTo: UUID,
        status: String,
    ): List<IssueVerificationEntity>

    @Query(
        """
        SELECT v FROM IssueVerificationEntity v
        JOIN com.munserv.issues.repository.IssueEntity i ON i.id = v.issueId
        WHERE i.sectorId = :sectorId
        AND v.status = 'pending'
        AND (v.assignedTo = :memberId OR v.assignedTo IS NULL)
        """,
    )
    fun findPendingForGroundAdmin(
        sectorId: UUID,
        memberId: UUID,
    ): List<IssueVerificationEntity>

    @Query(
        """
        SELECT COUNT(v) FROM IssueVerificationEntity v
        WHERE v.assignedTo = :memberId
        AND v.status = 'pending'
        """,
    )
    fun countPendingForMember(memberId: UUID): Long

    @Query(
        """
        SELECT COUNT(v) FROM IssueVerificationEntity v
        WHERE v.verifiedBy = :memberId
        AND v.status = 'completed'
        """,
    )
    fun countCompletedByMember(memberId: UUID): Long

    fun existsByIssueIdAndVerificationTypeAndStatus(
        issueId: UUID,
        verificationType: String,
        status: String,
    ): Boolean
}
