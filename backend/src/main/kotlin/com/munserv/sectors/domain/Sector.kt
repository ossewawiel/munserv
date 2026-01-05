package com.munserv.sectors.domain

import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.PodId
import com.munserv.shared.types.SectorId
import java.time.Instant

/**
 * Domain entity representing a geographic sector within a pod.
 * Sectors are the primary organizational unit for issue management.
 *
 * This is a pure domain class with no framework dependencies.
 */
data class Sector(
    val id: SectorId,
    val podId: PodId,
    val name: String,
    val center: GeoPoint,
    val boundary: List<GeoPoint>? = null,
    val createdAt: Instant = Instant.now(),
    val updatedAt: Instant = Instant.now(),
)
