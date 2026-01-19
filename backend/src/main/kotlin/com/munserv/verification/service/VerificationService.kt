package com.munserv.verification.service

import com.munserv.auth.repository.MemberRepository
import com.munserv.issues.domain.Issue
import com.munserv.issues.domain.IssueId
import com.munserv.issues.domain.IssueState
import com.munserv.issues.repository.IssueRepository
import com.munserv.messages.service.MessageFactory
import com.munserv.messages.service.MessageService
import com.munserv.sectors.service.SectorSettingsResult
import com.munserv.sectors.service.SectorSettingsService
import com.munserv.shared.enums.GroundAdminStatus
import com.munserv.shared.enums.VerificationMode
import com.munserv.shared.types.MemberId
import com.munserv.verification.api.IssueVerificationResponse
import com.munserv.verification.api.PendingVerificationResponse
import com.munserv.verification.api.PendingVerificationsResponse
import com.munserv.verification.api.RequestVerificationRequest
import com.munserv.verification.api.SubmitVerificationRequest
import com.munserv.verification.api.VerificationHistoryResponse
import com.munserv.verification.domain.IssueVerification
import com.munserv.verification.domain.IssueVerificationId
import com.munserv.verification.domain.VerificationOutcome
import com.munserv.verification.domain.VerificationStatus
import com.munserv.verification.domain.VerificationType
import com.munserv.verification.repository.IssueVerificationRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

/**
 * Service for managing the issue verification workflow.
 *
 * Handles:
 * - Requesting verifications (admin or automatic)
 * - Submitting verification results (Ground Admins)
 * - Issue state changes based on verification results
 * - Admin overrides
 */
@Service
class VerificationService(
    private val verificationRepository: IssueVerificationRepository,
    private val issueRepository: IssueRepository,
    private val memberRepository: MemberRepository,
    private val sectorSettingsService: SectorSettingsService,
    private val messageService: MessageService,
) {
    /**
     * Request verification from Ground Admins (manual admin trigger).
     */
    @Transactional
    fun requestVerification(
        issueId: IssueId,
        request: RequestVerificationRequest,
        requestedBy: MemberId,
    ): VerificationResult {
        val errors = request.validate()
        if (errors.isNotEmpty()) {
            return VerificationResult.ValidationError(errors)
        }

        val issue =
            issueRepository.findById(issueId)
                ?: return VerificationResult.NotFound("Issue not found")

        val validationError = validateStateForVerification(issue, request.toVerificationType())
        if (validationError != null) {
            return validationError
        }

        if (verificationRepository.existsByIssueIdAndVerificationTypeAndStatus(
                issueId,
                request.toVerificationType(),
                VerificationStatus.PENDING,
            )
        ) {
            return VerificationResult.Conflict("Pending verification already exists")
        }

        val assignTo = request.assignTo?.let { MemberId.fromString(it) }
        val verification =
            when (request.toVerificationType()) {
                VerificationType.EXISTENCE -> IssueVerification.createExistenceVerification(issueId, assignTo)
                VerificationType.FIX -> IssueVerification.createFixVerification(issueId, assignTo)
            }
        val saved = verificationRepository.save(verification)

        sendVerificationMessages(issue, saved, assignTo, request.message)

        return VerificationResult.Success(IssueVerificationResponse.from(saved))
    }

    /**
     * Automatically trigger verification based on sector settings.
     * Called when issue state changes.
     */
    @Transactional
    fun triggerAutoVerification(
        issue: Issue,
        verificationType: VerificationType,
    ) {
        val settingsResult = sectorSettingsService.getSettings(issue.sectorId)
        if (settingsResult !is SectorSettingsResult.Success) return

        val settings = settingsResult.settings
        val mode =
            if (verificationType == VerificationType.EXISTENCE) {
                settings.newIssueVerificationMode
            } else {
                settings.fixVerificationMode
            }

        val verification =
            when (verificationType) {
                VerificationType.EXISTENCE -> IssueVerification.createExistenceVerification(issue.id)
                VerificationType.FIX -> IssueVerification.createFixVerification(issue.id)
            }
        val saved = verificationRepository.save(verification)

        when (mode) {
            VerificationMode.ALL_NOTIFIED -> notifyAllGroundAdmins(issue, saved)
            VerificationMode.FIRST_COME -> notifyAllGroundAdmins(issue, saved)
            VerificationMode.NEAREST_AUTO -> notifyAllGroundAdmins(issue, saved)
            VerificationMode.ADMIN_ASSIGNS -> {
                // Don't send messages, admin will assign manually
            }
        }
    }

    /**
     * Submit verification result (Ground Admin).
     */
    @Transactional
    fun submitVerification(
        issueId: IssueId,
        request: SubmitVerificationRequest,
        verifiedBy: MemberId,
    ): VerificationResult {
        val errors = request.validate()
        if (errors.isNotEmpty()) {
            return VerificationResult.ValidationError(errors)
        }

        val verificationId = IssueVerificationId.fromString(request.verificationId)
        val verification =
            verificationRepository.findById(verificationId)
                ?: return VerificationResult.NotFound("Verification not found")

        if (verification.issueId != issueId) {
            return VerificationResult.NotFound("Verification not found")
        }

        if (!verification.isPending) {
            return VerificationResult.Conflict("Verification already completed")
        }

        val member =
            memberRepository.findById(verifiedBy)
                ?: return VerificationResult.NotFound("Member not found")

        if (!member.isGroundAdmin || member.groundAdminStatus != GroundAdminStatus.ACTIVE) {
            return VerificationResult.Forbidden("Not an active Ground Admin")
        }

        if (verification.assignedTo != null && verification.assignedTo != verifiedBy) {
            return VerificationResult.Forbidden("This verification is assigned to another Ground Admin")
        }

        val completed =
            verification.complete(
                verifiedBy = verifiedBy,
                outcome = request.toOutcome(),
                reason = request.toReason(),
                note = request.note,
                photoId = request.photoId?.let { java.util.UUID.fromString(it) },
            )
        verificationRepository.save(completed)

        updateIssueState(completed)

        return VerificationResult.Success(IssueVerificationResponse.from(completed, member.fullName))
    }

    /**
     * Get verification history for an issue.
     */
    fun getVerificationHistory(issueId: IssueId): VerificationHistoryResponse {
        val verifications = verificationRepository.findByIssueId(issueId)
        val items =
            verifications.map { v ->
                val verifierName =
                    v.verifiedBy?.let {
                        memberRepository.findById(it)?.fullName
                    }
                IssueVerificationResponse.from(v, verifierName)
            }
        return VerificationHistoryResponse(items = items)
    }

    /**
     * Get pending verifications for a Ground Admin.
     */
    fun getPendingVerifications(memberId: MemberId): VerificationResult {
        val member =
            memberRepository.findById(memberId)
                ?: return VerificationResult.NotFound("Member not found")

        if (!member.isGroundAdmin) {
            return VerificationResult.Success(PendingVerificationsResponse(items = emptyList()))
        }

        val verifications =
            verificationRepository.findPendingForGroundAdmin(
                member.sectorId,
                memberId,
            )

        val items =
            verifications.mapNotNull { v ->
                val issue = issueRepository.findById(v.issueId) ?: return@mapNotNull null
                PendingVerificationResponse(
                    verificationId = v.id.toString(),
                    issueId = v.issueId.toString(),
                    issueType = issue.type.toApiString(),
                    issueDescription = issue.description,
                    verificationType = v.verificationType.toDbValue(),
                    latitude = issue.location.latitude,
                    longitude = issue.location.longitude,
                    requestedAt = v.requestedAt,
                    distance = null,
                )
            }

        return VerificationResult.Success(PendingVerificationsResponse(items = items))
    }

    // ==================== Admin Override ====================

    /**
     * Admin directly changes issue state (bypassing verification).
     */
    @Transactional
    fun adminOverrideState(
        issueId: IssueId,
        newState: IssueState,
        adminId: MemberId,
    ): VerificationResult {
        val issue =
            issueRepository.findById(issueId)
                ?: return VerificationResult.NotFound("Issue not found")

        val pendingVerifications =
            verificationRepository.findByIssueIdAndStatus(
                issueId,
                VerificationStatus.PENDING,
            )
        val expiredVerifications = pendingVerifications.map { it.expire() }
        verificationRepository.saveAll(expiredVerifications)

        val updated = issue.withState(newState)
        issueRepository.save(updated)

        return VerificationResult.Success(Unit)
    }

    // ==================== Private Helpers ====================

    private fun validateStateForVerification(
        issue: Issue,
        type: VerificationType,
    ): VerificationResult? =
        when (type) {
            VerificationType.EXISTENCE -> {
                if (issue.state != IssueState.Reported) {
                    VerificationResult.ValidationError(listOf("Issue must be in REPORTED state for existence verification"))
                } else {
                    null
                }
            }
            VerificationType.FIX -> {
                if (issue.state != IssueState.Fixed) {
                    VerificationResult.ValidationError(listOf("Issue must be in FIXED state for fix verification"))
                } else {
                    null
                }
            }
        }

    @Suppress("UNUSED_PARAMETER")
    private fun sendVerificationMessages(
        issue: Issue,
        verification: IssueVerification,
        assignTo: MemberId?,
        customMessage: String?,
    ) {
        if (assignTo != null) {
            val message = createVerificationMessage(issue, verification, assignTo.value)
            messageService.createMessage(message)
        } else {
            notifyAllGroundAdmins(issue, verification)
        }
    }

    private fun notifyAllGroundAdmins(
        issue: Issue,
        verification: IssueVerification,
    ) {
        val groundAdmins =
            memberRepository.findBySectorIdAndIsGroundAdminAndGroundAdminStatus(
                issue.sectorId,
                true,
                GroundAdminStatus.ACTIVE,
            )

        groundAdmins.forEach { ga ->
            val message = createVerificationMessage(issue, verification, ga.id.value)
            messageService.createMessage(message)
        }
    }

    private fun createVerificationMessage(
        issue: Issue,
        verification: IssueVerification,
        recipientId: java.util.UUID,
    ) = if (verification.isExistenceVerification) {
        MessageFactory.verifyNewIssue(
            recipientId = recipientId,
            issueId = issue.id.value,
            issueType = issue.type.toApiString(),
            issueDescription = issue.description,
            verificationId = verification.id.value,
        )
    } else {
        MessageFactory.verifyFix(
            recipientId = recipientId,
            issueId = issue.id.value,
            issueType = issue.type.toApiString(),
            verificationId = verification.id.value,
        )
    }

    private fun updateIssueState(verification: IssueVerification) {
        val issue = issueRepository.findById(verification.issueId) ?: return

        when {
            verification.isExistenceVerification && verification.outcome == VerificationOutcome.CONFIRMED -> {
                val updated = issue.withState(IssueState.Confirmed)
                issueRepository.save(updated)
            }
            verification.isExistenceVerification && verification.outcome == VerificationOutcome.NOT_FOUND -> {
                val updated = issue.withState(IssueState.Rejected)
                issueRepository.save(updated)
            }
            verification.isFixVerification && verification.outcome == VerificationOutcome.NOT_FIXED -> {
                val updated = issue.withState(IssueState.Reopened)
                issueRepository.save(updated)
            }
            // RESULT_CONFIRMED for fix verification: stay in FIXED, will auto-close later
            // RESULT_CANNOT_VERIFY: no state change, may need to reassign
        }
    }
}
