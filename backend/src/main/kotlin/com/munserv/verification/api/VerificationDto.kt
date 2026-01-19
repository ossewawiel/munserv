package com.munserv.verification.api

import com.munserv.shared.enums.VerificationReason
import com.munserv.verification.domain.IssueVerification
import com.munserv.verification.domain.VerificationOutcome
import com.munserv.verification.domain.VerificationType
import java.time.Instant

// ==================== Request DTOs ====================

/**
 * Request to initiate a verification (admin only).
 */
data class RequestVerificationRequest(
    val type: String,
    val assignTo: String? = null,
    val message: String? = null,
) {
    fun validate(): List<String> {
        val errors = mutableListOf<String>()
        if (type !in listOf("existence", "fix")) {
            errors.add("type must be 'existence' or 'fix'")
        }
        return errors
    }

    fun toVerificationType(): VerificationType = VerificationType.fromString(type)
}

/**
 * Request to submit a verification result (Ground Admin).
 */
data class SubmitVerificationRequest(
    val verificationId: String,
    val result: String,
    val reason: String? = null,
    val note: String? = null,
    val photoId: String? = null,
) {
    fun validate(): List<String> {
        val errors = mutableListOf<String>()
        val validResults = listOf("confirmed", "not_found", "not_fixed", "cannot_verify")
        if (result !in validResults) {
            errors.add("result must be one of: $validResults")
        }
        if (result == "cannot_verify" && reason == null) {
            errors.add("reason is required when result is 'cannot_verify'")
        }
        return errors
    }

    fun toOutcome(): VerificationOutcome = VerificationOutcome.fromString(result)

    fun toReason(): VerificationReason? = reason?.let { VerificationReason.fromString(it) }
}

/**
 * Request to override issue state (admin only).
 */
data class OverrideStateRequest(
    val state: String,
)

// ==================== Response DTOs ====================

/**
 * Response for a single verification.
 */
data class IssueVerificationResponse(
    val id: String,
    val issueId: String,
    val verificationType: String,
    val assignedTo: String?,
    val verifiedBy: String?,
    val verifiedByName: String?,
    val result: String?,
    val reason: String?,
    val note: String?,
    val photoId: String?,
    val requestedAt: Instant,
    val respondedAt: Instant?,
    val status: String,
) {
    companion object {
        fun from(
            verification: IssueVerification,
            verifierName: String? = null,
        ) = IssueVerificationResponse(
            id = verification.id.toString(),
            issueId = verification.issueId.toString(),
            verificationType = verification.verificationType.toDbValue(),
            assignedTo = verification.assignedTo?.toString(),
            verifiedBy = verification.verifiedBy?.toString(),
            verifiedByName = verifierName,
            result = verification.outcome?.toDbValue(),
            reason = verification.reason?.toApiString(),
            note = verification.note,
            photoId = verification.photoId?.toString(),
            requestedAt = verification.requestedAt,
            respondedAt = verification.respondedAt,
            status = verification.status.toDbValue(),
        )
    }
}

/**
 * Response for a pending verification with issue context.
 */
data class PendingVerificationResponse(
    val verificationId: String,
    val issueId: String,
    val issueType: String,
    val issueDescription: String?,
    val verificationType: String,
    val latitude: Double,
    val longitude: Double,
    val requestedAt: Instant,
    val distance: Double? = null,
)

/**
 * Response for verification history.
 */
data class VerificationHistoryResponse(
    val items: List<IssueVerificationResponse>,
)

/**
 * Response for pending verifications list.
 */
data class PendingVerificationsResponse(
    val items: List<PendingVerificationResponse>,
)
