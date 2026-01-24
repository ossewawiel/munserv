package com.munserv.pod.api

import com.munserv.admin.domain.AdminRole
import com.munserv.pod.service.DashboardResult
import com.munserv.pod.service.PodDashboardService
import com.munserv.pod.service.PodResult
import com.munserv.shared.security.RequireRole
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.PodId
import com.munserv.shared.types.SectorId
import com.munserv.shared.types.WardId
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.media.Content
import io.swagger.v3.oas.annotations.media.Schema
import io.swagger.v3.oas.annotations.responses.ApiResponse
import io.swagger.v3.oas.annotations.responses.ApiResponses
import io.swagger.v3.oas.annotations.security.SecurityRequirement
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

/**
 * REST controller for pod dashboard statistics.
 * Provides endpoints for Pod Chiefs to view statistics at pod, ward, and sector levels.
 *
 * All endpoints require POD_CHIEF role.
 */
@RestController
@RequestMapping("/api/v1/pod/dashboard")
@Tag(name = "Pod Dashboard", description = "Dashboard statistics endpoints. Requires pod_chief role.")
@SecurityRequirement(name = "bearerAuth")
@RequireRole(AdminRole.POD_CHIEF)
class PodDashboardController(
    private val dashboardService: PodDashboardService,
    private val podIdResolver: PodIdResolver,
) {
    @Operation(
        summary = "Get pod dashboard statistics",
        description = "Returns aggregated statistics for the entire pod including issues, members, and administrative units.",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Dashboard statistics retrieved successfully",
                content = [Content(schema = Schema(implementation = PodDashboardStatsResponse::class))],
            ),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "403", description = "Insufficient permissions"),
            ApiResponse(responseCode = "404", description = "Pod not found"),
        ],
    )
    @GetMapping
    fun getPodDashboard(): ResponseEntity<*> {
        val podId =
            getCurrentPodId()
                ?: return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorResponse("unauthorized", "Could not determine pod for current user"),
                )

        return when (val result = dashboardService.getPodStats(podId)) {
            is PodResult.Success ->
                ResponseEntity.ok(PodDashboardStatsResponse.from(result.data))
            is PodResult.NotFound ->
                ResponseEntity.notFound().build<Any>()
            is PodResult.ValidationError ->
                ResponseEntity.badRequest().body(ErrorResponse("validation_error", result.errors.joinToString("; ")))
            is PodResult.Unauthorized ->
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(ErrorResponse("forbidden", result.reason))
        }
    }

    @Operation(
        summary = "Get ward dashboard statistics",
        description = "Returns aggregated statistics for a specific ward.",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Ward statistics retrieved successfully",
                content = [Content(schema = Schema(implementation = WardDashboardStatsResponse::class))],
            ),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "403", description = "Insufficient permissions"),
            ApiResponse(responseCode = "404", description = "Ward not found"),
        ],
    )
    @GetMapping("/wards/{wardId}")
    fun getWardDashboard(
        @Parameter(description = "Ward UUID")
        @PathVariable wardId: UUID,
    ): ResponseEntity<*> {
        // Verify caller has access (is authenticated with pod_chief role)
        getCurrentPodId()
            ?: return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                ErrorResponse("unauthorized", "Could not determine pod for current user"),
            )

        return when (val result = dashboardService.getWardStats(WardId(wardId))) {
            is DashboardResult.Success ->
                ResponseEntity.ok(WardDashboardStatsResponse.from(result.data))
            is DashboardResult.WardNotFound ->
                ResponseEntity.notFound().build<Any>()
            is DashboardResult.SectorNotFound ->
                ResponseEntity.notFound().build<Any>()
        }
    }

    @Operation(
        summary = "Get sector dashboard statistics",
        description = "Returns aggregated statistics for a specific sector.",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Sector statistics retrieved successfully",
                content = [Content(schema = Schema(implementation = SectorDashboardStatsResponse::class))],
            ),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "403", description = "Insufficient permissions"),
            ApiResponse(responseCode = "404", description = "Sector not found"),
        ],
    )
    @GetMapping("/sectors/{sectorId}")
    fun getSectorDashboard(
        @Parameter(description = "Sector UUID")
        @PathVariable sectorId: UUID,
    ): ResponseEntity<*> {
        // Verify caller has access (is authenticated with pod_chief role)
        getCurrentPodId()
            ?: return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                ErrorResponse("unauthorized", "Could not determine pod for current user"),
            )

        return when (val result = dashboardService.getSectorStats(SectorId(sectorId))) {
            is DashboardResult.Success ->
                ResponseEntity.ok(SectorDashboardStatsResponse.from(result.data))
            is DashboardResult.WardNotFound ->
                ResponseEntity.notFound().build<Any>()
            is DashboardResult.SectorNotFound ->
                ResponseEntity.notFound().build<Any>()
        }
    }

    private fun getCurrentPodId(): PodId? {
        val adminId = getCurrentAdminId() ?: return null
        return podIdResolver.resolvePodId(adminId)
    }

    private fun getCurrentAdminId(): AdminId? {
        val authentication =
            SecurityContextHolder.getContext().authentication
                ?: return null
        val subject =
            authentication.principal as? String
                ?: return null
        return try {
            AdminId(UUID.fromString(subject))
        } catch (e: IllegalArgumentException) {
            null
        }
    }
}
