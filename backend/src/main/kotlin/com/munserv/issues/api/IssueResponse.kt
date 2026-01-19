package com.munserv.issues.api

import com.munserv.issues.domain.Issue
import com.munserv.issues.domain.IssueStateHistoryEntry

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
    val stateHistory: List<StateHistoryEntryResponse>,
    val sectorId: String,
    val reporterId: String,
    val reportCount: Int,
    val createdAt: String,
    val updatedAt: String,
)

/**
 * State history entry response.
 */
data class StateHistoryEntryResponse(
    val state: String,
    val changedAt: String,
    val changedBy: String?,
    val note: String?,
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

fun Issue.toDetailResponse(
    photoUrls: List<String> = emptyList(),
    stateHistory: List<StateHistoryEntryResponse> = emptyList(),
) = IssueDetailResponse(
    id = id.value.toString(),
    type = type.toApiString(),
    state = state.toApiString(),
    location = LocationResponse(location.latitude, location.longitude),
    address = address,
    description = description,
    heat = heat,
    photoUrls = photoUrls,
    stateHistory = stateHistory,
    sectorId = sectorId.value.toString(),
    reporterId = reporterId.value.toString(),
    reportCount = reportCount,
    createdAt = createdAt.toString(),
    updatedAt = updatedAt.toString(),
)

/**
 * Convert state history entry to response.
 */
fun IssueStateHistoryEntry.toResponse(adminName: String? = null) =
    StateHistoryEntryResponse(
        state = state.toApiString(),
        changedAt = changedAt.toString(),
        changedBy = adminName ?: changedBy?.value?.toString(),
        note = note,
    )
