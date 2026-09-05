package com.munserv.sectors.api

import com.munserv.admin.domain.AdminRole
import com.munserv.sectors.service.SectorSettingsResult
import com.munserv.sectors.service.SectorSettingsService
import com.munserv.shared.security.RequireRole
import com.munserv.shared.types.SectorId
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.media.Content
import io.swagger.v3.oas.annotations.media.Schema
import io.swagger.v3.oas.annotations.responses.ApiResponse
import io.swagger.v3.oas.annotations.responses.ApiResponses
import io.swagger.v3.oas.annotations.security.SecurityRequirement
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PatchMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

/**
 * REST controller for sector settings management.
 * Provides endpoints for viewing and updating sector configuration.
 *
 * Requires SECTOR_CHIEF role or higher for all operations.
 * Sector admins (SECTOR_ADMIN) cannot access these endpoints.
 */
@RestController
@RequestMapping("/api/v1/sectors/{sectorId}/settings")
@Tag(name = "Sector Settings", description = "Endpoints for managing sector configuration")
@SecurityRequirement(name = "bearerAuth")
@RequireRole(AdminRole.SECTOR_CHIEF)
class SectorSettingsController(
    private val settingsService: SectorSettingsService,
) {
    @Operation(
        summary = "Get sector settings",
        description = "Retrieve the settings for a specific sector. Creates default settings if none exist.",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Settings retrieved successfully",
                content = [Content(schema = Schema(implementation = SectorSettingsResponse::class))],
            ),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "403", description = "Access denied to this sector"),
            ApiResponse(responseCode = "404", description = "Sector not found"),
        ],
    )
    @GetMapping
    fun getSettings(
        @Parameter(description = "Sector UUID", required = true)
        @PathVariable sectorId: UUID,
    ): ResponseEntity<*> =
        when (val result = settingsService.getSettings(SectorId(sectorId))) {
            is SectorSettingsResult.Success -> {
                ResponseEntity.ok(SectorSettingsResponse.from(result.settings))
            }

            is SectorSettingsResult.SectorNotFound -> {
                ResponseEntity.notFound().build<Any>()
            }

            is SectorSettingsResult.ValidationError -> {
                ResponseEntity.badRequest().body(mapOf("errors" to result.errors))
            }
        }

    @Operation(
        summary = "Update sector settings",
        description = "Partially update the settings for a sector. Only provided fields will be updated.",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Settings updated successfully",
                content = [Content(schema = Schema(implementation = SectorSettingsResponse::class))],
            ),
            ApiResponse(responseCode = "400", description = "Validation error"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "403", description = "Access denied to this sector"),
            ApiResponse(responseCode = "404", description = "Sector not found"),
        ],
    )
    @PatchMapping
    fun updateSettings(
        @Parameter(description = "Sector UUID", required = true)
        @PathVariable sectorId: UUID,
        @RequestBody request: UpdateSectorSettingsRequest,
    ): ResponseEntity<*> =
        when (val result = settingsService.updateSettings(SectorId(sectorId), request.toCommand())) {
            is SectorSettingsResult.Success -> {
                ResponseEntity.ok(SectorSettingsResponse.from(result.settings))
            }

            is SectorSettingsResult.SectorNotFound -> {
                ResponseEntity.notFound().build<Any>()
            }

            is SectorSettingsResult.ValidationError -> {
                ResponseEntity.badRequest().body(mapOf("errors" to result.errors))
            }
        }
}
