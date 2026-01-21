package com.munserv.admin.api

import com.munserv.admin.domain.MemberWithStats
import com.munserv.admin.service.DashboardService
import com.munserv.admin.service.HeatReportService
import com.munserv.auth.api.ErrorResponse
import com.munserv.auth.api.MemberApprovedResponse
import com.munserv.auth.domain.Member
import com.munserv.auth.domain.MemberStatus
import com.munserv.auth.repository.MemberRepository
import com.munserv.auth.service.RegistrationResult
import com.munserv.auth.service.RegistrationService
import com.munserv.groundadmin.domain.ApplicationStatus
import com.munserv.groundadmin.domain.ApplicationType
import com.munserv.groundadmin.repository.GroundAdminApplicationRepository
import com.munserv.issues.repository.IssueRepository
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.media.Content
import io.swagger.v3.oas.annotations.media.Schema
import io.swagger.v3.oas.annotations.responses.ApiResponse
import io.swagger.v3.oas.annotations.responses.ApiResponses
import io.swagger.v3.oas.annotations.security.SecurityRequirement
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.constraints.Max
import jakarta.validation.constraints.Min
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.validation.annotation.Validated
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import java.time.Clock
import java.util.UUID
import kotlin.math.ceil

/**
 * REST controller for admin dashboard and reports.
 * All endpoints require admin role (enforced by SecurityConfig).
 */
@RestController
@RequestMapping("/api/v1/admin")
@Tag(name = "Admin", description = "Admin dashboard and reporting endpoints. Requires admin role.")
@SecurityRequirement(name = "bearerAuth")
@Validated
class AdminController(
    private val dashboardService: DashboardService,
    private val heatReportService: HeatReportService,
    private val memberRepository: MemberRepository,
    private val issueRepository: IssueRepository,
    private val registrationService: RegistrationService,
    private val applicationRepository: GroundAdminApplicationRepository,
    private val clock: Clock,
) {
    /**
     * GET /api/v1/admin/dashboard
     * Returns dashboard statistics for the given sector.
     */
    @Operation(
        summary = "Get dashboard statistics",
        description = "Retrieve dashboard statistics for a sector including issue counts by state and type",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Dashboard statistics retrieved successfully",
                content = [Content(schema = Schema(implementation = DashboardResponse::class))],
            ),
            ApiResponse(responseCode = "401", description = "Unauthorized - invalid or missing token"),
            ApiResponse(responseCode = "403", description = "Forbidden - requires admin role"),
            ApiResponse(responseCode = "404", description = "Sector not found"),
        ],
    )
    @GetMapping("/dashboard")
    fun getDashboard(
        @Parameter(description = "Sector UUID", required = true, example = "550e8400-e29b-41d4-a716-446655440001")
        @RequestParam sectorId: String,
    ): ResponseEntity<DashboardResponse> {
        val id = SectorId.fromString(sectorId)
        val stats =
            dashboardService.getDashboardStats(id)
                ?: return ResponseEntity.notFound().build()

        return ResponseEntity.ok(stats.toResponse())
    }

    /**
     * GET /api/v1/admin/reports/heat
     * Returns issues ranked by heat score descending.
     */
    @Operation(
        summary = "Get heat report",
        description = "Retrieve a list of issues ranked by heat score in descending order",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Heat report generated successfully",
                content = [Content(schema = Schema(implementation = HeatReportResponse::class))],
            ),
            ApiResponse(responseCode = "401", description = "Unauthorized - invalid or missing token"),
            ApiResponse(responseCode = "403", description = "Forbidden - requires admin role"),
        ],
    )
    @GetMapping("/reports/heat")
    fun getHeatReport(
        @Parameter(description = "Sector UUID", required = true, example = "550e8400-e29b-41d4-a716-446655440001")
        @RequestParam sectorId: String,
        @Parameter(description = "Maximum number of issues to return", example = "20")
        @RequestParam(defaultValue = "20")
        @Min(1, message = "Limit must be at least 1")
        @Max(100, message = "Limit cannot exceed 100")
        limit: Int,
    ): ResponseEntity<HeatReportResponse> {
        val id = SectorId.fromString(sectorId)
        val items = heatReportService.getHeatReport(id, limit)
        val response = items.toHeatReportResponse(clock.instant())

        return ResponseEntity.ok(response)
    }

    /**
     * GET /api/v1/admin/members
     * Returns paginated list of members for the sector with issue counts.
     * Optionally filter by member status, Ground Admin status, or pending applications.
     */
    @Operation(
        summary = "List sector members",
        description =
            "Retrieve a paginated list of members in a sector with their issue counts. " +
                "Supports filtering by member status, Ground Admin status, pending applications, " +
                "and pending invitations.",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Members list retrieved successfully",
                content = [Content(schema = Schema(implementation = MembersListResponse::class))],
            ),
            ApiResponse(responseCode = "400", description = "Invalid status value"),
            ApiResponse(responseCode = "401", description = "Unauthorized - invalid or missing token"),
            ApiResponse(responseCode = "403", description = "Forbidden - requires admin role"),
        ],
    )
    @GetMapping("/members")
    fun getMembers(
        @Parameter(description = "Sector UUID", required = true, example = "550e8400-e29b-41d4-a716-446655440001")
        @RequestParam sectorId: String,
        @Parameter(
            description = "Filter by member status",
            required = false,
            example = "active",
            schema = Schema(allowableValues = ["pending_approval", "active", "suspended", "deleted"]),
        )
        @RequestParam(required = false) status: String?,
        @Parameter(description = "Filter by Ground Admin status (true = only Ground Admins)")
        @RequestParam(required = false) isGroundAdmin: Boolean?,
        @Parameter(description = "Filter by pending GA application (true = only members with pending applications)")
        @RequestParam(required = false) hasPendingApplication: Boolean?,
        @Parameter(description = "Filter by pending GA invitation (true = only members with pending invitations)")
        @RequestParam(required = false) hasInvitationPending: Boolean?,
        @Parameter(description = "Page number (1-based)", example = "1")
        @RequestParam(defaultValue = "1")
        @Min(1, message = "Page must be at least 1")
        page: Int,
        @Parameter(description = "Items per page", example = "20")
        @RequestParam(defaultValue = "20")
        @Min(1, message = "Limit must be at least 1")
        @Max(100, message = "Limit cannot exceed 100")
        limit: Int,
    ): ResponseEntity<*> {
        val id = SectorId.fromString(sectorId)

        // Parse and validate status if provided
        val memberStatus =
            status?.let {
                try {
                    MemberStatus.fromString(it)
                } catch (e: IllegalArgumentException) {
                    return ResponseEntity.badRequest().body(
                        ErrorResponse(
                            "invalid_status",
                            "Invalid status value: $it. Valid values are: pending_approval, active, suspended, deleted",
                        ),
                    )
                }
            }

        // Fetch members based on filters
        val allMembers: List<Member> =
            when {
                isGroundAdmin == true -> memberRepository.findBySectorIdAndIsGroundAdmin(id, true)
                hasPendingApplication == true || hasInvitationPending == true -> {
                    val pendingApplications =
                        applicationRepository.findBySectorIdAndStatus(
                            id,
                            ApplicationStatus.PENDING.toDbValue(),
                        )

                    val memberIds =
                        pendingApplications
                            .filter { app ->
                                when {
                                    hasPendingApplication == true -> app.type == ApplicationType.APPLICATION
                                    hasInvitationPending == true -> app.type == ApplicationType.INVITATION
                                    else -> true
                                }
                            }
                            .map { it.memberId }
                            .toSet()

                    memberIds.mapNotNull { memberRepository.findById(it) }
                }
                memberStatus != null -> memberRepository.findBySectorIdAndStatus(id, memberStatus)
                else -> memberRepository.findBySectorId(id)
            }

        val totalItems = allMembers.size
        val totalPages = if (totalItems == 0) 1 else ceil(totalItems.toDouble() / limit).toInt()
        val validPage = page.coerceIn(1, totalPages)

        val startIndex = (validPage - 1) * limit
        val pagedMembers = allMembers.drop(startIndex).take(limit)

        // Get pending application info for the paged members
        val pendingApps =
            applicationRepository.findBySectorIdAndStatus(
                id,
                ApplicationStatus.PENDING.toDbValue(),
            )
        val pendingAppsByMember =
            pendingApps
                .filter { it.type == ApplicationType.APPLICATION }
                .associateBy { it.memberId }
        val pendingInvitationsByMember =
            pendingApps
                .filter { it.type == ApplicationType.INVITATION }
                .associateBy { it.memberId }

        val memberResponses =
            pagedMembers.map { member ->
                val issueCount = issueRepository.findByReporterId(member.id).size
                val pendingApp = pendingAppsByMember[member.id]
                val pendingInvite = pendingInvitationsByMember[member.id]
                member.toMemberWithStatsAndGAInfo(
                    issueCount = issueCount,
                    hasPendingApplication = pendingApp != null,
                    hasInvitationPending = pendingInvite != null,
                    pendingApplicationId = pendingApp?.id?.toString() ?: pendingInvite?.id?.toString(),
                ).toResponse()
            }

        val response =
            MembersListResponse(
                items = memberResponses,
                pagination =
                    PaginationResponse(
                        page = validPage,
                        limit = limit,
                        totalItems = totalItems,
                        totalPages = totalPages,
                    ),
            )

        return ResponseEntity.ok(response)
    }

    private fun Member.toMemberWithStatsAndGAInfo(
        issueCount: Int,
        hasPendingApplication: Boolean,
        hasInvitationPending: Boolean,
        pendingApplicationId: String?,
    ) = MemberWithStats(
        id = id,
        firstName = firstName,
        surname = surname,
        phoneNumber = phone.ifEmpty { "***-***-****" },
        address = address,
        status = status,
        issueCount = issueCount,
        joinedAt = createdAt,
        isGroundAdmin = isGroundAdmin,
        groundAdminStatus = groundAdminStatus,
        hasPendingApplication = hasPendingApplication,
        hasInvitationPending = hasInvitationPending,
        pendingApplicationId = pendingApplicationId,
    )

    /**
     * GET /api/v1/admin/members/pending-count
     * Returns count of members with pending_approval status for the sector.
     */
    @Operation(
        summary = "Get pending member count",
        description = "Returns the number of members awaiting approval in a sector",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Pending count retrieved successfully",
                content = [Content(schema = Schema(implementation = PendingCountResponse::class))],
            ),
            ApiResponse(responseCode = "401", description = "Unauthorized"),
            ApiResponse(responseCode = "403", description = "Forbidden - requires admin role"),
        ],
    )
    @GetMapping("/members/pending-count")
    fun getPendingMemberCount(
        @Parameter(description = "Sector UUID", required = true)
        @RequestParam sectorId: String,
    ): ResponseEntity<PendingCountResponse> {
        val id = SectorId.fromString(sectorId)
        val count = memberRepository.findBySectorIdAndStatus(id, MemberStatus.PendingApproval).size
        return ResponseEntity.ok(PendingCountResponse(count))
    }

    /**
     * POST /api/v1/admin/members/{id}/approve
     * Approves a pending member registration.
     * Generates temporary password and sends welcome email.
     */
    @Operation(
        summary = "Approve pending member registration",
        description = "Approve a pending member registration. Generates temporary password and sends welcome email.",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Member approved",
                content = [Content(schema = Schema(implementation = MemberApprovedResponse::class))],
            ),
            ApiResponse(responseCode = "400", description = "Invalid status"),
            ApiResponse(responseCode = "401", description = "Unauthorized - invalid or missing token"),
            ApiResponse(responseCode = "403", description = "Forbidden - requires admin role"),
            ApiResponse(responseCode = "404", description = "Member not found"),
        ],
    )
    @PostMapping("/members/{id}/approve")
    fun approveMember(
        @Parameter(description = "Member UUID to approve")
        @PathVariable id: String,
    ): ResponseEntity<*> =
        when (val result = registrationService.approveMember(MemberId(UUID.fromString(id)))) {
            is RegistrationResult.Approved ->
                ResponseEntity.ok(
                    MemberApprovedResponse(
                        memberId = result.member.id.value.toString(),
                        email = result.member.email,
                        message = "Member approved. Temporary password: ${result.temporaryPassword}",
                    ),
                )

            is RegistrationResult.MemberNotFound ->
                ResponseEntity
                    .status(HttpStatus.NOT_FOUND)
                    .body(ErrorResponse("not_found", "Member not found"))

            is RegistrationResult.InvalidStatus ->
                ResponseEntity
                    .badRequest()
                    .body(
                        ErrorResponse(
                            "invalid_status",
                            "Member status is ${result.current}, expected ${result.expected}",
                        ),
                    )

            is RegistrationResult.Success,
            is RegistrationResult.Rejected,
            is RegistrationResult.EmailAlreadyRegistered,
            is RegistrationResult.InvalidSector,
            is RegistrationResult.ValidationError,
            -> ResponseEntity.internalServerError().build<Unit>()
        }

    /**
     * DELETE /api/v1/admin/members/{id}
     * Rejects a pending member registration.
     * Deletes the member record.
     */
    @Operation(
        summary = "Reject pending member registration",
        description = "Reject a pending member registration. Deletes the member record.",
    )
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "204", description = "Member rejected"),
            ApiResponse(responseCode = "400", description = "Invalid status"),
            ApiResponse(responseCode = "401", description = "Unauthorized - invalid or missing token"),
            ApiResponse(responseCode = "403", description = "Forbidden - requires admin role"),
            ApiResponse(responseCode = "404", description = "Member not found"),
        ],
    )
    @DeleteMapping("/members/{id}")
    fun rejectMember(
        @Parameter(description = "Member UUID to reject")
        @PathVariable id: String,
    ): ResponseEntity<*> =
        when (val result = registrationService.rejectMember(MemberId(UUID.fromString(id)))) {
            is RegistrationResult.Rejected ->
                ResponseEntity.noContent().build<Unit>()

            is RegistrationResult.MemberNotFound ->
                ResponseEntity
                    .status(HttpStatus.NOT_FOUND)
                    .body(ErrorResponse("not_found", "Member not found"))

            is RegistrationResult.InvalidStatus ->
                ResponseEntity
                    .badRequest()
                    .body(
                        ErrorResponse(
                            "invalid_status",
                            "Member status is ${result.current}, expected ${result.expected}",
                        ),
                    )

            is RegistrationResult.Success,
            is RegistrationResult.Approved,
            is RegistrationResult.EmailAlreadyRegistered,
            is RegistrationResult.InvalidSector,
            is RegistrationResult.ValidationError,
            -> ResponseEntity.internalServerError().build<Unit>()
        }
}
