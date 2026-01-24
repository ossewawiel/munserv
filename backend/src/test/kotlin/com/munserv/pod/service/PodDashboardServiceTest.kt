package com.munserv.pod.service

import com.munserv.pod.domain.PodDashboardStats
import com.munserv.pod.domain.SectorDashboardStats
import com.munserv.pod.domain.WardDashboardStats
import com.munserv.pod.repository.PodDashboardRepository
import com.munserv.pod.repository.PodRepository
import com.munserv.pod.repository.PodStatsRow
import com.munserv.pod.repository.SectorStatsRow
import com.munserv.pod.repository.WardStatsRow
import com.munserv.shared.types.PodId
import com.munserv.shared.types.SectorId
import com.munserv.shared.types.WardId
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import java.util.UUID

class PodDashboardServiceTest {
    private lateinit var podRepository: PodRepository
    private lateinit var dashboardRepository: PodDashboardRepository
    private lateinit var service: PodDashboardService

    private val testPodId = PodId(UUID.fromString("550e8400-e29b-41d4-a716-446655440000"))
    private val testWardId = WardId(UUID.fromString("550e8400-e29b-41d4-a716-446655440001"))
    private val testSectorId = SectorId(UUID.fromString("550e8400-e29b-41d4-a716-446655440002"))

    @BeforeEach
    fun setUp() {
        podRepository = mockk()
        dashboardRepository = mockk()
        service = PodDashboardService(podRepository, dashboardRepository)
    }

    @Nested
    inner class GetPodStats {
        @Test
        fun `should return NotFound when pod does not exist`() {
            every { podRepository.existsById(testPodId) } returns false

            val result = service.getPodStats(testPodId)

            result.shouldBeInstanceOf<PodResult.NotFound>()
            (result as PodResult.NotFound).podId shouldBe testPodId
        }

        @Test
        fun `should return Success with aggregated statistics`() {
            val statsRow = PodStatsRow(
                totalIssues = 150,
                openIssues = 45,
                resolvedThisMonth = 23,
                pendingIssues = 12,
                activeAdministrators = 5,
                totalMembers = 1250,
                activeGroundAdmins = 8,
                wardCount = 4,
                sectorCount = 16,
            )

            every { podRepository.existsById(testPodId) } returns true
            every { dashboardRepository.getPodStats(testPodId) } returns statsRow

            val result = service.getPodStats(testPodId)

            val success = result.shouldBeInstanceOf<PodResult.Success<PodDashboardStats>>()
            success.data.totalIssues shouldBe 150
            success.data.openIssues shouldBe 45
            success.data.resolvedThisMonth shouldBe 23
            success.data.pendingIssues shouldBe 12
            success.data.activeAdministrators shouldBe 5
            success.data.totalMembers shouldBe 1250
            success.data.activeGroundAdmins shouldBe 8
            success.data.wardCount shouldBe 4
            success.data.sectorCount shouldBe 16

            verify { dashboardRepository.getPodStats(testPodId) }
        }

        @Test
        fun `should return zero counts when pod has no data`() {
            val emptyStatsRow = PodStatsRow(
                totalIssues = 0,
                openIssues = 0,
                resolvedThisMonth = 0,
                pendingIssues = 0,
                activeAdministrators = 0,
                totalMembers = 0,
                activeGroundAdmins = 0,
                wardCount = 0,
                sectorCount = 0,
            )

            every { podRepository.existsById(testPodId) } returns true
            every { dashboardRepository.getPodStats(testPodId) } returns emptyStatsRow

            val result = service.getPodStats(testPodId)

            val success = result.shouldBeInstanceOf<PodResult.Success<PodDashboardStats>>()
            success.data.totalIssues shouldBe 0
            success.data.wardCount shouldBe 0
        }
    }

    @Nested
    inner class GetWardStats {
        @Test
        fun `should return WardNotFound when ward does not exist`() {
            every { dashboardRepository.getWardName(testWardId) } returns null

            val result = service.getWardStats(testWardId)

            result.shouldBeInstanceOf<DashboardResult.WardNotFound>()
            (result as DashboardResult.WardNotFound).wardId shouldBe testWardId
        }

        @Test
        fun `should return Success with ward statistics`() {
            val statsRow = WardStatsRow(
                totalIssues = 45,
                openIssues = 15,
                resolvedThisMonth = 8,
                sectorCount = 4,
                activeGroundAdmins = 3,
            )

            every { dashboardRepository.getWardName(testWardId) } returns "Ward 42"
            every { dashboardRepository.getWardStats(testWardId) } returns statsRow

            val result = service.getWardStats(testWardId)

            val success = result.shouldBeInstanceOf<DashboardResult.Success<WardDashboardStats>>()
            success.data.wardId shouldBe testWardId
            success.data.wardName shouldBe "Ward 42"
            success.data.totalIssues shouldBe 45
            success.data.openIssues shouldBe 15
            success.data.resolvedThisMonth shouldBe 8
            success.data.sectorCount shouldBe 4
            success.data.activeGroundAdmins shouldBe 3
        }

        @Test
        fun `should return WardNotFound when ward name exists but stats query fails`() {
            every { dashboardRepository.getWardName(testWardId) } returns "Ward 42"
            every { dashboardRepository.getWardStats(testWardId) } returns null

            val result = service.getWardStats(testWardId)

            result.shouldBeInstanceOf<DashboardResult.WardNotFound>()
        }
    }

    @Nested
    inner class GetSectorStats {
        @Test
        fun `should return SectorNotFound when sector does not exist`() {
            every { dashboardRepository.getSectorName(testSectorId) } returns null

            val result = service.getSectorStats(testSectorId)

            result.shouldBeInstanceOf<DashboardResult.SectorNotFound>()
            (result as DashboardResult.SectorNotFound).sectorId shouldBe testSectorId
        }

        @Test
        fun `should return Success with sector statistics`() {
            val statsRow = SectorStatsRow(
                totalIssues = 25,
                openIssues = 8,
                resolvedThisMonth = 5,
                activeGroundAdmins = 2,
                totalMembers = 320,
            )

            every { dashboardRepository.getSectorName(testSectorId) } returns "Sector A"
            every { dashboardRepository.getSectorStats(testSectorId) } returns statsRow

            val result = service.getSectorStats(testSectorId)

            val success = result.shouldBeInstanceOf<DashboardResult.Success<SectorDashboardStats>>()
            success.data.sectorId shouldBe testSectorId
            success.data.sectorName shouldBe "Sector A"
            success.data.totalIssues shouldBe 25
            success.data.openIssues shouldBe 8
            success.data.resolvedThisMonth shouldBe 5
            success.data.activeGroundAdmins shouldBe 2
            success.data.totalMembers shouldBe 320
        }

        @Test
        fun `should return SectorNotFound when sector name exists but stats query fails`() {
            every { dashboardRepository.getSectorName(testSectorId) } returns "Sector A"
            every { dashboardRepository.getSectorStats(testSectorId) } returns null

            val result = service.getSectorStats(testSectorId)

            result.shouldBeInstanceOf<DashboardResult.SectorNotFound>()
        }
    }
}
