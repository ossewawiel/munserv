package com.munserv.verification.repository

import com.munserv.issues.domain.IssueId
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import com.munserv.verification.domain.IssueVerification
import com.munserv.verification.domain.IssueVerificationId
import com.munserv.verification.domain.VerificationStatus
import com.munserv.verification.domain.VerificationType

/**
 * Domain repository interface for Issue Verifications.
 * Implementations handle data access details.
 */
interface IssueVerificationRepository {
    fun findById(id: IssueVerificationId): IssueVerification?

    fun findByIssueId(issueId: IssueId): List<IssueVerification>

    fun findByIssueIdAndStatus(
        issueId: IssueId,
        status: VerificationStatus,
    ): List<IssueVerification>

    fun findByAssignedToAndStatus(
        assignedTo: MemberId,
        status: VerificationStatus,
    ): List<IssueVerification>

    fun findPendingForGroundAdmin(
        sectorId: SectorId,
        memberId: MemberId,
    ): List<IssueVerification>

    fun countPendingForMember(memberId: MemberId): Long

    fun countCompletedByMember(memberId: MemberId): Long

    fun existsByIssueIdAndVerificationTypeAndStatus(
        issueId: IssueId,
        verificationType: VerificationType,
        status: VerificationStatus,
    ): Boolean

    fun save(verification: IssueVerification): IssueVerification

    fun saveAll(verifications: List<IssueVerification>): List<IssueVerification>
}
