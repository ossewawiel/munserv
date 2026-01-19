package com.munserv.verification.domain

import com.munserv.issues.domain.IssueId
import com.munserv.shared.enums.VerificationReason
import com.munserv.shared.types.MemberId
import java.time.Instant
import java.util.UUID

/**
 * Domain entity representing a verification request for an issue.
 *
 * Verifications are created when:
 * - A new issue needs existence verification (existence type)
 * - A fixed issue needs fix verification (fix type)
 *
 * This is a pure domain class with no framework dependencies.
 */
data class IssueVerification(
    val id: IssueVerificationId,
    val issueId: IssueId,
    val verificationType: VerificationType,
    val assignedTo: MemberId? = null,
    val verifiedBy: MemberId? = null,
    val outcome: VerificationOutcome? = null,
    val reason: VerificationReason? = null,
    val note: String? = null,
    val photoId: UUID? = null,
    val requestedAt: Instant = Instant.now(),
    val respondedAt: Instant? = null,
    val status: VerificationStatus = VerificationStatus.PENDING,
) {
    /**
     * True if verification is still pending.
     */
    val isPending: Boolean
        get() = status == VerificationStatus.PENDING

    /**
     * True if this is an existence verification.
     */
    val isExistenceVerification: Boolean
        get() = verificationType == VerificationType.EXISTENCE

    /**
     * True if this is a fix verification.
     */
    val isFixVerification: Boolean
        get() = verificationType == VerificationType.FIX

    /**
     * Complete the verification with a result.
     */
    fun complete(
        verifiedBy: MemberId,
        outcome: VerificationOutcome,
        reason: VerificationReason? = null,
        note: String? = null,
        photoId: UUID? = null,
    ): IssueVerification =
        copy(
            verifiedBy = verifiedBy,
            outcome = outcome,
            reason = reason,
            note = note,
            photoId = photoId,
            respondedAt = Instant.now(),
            status = VerificationStatus.COMPLETED,
        )

    /**
     * Mark the verification as expired.
     */
    fun expire(): IssueVerification =
        copy(
            status = VerificationStatus.EXPIRED,
        )

    companion object {
        /**
         * Creates a new existence verification request.
         */
        fun createExistenceVerification(
            issueId: IssueId,
            assignedTo: MemberId? = null,
        ): IssueVerification =
            IssueVerification(
                id = IssueVerificationId.generate(),
                issueId = issueId,
                verificationType = VerificationType.EXISTENCE,
                assignedTo = assignedTo,
            )

        /**
         * Creates a new fix verification request.
         */
        fun createFixVerification(
            issueId: IssueId,
            assignedTo: MemberId? = null,
        ): IssueVerification =
            IssueVerification(
                id = IssueVerificationId.generate(),
                issueId = issueId,
                verificationType = VerificationType.FIX,
                assignedTo = assignedTo,
            )
    }
}
