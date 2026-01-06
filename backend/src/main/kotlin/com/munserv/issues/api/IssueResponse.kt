package com.munserv.issues.api

import com.munserv.issues.domain.Issue

/**
 * Summary response for issues list.
 */
data class IssueSummaryResponse(
    val id: String,
    val type: String,
    val state: String,
    val location: LocationResponse,
    val heat: Int,
    val thumbnailUrl: String?,
    val createdAt: String,
)

/**
 * Full issue detail response.
 */
data class IssueDetailResponse(
    val id: String,
    val type: String,
    val state: String,
    val location: LocationResponse,
    val address: String?,
    val description: String?,
    val heat: Int,
    val photoUrls: List<String>,
    val sectorId: String,
    val reporterId: String,
    val reportCount: Int,
    val createdAt: String,
    val updatedAt: String,
)

/**
 * Location in response.
 */
data class LocationResponse(
    val latitude: Double,
    val longitude: Double,
)

/**
 * Paginated list response.
 */
data class PaginatedIssuesResponse(
    val items: List<IssueSummaryResponse>,
    val pagination: PaginationInfo,
)

/**
 * Pagination metadata.
 */
data class PaginationInfo(
    val page: Int,
    val limit: Int,
    val totalItems: Int,
    val totalPages: Int,
)

/**
 * Error response.
 */
data class ErrorResponse(
    val error: ErrorDetail,
)

/**
 * Error detail.
 */
data class ErrorDetail(
    val code: String,
    val message: String,
)

// Extension functions to convert domain to response

fun Issue.toSummaryResponse(thumbnailUrl: String? = null) =
    IssueSummaryResponse(
        id = id.value.toString(),
        type = type.toApiString(),
        state = state.toApiString(),
        location = LocationResponse(location.latitude, location.longitude),
        heat = heat,
        thumbnailUrl = thumbnailUrl,
        createdAt = createdAt.toString(),
    )

fun Issue.toDetailResponse(photoUrls: List<String> = emptyList()) =
    IssueDetailResponse(
        id = id.value.toString(),
        type = type.toApiString(),
        state = state.toApiString(),
        location = LocationResponse(location.latitude, location.longitude),
        address = address,
        description = description,
        heat = heat,
        photoUrls = photoUrls,
        sectorId = sectorId.value.toString(),
        reporterId = reporterId.value.toString(),
        reportCount = reportCount,
        createdAt = createdAt.toString(),
        updatedAt = updatedAt.toString(),
    )
