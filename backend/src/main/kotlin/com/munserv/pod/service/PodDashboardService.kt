package com.munserv.pod.service

import com.munserv.pod.domain.PodDashboardStats
import com.munserv.pod.domain.SectorDashboardStats
import com.munserv.pod.domain.WardDashboardStats
import com.munserv.pod.repository.PodDashboardRepository
import com.munserv.pod.repository.PodRepository
import com.munserv.shared.types.PodId
import com.munserv.shared.types.SectorId
import com.munserv.shared.types.WardId
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

/**
 * Service for retrieving dashboard statistics at pod, ward, and sector levels.
 */
@Service
class PodDashboardService(
    private val podRepository: PodRepository,
    private val dashboardRepository: PodDashboardRepository,
) {
    /**
     * Get dashboard statistics for the entire pod.
     *
     * @param podId The pod to get statistics for
     * @return Success with stats, or NotFound if pod doesn't exist
     */
    @Transactional(readOnly = true)
    fun getPodStats(podId: PodId): PodResult<PodDashboardStats> {
        if (!podRepository.existsById(podId)) {
            return PodResult.NotFound(podId)
        }

        val stats = dashboardRepository.getPodStats(podId)
        return PodResult.Success(
            PodDashboardStats(
                totalIssues = stats.totalIssues,
                openIssues = stats.openIssues,
                resolvedThisMonth = stats.resolvedThisMonth,
                pendingIssues = stats.pendingIssues,
                activeAdministrators = stats.activeAdministrators,
                totalMembers = stats.totalMembers,
                activeGroundAdmins = stats.activeGroundAdmins,
                wardCount = stats.wardCount,
                sectorCount = stats.sectorCount,
            ),
        )
    }

    /**
     * Get dashboard statistics for a specific ward.
     *
     * @param wardId The ward to get statistics for
     * @return Success with stats, or NotFound if ward doesn't exist
     */
    @Transactional(readOnly = true)
    fun getWardStats(wardId: WardId): DashboardResult<WardDashboardStats> {
        val wardName =
            dashboardRepository.getWardName(wardId)
                ?: return DashboardResult.WardNotFound(wardId)

        val stats =
            dashboardRepository.getWardStats(wardId)
                ?: return DashboardResult.WardNotFound(wardId)

        return DashboardResult.Success(
            WardDashboardStats(
                wardId = wardId,
                wardName = wardName,
                totalIssues = stats.totalIssues,
                openIssues = stats.openIssues,
                resolvedThisMonth = stats.resolvedThisMonth,
                sectorCount = stats.sectorCount,
                activeGroundAdmins = stats.activeGroundAdmins,
            ),
        )
    }

    /**
     * Get dashboard statistics for a specific sector.
     *
     * @param sectorId The sector to get statistics for
     * @return Success with stats, or NotFound if sector doesn't exist
     */
    @Transactional(readOnly = true)
    fun getSectorStats(sectorId: SectorId): DashboardResult<SectorDashboardStats> {
        val sectorName =
            dashboardRepository.getSectorName(sectorId)
                ?: return DashboardResult.SectorNotFound(sectorId)

        val stats =
            dashboardRepository.getSectorStats(sectorId)
                ?: return DashboardResult.SectorNotFound(sectorId)

        return DashboardResult.Success(
            SectorDashboardStats(
                sectorId = sectorId,
                sectorName = sectorName,
                totalIssues = stats.totalIssues,
                openIssues = stats.openIssues,
                resolvedThisMonth = stats.resolvedThisMonth,
                activeGroundAdmins = stats.activeGroundAdmins,
                totalMembers = stats.totalMembers,
            ),
        )
    }
}

/**
 * Sealed interface for dashboard operation results.
 * Distinct from PodResult to handle ward/sector not found cases.
 */
sealed interface DashboardResult<out T> {
    data class Success<T>(
        val data: T,
    ) : DashboardResult<T>

    data class WardNotFound(
        val wardId: WardId,
    ) : DashboardResult<Nothing>

    data class SectorNotFound(
        val sectorId: SectorId,
    ) : DashboardResult<Nothing>
}
