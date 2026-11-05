package com.munserv.pod.api

import com.munserv.pod.domain.PodDashboardStats
import com.munserv.pod.domain.SectorDashboardStats
import com.munserv.pod.domain.WardDashboardStats
import io.swagger.v3.oas.annotations.media.Schema

/**
 * Response DTO for pod-level dashboard statistics.
 */
@Schema(description = "Pod dashboard statistics")
data class PodDashboardStatsResponse(
    @field:Schema(description = "Total number of issues in the pod", example = "150")
    val totalIssues: Int,
    @field:Schema(description = "Number of open issues (reported, confirmed, in_progress, reopened)", example = "45")
    val openIssues: Int,
    @field:Schema(description = "Number of issues resolved this month", example = "23")
    val resolvedThisMonth: Int,
    @field:Schema(description = "Number of pending issues awaiting confirmation", example = "12")
    val pendingIssues: Int,
    @field:Schema(description = "Number of active administrators in the pod", example = "5")
    val activeAdministrators: Int,
    @field:Schema(description = "Total number of members in the pod", example = "1250")
    val totalMembers: Int,
    @field:Schema(description = "Number of active ground admins", example = "8")
    val activeGroundAdmins: Int,
    @field:Schema(description = "Number of wards in the pod", example = "4")
    val wardCount: Int,
    @field:Schema(description = "Number of sectors in the pod", example = "16")
    val sectorCount: Int,
) {
    companion object {
        fun from(stats: PodDashboardStats): PodDashboardStatsResponse =
            PodDashboardStatsResponse(
                totalIssues = stats.totalIssues,
                openIssues = stats.openIssues,
                resolvedThisMonth = stats.resolvedThisMonth,
                pendingIssues = stats.pendingIssues,
                activeAdministrators = stats.activeAdministrators,
                totalMembers = stats.totalMembers,
                activeGroundAdmins = stats.activeGroundAdmins,
                wardCount = stats.wardCount,
                sectorCount = stats.sectorCount,
            )
    }
}

/**
 * Response DTO for ward-level dashboard statistics.
 */
@Schema(description = "Ward dashboard statistics")
data class WardDashboardStatsResponse(
    @field:Schema(description = "Ward ID", example = "550e8400-e29b-41d4-a716-446655440001")
    val wardId: String,
    @field:Schema(description = "Ward name", example = "Ward 42")
    val wardName: String,
    @field:Schema(description = "Total number of issues in the ward", example = "45")
    val totalIssues: Int,
    @field:Schema(description = "Number of open issues", example = "15")
    val openIssues: Int,
    @field:Schema(description = "Number of issues resolved this month", example = "8")
    val resolvedThisMonth: Int,
    @field:Schema(description = "Number of sectors in the ward", example = "4")
    val sectorCount: Int,
    @field:Schema(description = "Number of active ground admins in the ward", example = "3")
    val activeGroundAdmins: Int,
) {
    companion object {
        fun from(stats: WardDashboardStats): WardDashboardStatsResponse =
            WardDashboardStatsResponse(
                wardId = stats.wardId.toString(),
                wardName = stats.wardName,
                totalIssues = stats.totalIssues,
                openIssues = stats.openIssues,
                resolvedThisMonth = stats.resolvedThisMonth,
                sectorCount = stats.sectorCount,
                activeGroundAdmins = stats.activeGroundAdmins,
            )
    }
}

/**
 * Response DTO for sector-level dashboard statistics.
 */
@Schema(description = "Sector dashboard statistics")
data class SectorDashboardStatsResponse(
    @field:Schema(description = "Sector ID", example = "550e8400-e29b-41d4-a716-446655440002")
    val sectorId: String,
    @field:Schema(description = "Sector name", example = "Sector A")
    val sectorName: String,
    @field:Schema(description = "Total number of issues in the sector", example = "25")
    val totalIssues: Int,
    @field:Schema(description = "Number of open issues", example = "8")
    val openIssues: Int,
    @field:Schema(description = "Number of issues resolved this month", example = "5")
    val resolvedThisMonth: Int,
    @field:Schema(description = "Number of active ground admins in the sector", example = "2")
    val activeGroundAdmins: Int,
    @field:Schema(description = "Total number of members in the sector", example = "320")
    val totalMembers: Int,
) {
    companion object {
        fun from(stats: SectorDashboardStats): SectorDashboardStatsResponse =
            SectorDashboardStatsResponse(
                sectorId = stats.sectorId.toString(),
                sectorName = stats.sectorName,
                totalIssues = stats.totalIssues,
                openIssues = stats.openIssues,
                resolvedThisMonth = stats.resolvedThisMonth,
                activeGroundAdmins = stats.activeGroundAdmins,
                totalMembers = stats.totalMembers,
            )
    }
}
