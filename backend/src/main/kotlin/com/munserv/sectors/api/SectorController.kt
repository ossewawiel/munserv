package com.munserv.sectors.api

import com.munserv.sectors.service.SectorService
import com.munserv.shared.types.SectorId
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.responses.ApiResponse
import io.swagger.v3.oas.annotations.responses.ApiResponses
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

/**
 * REST controller for sector operations.
 */
@RestController
@RequestMapping("/api/v1/sectors")
@Tag(name = "Sectors", description = "Sector management operations")
class SectorController(
    private val sectorService: SectorService,
) {
    /**
     * Get all sectors.
     * Matches mock API: GET /api/v1/sectors -> { items: [...] }
     */
    @Operation(summary = "List all sectors", description = "Retrieve all available sectors")
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "Sectors retrieved successfully"),
        ],
    )
    @GetMapping
    fun getAllSectors(): ResponseEntity<SectorsListResponse> {
        val sectors = sectorService.findAll()
        return ResponseEntity.ok(sectors.toListResponse())
    }

    /**
     * Get a sector by ID.
     */
    @Operation(summary = "Get sector by ID", description = "Retrieve a specific sector by its UUID")
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "Sector retrieved successfully"),
            ApiResponse(responseCode = "404", description = "Sector not found"),
        ],
    )
    @GetMapping("/{id}")
    fun getSectorById(
        @Parameter(description = "Sector UUID")
        @PathVariable id: UUID,
    ): ResponseEntity<SectorResponse> {
        val sector = sectorService.findById(SectorId(id))
            ?: return ResponseEntity.notFound().build()

        return ResponseEntity.ok(sector.toResponse())
    }
}
