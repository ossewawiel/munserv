package com.munserv.issues.api

import com.munserv.issues.domain.IssueId
import com.munserv.issues.domain.IssueState
import com.munserv.issues.domain.IssueType
import com.munserv.issues.service.CreateIssueCommand
import com.munserv.issues.service.IssueResult
import com.munserv.issues.service.IssueService
import com.munserv.photos.service.IssuePhotoService
import com.munserv.shared.api.ErrorBody
import com.munserv.shared.api.ErrorCodes
import com.munserv.shared.api.ErrorResponse
import com.munserv.shared.api.paginate
import com.munserv.shared.api.toPaginationInfo
import com.munserv.shared.types.GeoPoint
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
import jakarta.validation.Valid
import jakarta.validation.constraints.Max
import jakarta.validation.constraints.Min
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.validation.annotation.Validated
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
 * REST controller for issue endpoints.
 */
@RestController
@RequestMapping("/api/v1/issues")
@Tag(name = "Issues", description = "Issue management endpoints for reporting and tracking municipal issues")
@SecurityRequirement(name = "bearerAuth")
@Validated
class IssueController(
    private val issueService: IssueService,
    private val photoService: IssuePhotoService,
) {
    companion object {
        private const val ERROR_UNEXPECTED = "Unexpected error"
    }

    /**
     * GET /api/v1/issues - List issues with optional filtering.
     */
    @Operation(
        summary = "List issues",
        description = "Retrieve a paginated list of issues with optional filtering by sector, state, and type",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Successfully retrieved issues",
                content = [Content(schema = Schema(implementation = PaginatedIssuesResponse::class))],
            ),
            ApiResponse(responseCode = "401", description = "Unauthorized - invalid or missing token"),
        ],
    )
    @GetMapping
    fun listIssues(
        @Parameter(description = "Filter by sector UUID")
        @RequestParam(required = false) sectorId: String?,
        @Parameter(description = "Filter by issue state")
        @RequestParam(required = false) state: String?,
        @Parameter(description = "Filter by issue type")
        @RequestParam(required = false) type: String?,
        @Parameter(description = "Page number (1-based)")
        @RequestParam(defaultValue = "1")
        @Min(1, message = "Page must be at least 1")
        page: Int,
        @Parameter(description = "Items per page (max 100)")
        @RequestParam(defaultValue = "20")
        @Min(1, message = "Limit must be at least 1")
        @Max(100, message = "Limit cannot exceed 100")
        limit: Int,
        @Parameter(description = "Sort field", schema = Schema(allowableValues = ["heat", "createdAt"]))
        @RequestParam(defaultValue = "heat") sortBy: String,
    ): ResponseEntity<PaginatedIssuesResponse> {
        // Parse filter parameters
        val sectorFilter = sectorId?.let { SectorId(UUID.fromString(it)) }
        val stateFilter = state?.let { IssueState.fromString(it) }
        val typeFilter = type?.let { IssueType.fromString(it) }

        // Filter, sort, and paginate using immutable chain
        val filteredAndSortedIssues =
            issueService.findAll()
                .let { issues -> sectorFilter?.let { filter -> issues.filter { it.sectorId == filter } } ?: issues }
                .let { issues -> stateFilter?.let { filter -> issues.filter { it.state == filter } } ?: issues }
                .let { issues -> typeFilter?.let { filter -> issues.filter { it.type == filter } } ?: issues }
                .let { issues ->
                    when (sortBy) {
                        "heat" -> issues.sortedByDescending { it.heat }
                        "createdAt" -> issues.sortedByDescending { it.createdAt }
                        else -> issues.sortedByDescending { it.heat }
                    }
                }

        // Paginate using shared utility
        val paginatedResult = filteredAndSortedIssues.paginate(page, limit)

        // Convert to response with thumbnail URLs
        val items =
            paginatedResult.items.map { issue ->
                val thumbnailUrl = photoService.getThumbnailUrl(issue.id)
                issue.toSummaryResponse(thumbnailUrl)
            }

        return ResponseEntity.ok(PaginatedIssuesResponse(items, paginatedResult.pagination.toPaginationInfo()))
    }

    /**
     * GET /api/v1/issues/mine - List issues reported by the authenticated member.
     */
    @Operation(
        summary = "List my issues",
        description = "Retrieve issues reported by the authenticated member",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Successfully retrieved member's issues",
                content = [Content(schema = Schema(implementation = PaginatedIssuesResponse::class))],
            ),
            ApiResponse(responseCode = "401", description = "Unauthorized - invalid or missing token"),
        ],
    )
    @GetMapping("/mine")
    fun listMyIssues(
        @Parameter(hidden = true)
        @AuthenticationPrincipal memberIdStr: String?,
        @Parameter(description = "Page number (1-based)")
        @RequestParam(defaultValue = "1")
        @Min(1, message = "Page must be at least 1")
        page: Int,
        @Parameter(description = "Items per page")
        @RequestParam(defaultValue = "20")
        @Min(1, message = "Limit must be at least 1")
        @Max(100, message = "Limit cannot exceed 100")
        limit: Int,
    ): ResponseEntity<*> {
        if (memberIdStr == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ErrorResponse(ErrorBody(ErrorCodes.UNAUTHORIZED, "Authentication required")))
        }

        val reporterId =
            try {
                MemberId(UUID.fromString(memberIdStr))
            } catch (e: IllegalArgumentException) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse(ErrorBody(ErrorCodes.UNAUTHORIZED, "Invalid authentication")))
            }

        val issues =
            issueService.findByReporter(reporterId)
                .sortedByDescending { it.createdAt }

        // Paginate using shared utility
        val paginatedResult = issues.paginate(page, limit)

        val items =
            paginatedResult.items.map { issue ->
                val thumbnailUrl = photoService.getThumbnailUrl(issue.id)
                issue.toSummaryResponse(thumbnailUrl)
            }

        return ResponseEntity.ok(PaginatedIssuesResponse(items, paginatedResult.pagination.toPaginationInfo()))
    }

    /**
     * GET /api/v1/issues/{id} - Get issue by ID.
     */
    @Operation(
        summary = "Get issue details",
        description = "Retrieve detailed information about a specific issue including photos and state history",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Successfully retrieved issue",
                content = [Content(schema = Schema(implementation = IssueDetailResponse::class))],
            ),
            ApiResponse(responseCode = "401", description = "Unauthorized - invalid or missing token"),
            ApiResponse(responseCode = "404", description = "Issue not found"),
        ],
    )
    @GetMapping("/{id}")
    fun getIssue(
        @Parameter(description = "Issue UUID", required = true)
        @PathVariable id: String,
    ): ResponseEntity<*> {
        val issueId = IssueId(UUID.fromString(id))

        return when (val result = issueService.findById(issueId)) {
            is IssueResult.Success -> {
                val photoUrls = photoService.getPhotoUrls(issueId)
                ResponseEntity.ok(result.issue.toDetailResponse(photoUrls))
            }
            is IssueResult.NotFound ->
                ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ErrorResponse(ErrorBody(ErrorCodes.NOT_FOUND, "Issue not found")))
            // Exhaustive handling - these should never occur for findById()
            is IssueResult.InvalidTransition,
            is IssueResult.ValidationError,
            is IssueResult.Unauthorized,
            -> throw IllegalStateException("Unexpected result type: ${result::class.simpleName}")
        }
    }

    /**
     * POST /api/v1/issues - Create a new issue.
     */
    @Operation(
        summary = "Report a new issue",
        description = "Create a new municipal issue report with location and type",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "201",
                description = "Issue created successfully",
                content = [Content(schema = Schema(implementation = IssueDetailResponse::class))],
            ),
            ApiResponse(responseCode = "400", description = "Validation error"),
            ApiResponse(responseCode = "401", description = "Unauthorized - invalid or missing token"),
        ],
    )
    @PostMapping
    fun createIssue(
        @io.swagger.v3.oas.annotations.parameters.RequestBody(
            description = "Issue creation request",
            required = true,
            content = [Content(schema = Schema(implementation = CreateIssueRequest::class))],
        )
        @Valid
        @RequestBody request: CreateIssueRequest,
        @Parameter(hidden = true)
        @AuthenticationPrincipal memberIdStr: String?,
    ): ResponseEntity<*> {
        if (memberIdStr == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ErrorResponse(ErrorBody(ErrorCodes.UNAUTHORIZED, "Authentication required")))
        }

        val reporterId =
            try {
                MemberId(UUID.fromString(memberIdStr))
            } catch (e: IllegalArgumentException) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse(ErrorBody(ErrorCodes.UNAUTHORIZED, "Invalid authentication")))
            }

        val sectorId =
            try {
                SectorId(UUID.fromString(request.sectorId))
            } catch (e: IllegalArgumentException) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ErrorResponse(ErrorBody(ErrorCodes.VALIDATION_ERROR, "Invalid sector ID format")))
            }

        val command =
            CreateIssueCommand(
                sectorId = sectorId,
                reporterId = reporterId,
                type = IssueType.fromString(request.type),
                location = GeoPoint(request.latitude, request.longitude),
                address = null,
                description = request.description,
            )

        return when (val result = issueService.create(command)) {
            is IssueResult.Success -> {
                // New issues have no photos yet
                ResponseEntity.status(HttpStatus.CREATED)
                    .body(result.issue.toDetailResponse(emptyList()))
            }
            is IssueResult.ValidationError ->
                ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ErrorResponse(ErrorBody(ErrorCodes.VALIDATION_ERROR, result.errors.joinToString(", "))))
            // Exhaustive handling - these should never occur for create()
            is IssueResult.NotFound,
            is IssueResult.InvalidTransition,
            is IssueResult.Unauthorized,
            -> throw IllegalStateException("Unexpected result type: ${result::class.simpleName}")
        }
    }

    /**
     * PATCH /api/v1/issues/{id}/state - Update issue state.
     */
    @Operation(
        summary = "Update issue state",
        description = "Transition an issue to a new state. Requires admin role.",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "State updated successfully",
                content = [Content(schema = Schema(implementation = IssueDetailResponse::class))],
            ),
            ApiResponse(responseCode = "401", description = "Unauthorized - invalid or missing token"),
            ApiResponse(responseCode = "403", description = "Forbidden - requires admin role"),
            ApiResponse(responseCode = "404", description = "Issue not found"),
            ApiResponse(responseCode = "422", description = "Invalid state transition"),
        ],
    )
    @PatchMapping("/{id}/state")
    fun updateIssueState(
        @Parameter(description = "Issue UUID", required = true)
        @PathVariable id: String,
        @io.swagger.v3.oas.annotations.parameters.RequestBody(
            description = "State change request",
            required = true,
            content = [Content(schema = Schema(implementation = UpdateIssueStateRequest::class))],
        )
        @Valid
        @RequestBody request: UpdateIssueStateRequest,
    ): ResponseEntity<*> {
        val issueId = IssueId(UUID.fromString(id))
        val newState = IssueState.fromString(request.state)

        return when (val result = issueService.updateState(issueId, newState)) {
            is IssueResult.Success -> {
                val photoUrls = photoService.getPhotoUrls(issueId)
                ResponseEntity.ok(result.issue.toDetailResponse(photoUrls))
            }
            is IssueResult.NotFound ->
                ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ErrorResponse(ErrorBody(ErrorCodes.NOT_FOUND, "Issue not found")))
            is IssueResult.InvalidTransition ->
                ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                    .body(
                        ErrorResponse(
                            ErrorBody(
                                ErrorCodes.INVALID_STATE_TRANSITION,
                                "Cannot transition from ${result.from.toApiString()} to ${result.to.toApiString()}",
                            ),
                        ),
                    )
            // Exhaustive handling - these should never occur for updateState()
            is IssueResult.ValidationError,
            is IssueResult.Unauthorized,
            -> throw IllegalStateException("Unexpected result type: ${result::class.simpleName}")
        }
    }
}
