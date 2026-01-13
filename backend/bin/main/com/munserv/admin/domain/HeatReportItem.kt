package com.munserv.admin.domain

import com.munserv.issues.domain.IssueId
import com.munserv.issues.domain.IssueState
import com.munserv.issues.domain.IssueType
import com.munserv.shared.types.GeoPoint

/**
 * Domain model representing an issue in the heat report.
 * Contains summary information and heat ranking data.
 */
data class HeatReportItem(
    val id: IssueId,
    val type: IssueType,
    val state: IssueState,
    val heat: Int,
    val daysOpen: Long,
    val reportCount: Int,
    val location: GeoPoint,
    val thumbnailUrl: String?,
)
