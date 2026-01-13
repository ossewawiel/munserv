package com.munserv.sectors.api

import com.munserv.sectors.domain.Sector

/**
 * Response DTO for center coordinates.
 */
data class CenterResponse(
    val latitude: Double,
    val longitude: Double,
)

/**
 * Response DTO for a single sector.
 */
data class SectorResponse(
    val id: String,
    val name: String,
    val center: CenterResponse,
)

/**
 * Response DTO for a list of sectors.
 */
data class SectorsListResponse(
    val items: List<SectorResponse>,
)

/**
 * Extension function to convert domain Sector to API response.
 */
fun Sector.toResponse(): SectorResponse =
    SectorResponse(
        id = id.toString(),
        name = name,
        center =
            CenterResponse(
                latitude = center.latitude,
                longitude = center.longitude,
            ),
    )

/**
 * Extension function to convert list of sectors to API response.
 */
fun List<Sector>.toListResponse(): SectorsListResponse =
    SectorsListResponse(
        items = map { it.toResponse() },
    )
