package com.munserv.verification.api

import com.munserv.issues.domain.IssueId
import com.munserv.issues.domain.IssueState
import com.munserv.shared.api.ErrorBody
import com.munserv.shared.api.ErrorCodes
import com.munserv.shared.api.ErrorResponse
import com.munserv.shared.types.MemberId
import com.munserv.verification.service.VerificationResult
import com.munserv.verification.service.VerificationService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.responses.ApiResponse
import io.swagger.v3.oas.annotations.responses.ApiResponses
import io.swagger.v3.oas.annotations.security.SecurityRequirement
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

/**
 * REST controller for issue verification workflow.
 *
 * Admin endpoints:
 * - Request verification for an issue
 * - Override issue state directly
 *
 * Ground Admin endpoints:
 * - Submit verification result
 * - Get pending verifications
 *
 * General endpoints:
 * - Get verification history for an issue
 */
@RestController
@RequestMapping("/api/v1")
@Tag(name = "Verifications", description = "Issue verification workflow")
@SecurityRequirement(name = "bearerAuth")
class VerificationController(
    private val verificationService: VerificationService,
) {
    // ==================== Admin Endpoints ====================

    @Operation(
        summary = "Request verification for an issue",
        description = "Admin requests Ground Admins to verify an issue exists or fix is complete",
    )
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "Verification requested"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "404", description = "Issue not found"),
            ApiResponse(responseCode = "409", description = "Pending verification already exists"),
        ],
    )
    @PostMapping("/issues/{issueId}/request-verification")
    fun requestVerification(
        @Parameter(description = "Issue UUID")
        @PathVariable issueId: UUID,
        @RequestBody request: RequestVerificationRequest,
        @AuthenticationPrincipal memberId: String?,
    ): ResponseEntity<*> {
        val memberIdValue = parseMemberId(memberId) ?: return unauthorizedResponse()
        val issueIdValue = IssueId(issueId)

        return when (val result = verificationService.requestVerification(issueIdValue, request, memberIdValue)) {
            is VerificationResult.Success -> ResponseEntity.ok(result.data)
            is VerificationResult.NotFound -> notFoundResponse(result.message)
            is VerificationResult.Conflict -> conflictResponse(result.message)
            is VerificationResult.Forbidden -> forbiddenResponse(result.message)
            is VerificationResult.ValidationError -> validationErrorResponse(result.errors)
        }
    }

    @Operation(
        summary = "Override issue state",
        description = "Admin directly changes issue state, bypassing verification",
    )
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "State updated"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "404", description = "Issue not found"),
        ],
    )
    @PostMapping("/issues/{issueId}/override-state")
    fun overrideState(
        @Parameter(description = "Issue UUID")
        @PathVariable issueId: UUID,
        @RequestBody request: OverrideStateRequest,
        @AuthenticationPrincipal memberId: String?,
    ): ResponseEntity<*> {
        val memberIdValue = parseMemberId(memberId) ?: return unauthorizedResponse()
        val issueIdValue = IssueId(issueId)
        val newState = IssueState.fromString(request.state)

        return when (val result = verificationService.adminOverrideState(issueIdValue, newState, memberIdValue)) {
            is VerificationResult.Success -> ResponseEntity.ok(mapOf("status" to "updated"))
            is VerificationResult.NotFound -> notFoundResponse(result.message)
            is VerificationResult.Conflict -> conflictResponse(result.message)
            is VerificationResult.Forbidden -> forbiddenResponse(result.message)
            is VerificationResult.ValidationError -> validationErrorResponse(result.errors)
        }
    }

    // ==================== Ground Admin Endpoints ====================

    @Operation(
        summary = "Submit verification result",
        description = "Ground Admin submits verification result for an issue",
    )
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "Verification submitted"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "403", description = "Not an active Ground Admin"),
            ApiResponse(responseCode = "404", description = "Verification not found"),
            ApiResponse(responseCode = "409", description = "Verification already completed"),
        ],
    )
    @PostMapping("/issues/{issueId}/verify")
    fun submitVerification(
        @Parameter(description = "Issue UUID")
        @PathVariable issueId: UUID,
        @RequestBody request: SubmitVerificationRequest,
        @AuthenticationPrincipal memberId: String?,
    ): ResponseEntity<*> {
        val memberIdValue = parseMemberId(memberId) ?: return unauthorizedResponse()
        val issueIdValue = IssueId(issueId)

        return when (val result = verificationService.submitVerification(issueIdValue, request, memberIdValue)) {
            is VerificationResult.Success -> ResponseEntity.ok(result.data)
            is VerificationResult.NotFound -> notFoundResponse(result.message)
            is VerificationResult.Conflict -> conflictResponse(result.message)
            is VerificationResult.Forbidden -> forbiddenResponse(result.message)
            is VerificationResult.ValidationError -> validationErrorResponse(result.errors)
        }
    }

    @Operation(
        summary = "Get pending verifications",
        description = "Get list of pending verifications for the current Ground Admin",
    )
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "Pending verifications retrieved"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "404", description = "Member not found"),
        ],
    )
    @GetMapping("/members/me/pending-verifications")
    fun getPendingVerifications(
        @AuthenticationPrincipal memberId: String?,
    ): ResponseEntity<*> {
        val memberIdValue = parseMemberId(memberId) ?: return unauthorizedResponse()

        return when (val result = verificationService.getPendingVerifications(memberIdValue)) {
            is VerificationResult.Success -> ResponseEntity.ok(result.data)
            is VerificationResult.NotFound -> notFoundResponse(result.message)
            is VerificationResult.Conflict -> conflictResponse(result.message)
            is VerificationResult.Forbidden -> forbiddenResponse(result.message)
            is VerificationResult.ValidationError -> validationErrorResponse(result.errors)
        }
    }

    // ==================== General Endpoints ====================

    @Operation(
        summary = "Get verification history",
        description = "Get verification history for an issue",
    )
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "Verification history retrieved"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
        ],
    )
    @GetMapping("/issues/{issueId}/verifications")
    fun getVerificationHistory(
        @Parameter(description = "Issue UUID")
        @PathVariable issueId: UUID,
        @AuthenticationPrincipal memberId: String?,
    ): ResponseEntity<*> {
        if (parseMemberId(memberId) == null) {
            return unauthorizedResponse()
        }

        val issueIdValue = IssueId(issueId)
        val response = verificationService.getVerificationHistory(issueIdValue)
        return ResponseEntity.ok(response)
    }

    // ==================== Helpers ====================

    private fun parseMemberId(memberId: String?): MemberId? =
        try {
            memberId?.let { MemberId(UUID.fromString(it)) }
        } catch (e: IllegalArgumentException) {
            null
        }

    private fun unauthorizedResponse(): ResponseEntity<ErrorResponse> =
        ResponseEntity.status(HttpStatus.UNAUTHORIZED)
            .body(ErrorResponse(ErrorBody(ErrorCodes.UNAUTHORIZED, "Authentication required")))

    private fun notFoundResponse(message: String): ResponseEntity<ErrorResponse> =
        ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(ErrorResponse(ErrorBody(ErrorCodes.NOT_FOUND, message)))

    private fun conflictResponse(message: String): ResponseEntity<ErrorResponse> =
        ResponseEntity.status(HttpStatus.CONFLICT)
            .body(ErrorResponse(ErrorBody(ErrorCodes.CONFLICT, message)))

    private fun forbiddenResponse(message: String): ResponseEntity<ErrorResponse> =
        ResponseEntity.status(HttpStatus.FORBIDDEN)
            .body(ErrorResponse(ErrorBody(ErrorCodes.FORBIDDEN, message)))

    private fun validationErrorResponse(errors: List<String>): ResponseEntity<ErrorResponse> =
        ResponseEntity.status(HttpStatus.BAD_REQUEST)
            .body(ErrorResponse(ErrorBody(ErrorCodes.VALIDATION_ERROR, errors.joinToString(", "))))
}
