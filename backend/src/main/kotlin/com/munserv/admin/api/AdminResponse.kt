package com.munserv.admin.api

import com.munserv.admin.domain.DashboardStats
import com.munserv.admin.domain.HeatReportItem
import com.munserv.admin.domain.MemberWithStats
import java.time.Instant

/**
 * Response DTOs for admin API endpoints.
 *
 * Dashboard Response DTOs
 */

data class DashboardResponse(
    val sectorId: String,
    val sectorName: String,
    val stats: StatsResponse,
)

data class StatsResponse(
    val totalOpen: Int,
    val byState: Map<String, Int>,
    val byType: Map<String, Int>,
    val avgResolutionDays: Double?,
    val reportedThisWeek: Int,
)

fun DashboardStats.toResponse() =
    DashboardResponse(
        sectorId = sectorId.value.toString(),
        sectorName = sectorName,
        stats =
            StatsResponse(
                totalOpen = totalOpen,
                byState = byState.mapKeys { it.key.toApiString() },
                byType = byType.mapKeys { it.key.toApiString() },
                avgResolutionDays = avgResolutionDays,
                reportedThisWeek = reportedThisWeek,
            ),
    )

// ================================
// Heat Report Response
// ================================

data class HeatReportResponse(
    val generatedAt: String,
    val items: List<HeatReportItemResponse>,
)

data class HeatReportItemResponse(
    val id: String,
    val type: String,
    val state: String,
    val heat: Int,
    val daysOpen: Long,
    val reportCount: Int,
    val location: LocationResponse,
    val thumbnailUrl: String?,
)

data class LocationResponse(
    val latitude: Double,
    val longitude: Double,
)

fun HeatReportItem.toResponse() =
    HeatReportItemResponse(
        id = id.value.toString(),
        type = type.toApiString(),
        state = state.toApiString(),
        heat = heat,
        daysOpen = daysOpen,
        reportCount = reportCount,
        location = LocationResponse(location.latitude, location.longitude),
        thumbnailUrl = thumbnailUrl,
    )

fun List<HeatReportItem>.toHeatReportResponse(generatedAt: Instant) =
    HeatReportResponse(
        generatedAt = generatedAt.toString(),
        items = map { it.toResponse() },
    )

// ================================
// Members Response
// ================================

data class MembersListResponse(
    val items: List<MemberResponse>,
    val pagination: PaginationResponse,
)

data class MemberResponse(
    val id: String,
    val firstName: String,
    val surname: String,
    val phoneNumber: String,
    val address: String,
    val status: String,
    val issueCount: Int,
    val joinedAt: String,
    // Ground Admin fields
    val isGroundAdmin: Boolean,
    val groundAdminStatus: String?,
    val hasPendingApplication: Boolean,
    val hasInvitationPending: Boolean,
    val pendingApplicationId: String?,
)

data class PaginationResponse(
    val page: Int,
    val limit: Int,
    val totalItems: Int,
    val totalPages: Int,
)

data class PendingCountResponse(
    val count: Int,
)

fun MemberWithStats.toResponse() =
    MemberResponse(
        id = id.value.toString(),
        firstName = firstName,
        surname = surname,
        phoneNumber = phoneNumber,
        address = address,
        status = status.toString(),
        issueCount = issueCount,
        joinedAt = joinedAt.toString(),
        isGroundAdmin = isGroundAdmin,
        groundAdminStatus = groundAdminStatus?.toApiString(),
        hasPendingApplication = hasPendingApplication,
        hasInvitationPending = hasInvitationPending,
        pendingApplicationId = pendingApplicationId,
    )

// Note: IssueType.toApiString() and IssueState.toApiString() are already defined
// in their respective domain classes
