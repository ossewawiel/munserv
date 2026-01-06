package com.munserv.issues.api

import com.munserv.issues.domain.IssueId
import com.munserv.issues.domain.IssueState
import com.munserv.issues.domain.IssueType
import com.munserv.issues.service.CreateIssueCommand
import com.munserv.issues.service.IssueResult
import com.munserv.issues.service.IssueService
import com.munserv.photos.service.IssuePhotoService
import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
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
class IssueController(
    private val issueService: IssueService,
    private val photoService: IssuePhotoService,
) {
    /**
     * GET /api/v1/issues - List issues with optional filtering.
     */
    @GetMapping
    fun listIssues(
        @RequestParam(required = false) sectorId: String?,
        @RequestParam(required = false) state: String?,
        @RequestParam(required = false) type: String?,
        @RequestParam(defaultValue = "1") page: Int,
        @RequestParam(defaultValue = "20") limit: Int,
        @RequestParam(defaultValue = "heat") sortBy: String,
    ): ResponseEntity<PaginatedIssuesResponse> {
        var issues = issueService.findAll()

        // Filter
        if (sectorId != null) {
            val sectorUuid = SectorId(UUID.fromString(sectorId))
            issues = issues.filter { it.sectorId == sectorUuid }
        }
        if (state != null) {
            val issueState = IssueState.fromString(state)
            issues = issues.filter { it.state == issueState }
        }
        if (type != null) {
            val issueType = IssueType.fromString(type)
            issues = issues.filter { it.type == issueType }
        }

        // Sort
        issues =
            when (sortBy) {
                "heat" -> issues.sortedByDescending { it.heat }
                "createdAt" -> issues.sortedByDescending { it.createdAt }
                else -> issues.sortedByDescending { it.heat }
            }

        // Paginate
        val totalItems = issues.size
        val startIndex = (page - 1) * limit
        val endIndex = minOf(startIndex + limit, totalItems)
        val paginated = if (startIndex < totalItems) issues.subList(startIndex, endIndex) else emptyList()

        // Convert to response with thumbnail URLs
        val items =
            paginated.map { issue ->
                val thumbnailUrl = photoService.getThumbnailUrl(issue.id)
                issue.toSummaryResponse(thumbnailUrl)
            }
        val pagination =
            PaginationInfo(
                page = page,
                limit = limit,
                totalItems = totalItems,
                totalPages = if (totalItems > 0) (totalItems + limit - 1) / limit else 0,
            )

        return ResponseEntity.ok(PaginatedIssuesResponse(items, pagination))
    }

    /**
     * GET /api/v1/issues/mine - List issues reported by the authenticated member.
     */
    @GetMapping("/mine")
    fun listMyIssues(
        @AuthenticationPrincipal memberId: MemberId?,
        @RequestParam(defaultValue = "1") page: Int,
        @RequestParam(defaultValue = "20") limit: Int,
    ): ResponseEntity<PaginatedIssuesResponse> {
        // Use first member ID if not authenticated (for testing)
        val reporterId = memberId ?: MemberId(UUID.fromString("550e8400-e29b-41d4-a716-446655440010"))

        val issues =
            issueService.findByReporter(reporterId)
                .sortedByDescending { it.createdAt }

        // Paginate
        val totalItems = issues.size
        val startIndex = (page - 1) * limit
        val endIndex = minOf(startIndex + limit, totalItems)
        val paginated = if (startIndex < totalItems) issues.subList(startIndex, endIndex) else emptyList()

        val items =
            paginated.map { issue ->
                val thumbnailUrl = photoService.getThumbnailUrl(issue.id)
                issue.toSummaryResponse(thumbnailUrl)
            }
        val pagination =
            PaginationInfo(
                page = page,
                limit = limit,
                totalItems = totalItems,
                totalPages = if (totalItems > 0) (totalItems + limit - 1) / limit else 0,
            )

        return ResponseEntity.ok(PaginatedIssuesResponse(items, pagination))
    }

    /**
     * GET /api/v1/issues/{id} - Get issue by ID.
     */
    @GetMapping("/{id}")
    fun getIssue(
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
                    .body(ErrorResponse(ErrorDetail("NOT_FOUND", "Issue not found")))
            else ->
                ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ErrorResponse(ErrorDetail("INTERNAL_ERROR", "Unexpected error")))
        }
    }

    /**
     * POST /api/v1/issues - Create a new issue.
     */
    @PostMapping
    fun createIssue(
        @RequestBody request: CreateIssueRequest,
        @AuthenticationPrincipal memberId: MemberId?,
    ): ResponseEntity<*> {
        // Use first member and sector if not authenticated (for testing)
        val reporterId = memberId ?: MemberId(UUID.fromString("550e8400-e29b-41d4-a716-446655440010"))
        val sectorId = SectorId(UUID.fromString("550e8400-e29b-41d4-a716-446655440001"))

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
                    .body(ErrorResponse(ErrorDetail("VALIDATION_ERROR", result.errors.joinToString(", "))))
            else ->
                ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ErrorResponse(ErrorDetail("INTERNAL_ERROR", "Unexpected error")))
        }
    }

    /**
     * PATCH /api/v1/issues/{id}/state - Update issue state.
     */
    @PatchMapping("/{id}/state")
    fun updateIssueState(
        @PathVariable id: String,
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
                    .body(ErrorResponse(ErrorDetail("NOT_FOUND", "Issue not found")))
            is IssueResult.InvalidTransition ->
                ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                    .body(
                        ErrorResponse(
                            ErrorDetail(
                                "INVALID_STATE_TRANSITION",
                                "Cannot transition from ${result.from.toApiString()} to ${result.to.toApiString()}",
                            ),
                        ),
                    )
            else ->
                ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ErrorResponse(ErrorDetail("INTERNAL_ERROR", "Unexpected error")))
        }
    }
}
