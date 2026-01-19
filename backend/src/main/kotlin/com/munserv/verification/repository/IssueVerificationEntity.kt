package com.munserv.verification.repository

import com.munserv.issues.domain.IssueId
import com.munserv.shared.enums.VerificationReason
import com.munserv.shared.types.MemberId
import com.munserv.verification.domain.IssueVerification
import com.munserv.verification.domain.IssueVerificationId
import com.munserv.verification.domain.VerificationOutcome
import com.munserv.verification.domain.VerificationStatus
import com.munserv.verification.domain.VerificationType
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.time.Instant
import java.util.UUID

/**
 * JPA entity for issue_verifications table.
 */
@Entity
@Table(name = "issue_verifications")
class IssueVerificationEntity(
    @Id
    val id: UUID,
    @Column(name = "issue_id", nullable = false)
    val issueId: UUID,
    @Column(name = "verification_type", nullable = false, length = 20)
    val verificationType: String,
    @Column(name = "assigned_to")
    val assignedTo: UUID? = null,
    @Column(name = "verified_by")
    val verifiedBy: UUID? = null,
    @Column(name = "result", length = 20)
    val outcome: String? = null,
    @Column(name = "reason", length = 50)
    val reason: String? = null,
    @Column(name = "note", columnDefinition = "TEXT")
    val note: String? = null,
    @Column(name = "photo_id")
    val photoId: UUID? = null,
    @Column(name = "requested_at", nullable = false)
    val requestedAt: Instant = Instant.now(),
    @Column(name = "responded_at")
    val respondedAt: Instant? = null,
    @Column(name = "status", nullable = false, length = 20)
    val status: String = "pending",
) {
    fun toDomain(): IssueVerification =
        IssueVerification(
            id = IssueVerificationId(id),
            issueId = IssueId(issueId),
            verificationType = VerificationType.fromString(verificationType),
            assignedTo = assignedTo?.let { MemberId(it) },
            verifiedBy = verifiedBy?.let { MemberId(it) },
            outcome = outcome?.let { VerificationOutcome.fromString(it) },
            reason = reason?.let { VerificationReason.fromString(it) },
            note = note,
            photoId = photoId,
            requestedAt = requestedAt,
            respondedAt = respondedAt,
            status = VerificationStatus.fromString(status),
        )

    companion object {
        fun fromDomain(verification: IssueVerification): IssueVerificationEntity =
            IssueVerificationEntity(
                id = verification.id.value,
                issueId = verification.issueId.value,
                verificationType = verification.verificationType.toDbValue(),
                assignedTo = verification.assignedTo?.value,
                verifiedBy = verification.verifiedBy?.value,
                outcome = verification.outcome?.toDbValue(),
                reason = verification.reason?.toApiString(),
                note = verification.note,
                photoId = verification.photoId,
                requestedAt = verification.requestedAt,
                respondedAt = verification.respondedAt,
                status = verification.status.toDbValue(),
            )
    }
}
