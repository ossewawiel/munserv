package com.munserv.sectors.api

import com.munserv.sectors.service.SectorService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

/**
 * REST controller for sector operations.
 */
@RestController
@RequestMapping("/api/v1/sectors")
class SectorController(
    private val sectorService: SectorService,
) {
    /**
     * Get all sectors.
     * Matches mock API: GET /api/v1/sectors -> { items: [...] }
     */
    @GetMapping
    fun getAllSectors(): ResponseEntity<SectorsListResponse> {
        val sectors = sectorService.findAll()
        return ResponseEntity.ok(sectors.toListResponse())
    }
}
