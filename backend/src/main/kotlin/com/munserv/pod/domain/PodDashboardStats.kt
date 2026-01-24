package com.munserv.pod.domain

import com.munserv.shared.types.SectorId
import com.munserv.shared.types.WardId

/**
 * Dashboard statistics at the pod level.
 * Aggregates counts from all wards and sectors in the pod.
 */
data class PodDashboardStats(
    val totalIssues: Int,
    val openIssues: Int,
    val resolvedThisMonth: Int,
    val pendingIssues: Int,
    val activeAdministrators: Int,
    val totalMembers: Int,
    val activeGroundAdmins: Int,
    val wardCount: Int,
    val sectorCount: Int,
)

/**
 * Dashboard statistics at the ward level.
 * Aggregates counts from all sectors in the ward.
 */
data class WardDashboardStats(
    val wardId: WardId,
    val wardName: String,
    val totalIssues: Int,
    val openIssues: Int,
    val resolvedThisMonth: Int,
    val sectorCount: Int,
    val activeGroundAdmins: Int,
)

/**
 * Dashboard statistics at the sector level.
 */
data class SectorDashboardStats(
    val sectorId: SectorId,
    val sectorName: String,
    val totalIssues: Int,
    val openIssues: Int,
    val resolvedThisMonth: Int,
    val activeGroundAdmins: Int,
    val totalMembers: Int,
)
