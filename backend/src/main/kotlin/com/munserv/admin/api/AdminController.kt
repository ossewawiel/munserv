package com.munserv.admin.api

import com.munserv.admin.domain.MemberWithStats
import com.munserv.admin.service.DashboardService
import com.munserv.admin.service.HeatReportService
import com.munserv.auth.domain.Member
import com.munserv.auth.repository.MemberRepository
import com.munserv.issues.repository.IssueRepository
import com.munserv.shared.types.SectorId
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import java.time.Clock
import kotlin.math.ceil

/**
 * REST controller for admin dashboard and reports.
 * All endpoints require admin role (enforced by SecurityConfig).
 */
@RestController
@RequestMapping("/api/v1/admin")
class AdminController(
    private val dashboardService: DashboardService,
    private val heatReportService: HeatReportService,
    private val memberRepository: MemberRepository,
    private val issueRepository: IssueRepository,
    private val clock: Clock,
) {
    /**
     * GET /api/v1/admin/dashboard
     * Returns dashboard statistics for the given sector.
     */
    @GetMapping("/dashboard")
    fun getDashboard(
        @RequestParam sectorId: String,
    ): ResponseEntity<DashboardResponse> {
        val id = SectorId.fromString(sectorId)
        val stats =
            dashboardService.getDashboardStats(id)
                ?: return ResponseEntity.notFound().build()

        return ResponseEntity.ok(stats.toResponse())
    }

    /**
     * GET /api/v1/admin/reports/heat
     * Returns issues ranked by heat score descending.
     */
    @GetMapping("/reports/heat")
    fun getHeatReport(
        @RequestParam sectorId: String,
        @RequestParam(defaultValue = "20") limit: Int,
    ): ResponseEntity<HeatReportResponse> {
        val id = SectorId.fromString(sectorId)
        val items = heatReportService.getHeatReport(id, limit)
        val response = items.toHeatReportResponse(clock.instant())

        return ResponseEntity.ok(response)
    }

    /**
     * GET /api/v1/admin/members
     * Returns paginated list of members for the sector with issue counts.
     */
    @GetMapping("/members")
    fun getMembers(
        @RequestParam sectorId: String,
        @RequestParam(defaultValue = "1") page: Int,
        @RequestParam(defaultValue = "20") limit: Int,
    ): ResponseEntity<MembersListResponse> {
        val id = SectorId.fromString(sectorId)
        val allMembers = memberRepository.findBySectorId(id)

        val totalItems = allMembers.size
        val totalPages = if (totalItems == 0) 1 else ceil(totalItems.toDouble() / limit).toInt()
        val validPage = page.coerceIn(1, totalPages)

        val startIndex = (validPage - 1) * limit
        val pagedMembers = allMembers.drop(startIndex).take(limit)

        val memberResponses =
            pagedMembers.map { member ->
                val issueCount = issueRepository.findByReporterId(member.id).size
                member.toMemberWithStats(issueCount).toResponse()
            }

        val response =
            MembersListResponse(
                items = memberResponses,
                pagination =
                    PaginationResponse(
                        page = validPage,
                        limit = limit,
                        totalItems = totalItems,
                        totalPages = totalPages,
                    ),
            )

        return ResponseEntity.ok(response)
    }

    private fun Member.toMemberWithStats(issueCount: Int) =
        MemberWithStats(
            id = id,
            firstName = firstName,
            surname = surname,
            phoneNumber = maskPhoneNumber(phoneHash),
            address = address,
            status = status,
            issueCount = issueCount,
            joinedAt = createdAt,
        )

    @Suppress("UNUSED_PARAMETER")
    private fun maskPhoneNumber(phoneHash: String): String {
        // For security, we don't store the actual phone number
        // Return a masked placeholder
        return "***-***-****"
    }
}
