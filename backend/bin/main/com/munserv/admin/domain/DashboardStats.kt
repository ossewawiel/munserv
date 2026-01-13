package com.munserv.admin.domain

import com.munserv.issues.domain.IssueState
import com.munserv.issues.domain.IssueType
import com.munserv.shared.types.SectorId

/**
 * Domain model representing dashboard statistics for a sector.
 */
data class DashboardStats(
    val sectorId: SectorId,
    val sectorName: String,
    val totalOpen: Int,
    val byState: Map<IssueState, Int>,
    val byType: Map<IssueType, Int>,
    val avgResolutionDays: Double?,
    val reportedThisWeek: Int,
)
