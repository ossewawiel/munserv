package com.munserv.verification.repository

import com.munserv.issues.domain.IssueId
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import com.munserv.verification.domain.IssueVerification
import com.munserv.verification.domain.IssueVerificationId
import com.munserv.verification.domain.VerificationStatus
import com.munserv.verification.domain.VerificationType
import org.springframework.data.repository.findByIdOrNull
import org.springframework.stereotype.Repository

/**
 * Default implementation of IssueVerificationRepository using JPA.
 */
@Repository
class DefaultIssueVerificationRepository(
    private val jpa: JpaIssueVerificationRepository,
) : IssueVerificationRepository {
    override fun findById(id: IssueVerificationId): IssueVerification? = jpa.findByIdOrNull(id.value)?.toDomain()

    override fun findByIssueId(issueId: IssueId): List<IssueVerification> = jpa.findByIssueId(issueId.value).map { it.toDomain() }

    override fun findByIssueIdAndStatus(
        issueId: IssueId,
        status: VerificationStatus,
    ): List<IssueVerification> = jpa.findByIssueIdAndStatus(issueId.value, status.toDbValue()).map { it.toDomain() }

    override fun findByAssignedToAndStatus(
        assignedTo: MemberId,
        status: VerificationStatus,
    ): List<IssueVerification> = jpa.findByAssignedToAndStatus(assignedTo.value, status.toDbValue()).map { it.toDomain() }

    override fun findPendingForGroundAdmin(
        sectorId: SectorId,
        memberId: MemberId,
    ): List<IssueVerification> = jpa.findPendingForGroundAdmin(sectorId.value, memberId.value).map { it.toDomain() }

    override fun countPendingForMember(memberId: MemberId): Long = jpa.countPendingForMember(memberId.value)

    override fun countCompletedByMember(memberId: MemberId): Long = jpa.countCompletedByMember(memberId.value)

    override fun existsByIssueIdAndVerificationTypeAndStatus(
        issueId: IssueId,
        verificationType: VerificationType,
        status: VerificationStatus,
    ): Boolean =
        jpa.existsByIssueIdAndVerificationTypeAndStatus(
            issueId.value,
            verificationType.toDbValue(),
            status.toDbValue(),
        )

    override fun save(verification: IssueVerification): IssueVerification =
        jpa.save(IssueVerificationEntity.fromDomain(verification)).toDomain()

    override fun saveAll(verifications: List<IssueVerification>): List<IssueVerification> =
        jpa.saveAll(verifications.map { IssueVerificationEntity.fromDomain(it) }).map { it.toDomain() }
}
