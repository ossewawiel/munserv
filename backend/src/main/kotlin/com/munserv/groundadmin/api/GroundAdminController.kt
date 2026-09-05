package com.munserv.groundadmin.api

import com.munserv.groundadmin.domain.GroundAdminApplicationId
import com.munserv.groundadmin.service.GroundAdminResult
import com.munserv.groundadmin.service.GroundAdminService
import com.munserv.shared.api.ErrorBody
import com.munserv.shared.api.ErrorCodes
import com.munserv.shared.api.ErrorResponse
import com.munserv.shared.enums.GroundAdminStatus
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.responses.ApiResponse
import io.swagger.v3.oas.annotations.responses.ApiResponses
import io.swagger.v3.oas.annotations.security.SecurityRequirement
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PatchMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

/**
 * REST controller for Ground Admin lifecycle operations.
 *
 * Member endpoints:
 * - Apply to become Ground Admin
 * - Accept/decline invitations
 * - Request step-down
 * - View own Ground Admin info
 *
 * Admin endpoints:
 * - Invite members to become Ground Admin
 * - Approve/decline applications
 * - Revoke Ground Admin status
 * - Update Ground Admin status (active/on_hold)
 * - List Ground Admins in sector
 */
@RestController
@RequestMapping("/api/v1")
@Tag(name = "Ground Admins", description = "Ground Admin lifecycle management")
@SecurityRequirement(name = "bearerAuth")
class GroundAdminController(
    private val groundAdminService: GroundAdminService,
) {
    // ==================== Member Endpoints ====================

    @Operation(
        summary = "Apply to become Ground Admin",
        description = "Member applies to become a Ground Admin in their sector",
    )
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "Application submitted successfully"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "404", description = "Member not found"),
            ApiResponse(responseCode = "409", description = "Already a Ground Admin or has pending application"),
        ],
    )
    @PostMapping("/members/me/ground-admin/apply")
    fun apply(
        @AuthenticationPrincipal memberId: String?,
    ): ResponseEntity<*> {
        val memberIdValue = parseMemberId(memberId) ?: return unauthorizedResponse()

        return when (val result = groundAdminService.apply(memberIdValue)) {
            is GroundAdminResult.Success -> ResponseEntity.ok(result.data)
            is GroundAdminResult.NotFound -> notFoundResponse(result.message)
            is GroundAdminResult.Conflict -> conflictResponse(result.message)
            is GroundAdminResult.Forbidden -> forbiddenResponse(result.message)
            is GroundAdminResult.ValidationError -> validationErrorResponse(result.errors)
        }
    }

    @Operation(
        summary = "Accept Ground Admin invitation",
        description = "Member accepts an invitation to become a Ground Admin",
    )
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "Invitation accepted"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "404", description = "Application not found"),
            ApiResponse(responseCode = "409", description = "Invitation already processed"),
        ],
    )
    @PostMapping("/members/me/ground-admin/accept")
    fun acceptInvitation(
        @RequestBody request: AcceptInvitationRequest,
        @AuthenticationPrincipal memberId: String?,
    ): ResponseEntity<*> {
        val memberIdValue = parseMemberId(memberId) ?: return unauthorizedResponse()
        val applicationId = GroundAdminApplicationId.fromString(request.applicationId)

        return when (val result = groundAdminService.acceptInvitation(memberIdValue, applicationId)) {
            is GroundAdminResult.Success -> ResponseEntity.ok(result.data)
            is GroundAdminResult.NotFound -> notFoundResponse(result.message)
            is GroundAdminResult.Conflict -> conflictResponse(result.message)
            is GroundAdminResult.Forbidden -> forbiddenResponse(result.message)
            is GroundAdminResult.ValidationError -> validationErrorResponse(result.errors)
        }
    }

    @Operation(
        summary = "Decline Ground Admin invitation",
        description = "Member declines an invitation to become a Ground Admin",
    )
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "Invitation declined"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "404", description = "Application not found"),
            ApiResponse(responseCode = "409", description = "Cannot decline this invitation"),
        ],
    )
    @PostMapping("/members/me/ground-admin/decline")
    fun declineInvitation(
        @RequestBody request: DeclineInvitationRequest,
        @AuthenticationPrincipal memberId: String?,
    ): ResponseEntity<*> {
        val memberIdValue = parseMemberId(memberId) ?: return unauthorizedResponse()
        val applicationId = GroundAdminApplicationId.fromString(request.applicationId)

        return when (val result = groundAdminService.declineInvitation(memberIdValue, applicationId, request.reason)) {
            is GroundAdminResult.Success -> ResponseEntity.ok(result.data)
            is GroundAdminResult.NotFound -> notFoundResponse(result.message)
            is GroundAdminResult.Conflict -> conflictResponse(result.message)
            is GroundAdminResult.Forbidden -> forbiddenResponse(result.message)
            is GroundAdminResult.ValidationError -> validationErrorResponse(result.errors)
        }
    }

    @Operation(
        summary = "Request to step down as Ground Admin",
        description = "Ground Admin requests to step down from their role",
    )
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "Step-down request submitted"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "404", description = "Member not found"),
            ApiResponse(responseCode = "409", description = "Not a Ground Admin"),
        ],
    )
    @PostMapping("/members/me/ground-admin/stepdown")
    fun stepDown(
        @RequestBody request: StepDownRequest,
        @AuthenticationPrincipal memberId: String?,
    ): ResponseEntity<*> {
        val memberIdValue = parseMemberId(memberId) ?: return unauthorizedResponse()

        return when (val result = groundAdminService.requestStepDown(memberIdValue, request.reason)) {
            is GroundAdminResult.Success -> ResponseEntity.ok(result.data)
            is GroundAdminResult.NotFound -> notFoundResponse(result.message)
            is GroundAdminResult.Conflict -> conflictResponse(result.message)
            is GroundAdminResult.Forbidden -> forbiddenResponse(result.message)
            is GroundAdminResult.ValidationError -> validationErrorResponse(result.errors)
        }
    }

    @Operation(
        summary = "Get my Ground Admin info",
        description = "Get current member's Ground Admin status and statistics",
    )
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "Ground Admin info retrieved (null if not a GA)"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "404", description = "Member not found"),
        ],
    )
    @GetMapping("/members/me/ground-admin")
    fun getMyGroundAdminInfo(
        @AuthenticationPrincipal memberId: String?,
    ): ResponseEntity<*> {
        val memberIdValue = parseMemberId(memberId) ?: return unauthorizedResponse()

        return when (val result = groundAdminService.getMyGroundAdminInfo(memberIdValue)) {
            is GroundAdminResult.Success -> ResponseEntity.ok(result.data)
            is GroundAdminResult.NotFound -> notFoundResponse(result.message)
            is GroundAdminResult.Conflict -> conflictResponse(result.message)
            is GroundAdminResult.Forbidden -> forbiddenResponse(result.message)
            is GroundAdminResult.ValidationError -> validationErrorResponse(result.errors)
        }
    }

    // ==================== Admin Endpoints ====================

    @Operation(
        summary = "Invite member to become Ground Admin",
        description = "Admin invites a member to become a Ground Admin in their sector",
    )
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "Invitation sent"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "403", description = "Member not in your sector"),
            ApiResponse(responseCode = "404", description = "Member not found"),
            ApiResponse(responseCode = "409", description = "Member already a Ground Admin or has pending application"),
        ],
    )
    @PostMapping("/members/{memberId}/ground-admin/invite")
    fun invite(
        @Parameter(description = "Member UUID to invite")
        @PathVariable memberId: UUID,
        @RequestBody request: InviteGroundAdminRequest,
        @AuthenticationPrincipal adminId: String?,
    ): ResponseEntity<*> {
        val adminIdValue = parseMemberId(adminId) ?: return unauthorizedResponse()
        val memberIdValue = MemberId(memberId)

        return when (val result = groundAdminService.invite(adminIdValue, memberIdValue, request.message)) {
            is GroundAdminResult.Success -> ResponseEntity.ok(result.data)
            is GroundAdminResult.NotFound -> notFoundResponse(result.message)
            is GroundAdminResult.Conflict -> conflictResponse(result.message)
            is GroundAdminResult.Forbidden -> forbiddenResponse(result.message)
            is GroundAdminResult.ValidationError -> validationErrorResponse(result.errors)
        }
    }

    @Operation(
        summary = "Revoke Ground Admin invitation",
        description = "Admin revokes/cancels a pending Ground Admin invitation",
    )
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "Invitation revoked"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "404", description = "Invitation not found"),
            ApiResponse(responseCode = "409", description = "Invitation already processed"),
        ],
    )
    @DeleteMapping("/members/{memberId}/ground-admin/invite/{applicationId}")
    fun revokeInvitation(
        @Parameter(description = "Member UUID whose invitation to revoke")
        @PathVariable memberId: UUID,
        @Parameter(description = "Application/Invitation UUID")
        @PathVariable applicationId: UUID,
        @AuthenticationPrincipal adminId: String?,
    ): ResponseEntity<*> {
        val adminIdValue = parseMemberId(adminId) ?: return unauthorizedResponse()
        val memberIdValue = MemberId(memberId)
        val applicationIdValue = GroundAdminApplicationId(applicationId)

        return when (
            val result =
                groundAdminService.revokeInvitation(
                    adminIdValue,
                    memberIdValue,
                    applicationIdValue,
                )
        ) {
            is GroundAdminResult.Success -> ResponseEntity.ok(result.data)
            is GroundAdminResult.NotFound -> notFoundResponse(result.message)
            is GroundAdminResult.Conflict -> conflictResponse(result.message)
            is GroundAdminResult.Forbidden -> forbiddenResponse(result.message)
            is GroundAdminResult.ValidationError -> validationErrorResponse(result.errors)
        }
    }

    @Operation(
        summary = "Approve Ground Admin application",
        description = "Admin approves a member's application to become a Ground Admin",
    )
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "Application approved"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "404", description = "Application not found"),
            ApiResponse(responseCode = "409", description = "Cannot approve this application"),
        ],
    )
    @PostMapping("/members/{memberId}/ground-admin/approve")
    fun approve(
        @Parameter(description = "Member UUID whose application to approve")
        @PathVariable memberId: UUID,
        @RequestBody request: ApproveApplicationRequest,
        @AuthenticationPrincipal adminId: String?,
    ): ResponseEntity<*> {
        val adminIdValue = parseMemberId(adminId) ?: return unauthorizedResponse()
        val memberIdValue = MemberId(memberId)
        val applicationId = GroundAdminApplicationId.fromString(request.applicationId)

        return when (val result = groundAdminService.approveApplication(adminIdValue, memberIdValue, applicationId)) {
            is GroundAdminResult.Success -> ResponseEntity.ok(result.data)
            is GroundAdminResult.NotFound -> notFoundResponse(result.message)
            is GroundAdminResult.Conflict -> conflictResponse(result.message)
            is GroundAdminResult.Forbidden -> forbiddenResponse(result.message)
            is GroundAdminResult.ValidationError -> validationErrorResponse(result.errors)
        }
    }

    @Operation(
        summary = "Decline Ground Admin application",
        description = "Admin declines a member's application to become a Ground Admin",
    )
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "Application declined"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "404", description = "Application not found"),
            ApiResponse(responseCode = "409", description = "Cannot decline this application"),
        ],
    )
    @PostMapping("/members/{memberId}/ground-admin/decline")
    fun decline(
        @Parameter(description = "Member UUID whose application to decline")
        @PathVariable memberId: UUID,
        @RequestBody request: DeclineApplicationRequest,
        @AuthenticationPrincipal adminId: String?,
    ): ResponseEntity<*> {
        val adminIdValue = parseMemberId(adminId) ?: return unauthorizedResponse()
        val memberIdValue = MemberId(memberId)
        val applicationId = GroundAdminApplicationId.fromString(request.applicationId)

        return when (
            val result =
                groundAdminService.declineApplication(
                    adminIdValue,
                    memberIdValue,
                    applicationId,
                    request.reason,
                )
        ) {
            is GroundAdminResult.Success -> ResponseEntity.ok(result.data)
            is GroundAdminResult.NotFound -> notFoundResponse(result.message)
            is GroundAdminResult.Conflict -> conflictResponse(result.message)
            is GroundAdminResult.Forbidden -> forbiddenResponse(result.message)
            is GroundAdminResult.ValidationError -> validationErrorResponse(result.errors)
        }
    }

    @Operation(
        summary = "Revoke Ground Admin status",
        description = "Admin revokes a member's Ground Admin status",
    )
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "Ground Admin status revoked"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "404", description = "Member not found"),
            ApiResponse(responseCode = "409", description = "Member is not a Ground Admin"),
        ],
    )
    @PostMapping("/members/{memberId}/ground-admin/revoke")
    fun revoke(
        @Parameter(description = "Member UUID to revoke Ground Admin status from")
        @PathVariable memberId: UUID,
        @RequestBody request: RevokeGroundAdminRequest,
        @AuthenticationPrincipal adminId: String?,
    ): ResponseEntity<*> {
        val adminIdValue = parseMemberId(adminId) ?: return unauthorizedResponse()
        val memberIdValue = MemberId(memberId)

        return when (val result = groundAdminService.revoke(adminIdValue, memberIdValue, request.reason)) {
            is GroundAdminResult.Success -> ResponseEntity.ok(result.data)
            is GroundAdminResult.NotFound -> notFoundResponse(result.message)
            is GroundAdminResult.Conflict -> conflictResponse(result.message)
            is GroundAdminResult.Forbidden -> forbiddenResponse(result.message)
            is GroundAdminResult.ValidationError -> validationErrorResponse(result.errors)
        }
    }

    @Operation(
        summary = "Update Ground Admin status",
        description = "Admin updates a Ground Admin's status (active/on_hold)",
    )
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "Status updated"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "404", description = "Member not found"),
            ApiResponse(responseCode = "409", description = "Member is not a Ground Admin"),
        ],
    )
    @PatchMapping("/members/{memberId}/ground-admin/status")
    fun updateStatus(
        @Parameter(description = "Member UUID to update status for")
        @PathVariable memberId: UUID,
        @RequestBody request: UpdateGroundAdminStatusRequest,
        @AuthenticationPrincipal adminId: String?,
    ): ResponseEntity<*> {
        val adminIdValue = parseMemberId(adminId) ?: return unauthorizedResponse()
        val memberIdValue = MemberId(memberId)

        return when (val result = groundAdminService.updateStatus(adminIdValue, memberIdValue, request.status)) {
            is GroundAdminResult.Success -> ResponseEntity.ok(result.data)
            is GroundAdminResult.NotFound -> notFoundResponse(result.message)
            is GroundAdminResult.Conflict -> conflictResponse(result.message)
            is GroundAdminResult.Forbidden -> forbiddenResponse(result.message)
            is GroundAdminResult.ValidationError -> validationErrorResponse(result.errors)
        }
    }

    @Operation(
        summary = "List Ground Admins in sector",
        description = "Get a list of all Ground Admins in a sector, optionally filtered by status",
    )
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "Ground Admins list retrieved"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
        ],
    )
    @GetMapping("/sectors/{sectorId}/ground-admins")
    fun listGroundAdmins(
        @Parameter(description = "Sector UUID")
        @PathVariable sectorId: UUID,
        @Parameter(description = "Filter by status (optional)")
        @RequestParam(required = false) status: GroundAdminStatus?,
        @AuthenticationPrincipal adminId: String?,
    ): ResponseEntity<*> {
        if (parseMemberId(adminId) == null) {
            return unauthorizedResponse()
        }

        val sectorIdValue = SectorId(sectorId)
        val response = groundAdminService.listGroundAdmins(sectorIdValue, status)
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
        ResponseEntity
            .status(HttpStatus.UNAUTHORIZED)
            .body(ErrorResponse(ErrorBody(ErrorCodes.UNAUTHORIZED, "Authentication required")))

    private fun notFoundResponse(message: String): ResponseEntity<ErrorResponse> =
        ResponseEntity
            .status(HttpStatus.NOT_FOUND)
            .body(ErrorResponse(ErrorBody(ErrorCodes.NOT_FOUND, message)))

    private fun conflictResponse(message: String): ResponseEntity<ErrorResponse> =
        ResponseEntity
            .status(HttpStatus.CONFLICT)
            .body(ErrorResponse(ErrorBody(ErrorCodes.CONFLICT, message)))

    private fun forbiddenResponse(message: String): ResponseEntity<ErrorResponse> =
        ResponseEntity
            .status(HttpStatus.FORBIDDEN)
            .body(ErrorResponse(ErrorBody(ErrorCodes.FORBIDDEN, message)))

    private fun validationErrorResponse(errors: List<String>): ResponseEntity<ErrorResponse> =
        ResponseEntity
            .status(HttpStatus.BAD_REQUEST)
            .body(ErrorResponse(ErrorBody(ErrorCodes.VALIDATION_ERROR, errors.joinToString(", "))))
}
