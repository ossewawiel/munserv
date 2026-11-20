package com.munserv.admin.service

import com.munserv.admin.domain.DashboardStats
import com.munserv.admin.domain.ResolutionTime
import com.munserv.issues.repository.IssueRepository
import com.munserv.issues.service.IssueService
import com.munserv.sectors.service.SectorService
import com.munserv.shared.types.SectorId
import org.springframework.stereotype.Service
import java.time.Clock
import java.time.temporal.ChronoUnit

/**
 * Service for generating dashboard statistics for admin users.
 */
@Service
class DashboardService(
    private val issueRepository: IssueRepository,
    private val issueService: IssueService,
    private val sectorService: SectorService,
    private val clock: Clock,
) {
    /**
     * Get dashboard statistics for a specific sector.
     * Returns null if the sector is not found.
     */
    fun getDashboardStats(sectorId: SectorId): DashboardStats? {
        val sector = sectorService.findById(sectorId) ?: return null
        val issues = issueRepository.findBySectorId(sectorId)

        val now = clock.instant()
        val oneWeekAgo = now.minus(7, ChronoUnit.DAYS)

        val totalOpen = issues.count { it.isOpen }
        val byState = issues.groupingBy { it.state }.eachCount()
        val byType = issues.groupingBy { it.type }.eachCount()
        val reportedThisWeek = issues.count { it.createdAt.isAfter(oneWeekAgo) }

        val histories = issueService.getStateHistories(issues.map { it.id })
        val avgResolutionDays =
            ResolutionTime.averageDays(histories, now.minus(RESOLUTION_WINDOW_DAYS, ChronoUnit.DAYS))

        return DashboardStats(
            sectorId = sector.id,
            sectorName = sector.name,
            totalOpen = totalOpen,
            byState = byState,
            byType = byType,
            avgResolutionDays = avgResolutionDays,
            reportedThisWeek = reportedThisWeek,
        )
    }

    companion object {
        private const val RESOLUTION_WINDOW_DAYS = 90L
    }
}
