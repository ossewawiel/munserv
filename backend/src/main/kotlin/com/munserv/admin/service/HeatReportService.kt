package com.munserv.admin.service

import com.munserv.admin.domain.HeatReportItem
import com.munserv.issues.domain.Issue
import com.munserv.issues.repository.IssueRepository
import com.munserv.shared.types.SectorId
import org.springframework.stereotype.Service
import java.time.Clock
import java.time.temporal.ChronoUnit

/**
 * Service for generating heat reports ranking issues by priority.
 */
@Service
class HeatReportService(
    private val issueRepository: IssueRepository,
    private val clock: Clock,
) {
    /**
     * Get open issues for a sector ranked by heat score descending.
     *
     * @param sectorId The sector to get the report for
     * @param limit Maximum number of items to return (default 20)
     * @return List of heat report items sorted by heat descending
     */
    fun getHeatReport(
        sectorId: SectorId,
        limit: Int = 20,
    ): List<HeatReportItem> {
        val now = clock.instant()

        return issueRepository.findBySectorId(sectorId)
            .filter { it.isOpen }
            .sortedByDescending { it.heat }
            .take(limit)
            .map { it.toHeatReportItem(now) }
    }

    private fun Issue.toHeatReportItem(now: java.time.Instant): HeatReportItem {
        val daysOpen = ChronoUnit.DAYS.between(createdAt, now)

        // TODO: Add thumbnailUrl photo support in Phase 5
        return HeatReportItem(
            id = id,
            type = type,
            state = state,
            heat = heat,
            daysOpen = daysOpen,
            reportCount = reportCount,
            location = location,
            thumbnailUrl = null,
        )
    }
}
