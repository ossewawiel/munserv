package com.munserv.admin.service

import com.munserv.admin.domain.DashboardStats
import com.munserv.issues.domain.Issue
import com.munserv.issues.domain.IssueId
import com.munserv.issues.domain.IssueState
import com.munserv.issues.domain.IssueType
import com.munserv.issues.repository.IssueRepository
import com.munserv.sectors.domain.Sector
import com.munserv.sectors.service.SectorService
import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.PodId
import com.munserv.shared.types.SectorId
import io.kotest.matchers.shouldBe
import io.mockk.every
import io.mockk.mockk
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import java.time.Clock
import java.time.Instant
import java.time.ZoneId
import java.time.temporal.ChronoUnit

class DashboardServiceTest {
    private lateinit var issueRepository: IssueRepository
    private lateinit var sectorService: SectorService
    private lateinit var clock: Clock
    private lateinit var service: DashboardService

    private val fixedInstant = Instant.parse("2025-01-15T10:00:00Z")
    private val testSectorId = SectorId.fromString("550e8400-e29b-41d4-a716-446655440001")
    private val testPodId = PodId.fromString("550e8400-e29b-41d4-a716-446655440000")
    private val testReporterId = MemberId.fromString("550e8400-e29b-41d4-a716-446655440010")
    private val testLocation = GeoPoint(-26.1350, 27.9800)

    @BeforeEach
    fun setUp() {
        issueRepository = mockk()
        sectorService = mockk()
        clock = Clock.fixed(fixedInstant, ZoneId.of("UTC"))
        service = DashboardService(issueRepository, sectorService, clock)
    }

    private fun createTestSector() =
        Sector(
            id = testSectorId,
            podId = testPodId,
            name = "Ward 42 - Northcliff",
            center = testLocation,
            createdAt = fixedInstant,
        )

    private fun createTestIssue(
        id: IssueId = IssueId.generate(),
        state: IssueState = IssueState.Reported,
        type: IssueType = IssueType.POTHOLE,
        createdAt: Instant = fixedInstant,
    ) = Issue(
        id = id,
        sectorId = testSectorId,
        reporterId = testReporterId,
        type = type,
        state = state,
        location = testLocation,
        address = "123 Test Street",
        description = "Test issue",
        heat = 10,
        reportCount = 1,
        createdAt = createdAt,
        updatedAt = createdAt,
    )

    @Nested
    inner class GetDashboardStats {
        @Test
        fun `should return stats with correct totalOpen count`() {
            val sector = createTestSector()
            val issues =
                listOf(
                    createTestIssue(state = IssueState.Reported),
                    createTestIssue(state = IssueState.Confirmed),
                    createTestIssue(state = IssueState.InProgress),
                    createTestIssue(state = IssueState.Fixed),
                    createTestIssue(state = IssueState.Rejected),
                )

            every { sectorService.findById(testSectorId) } returns sector
            every { issueRepository.findBySectorId(testSectorId) } returns issues

            val result = service.getDashboardStats(testSectorId)

            // totalOpen = 3 because Reported, Confirmed, InProgress are open states
            result shouldBe
                DashboardStats(
                    sectorId = testSectorId,
                    sectorName = "Ward 42 - Northcliff",
                    totalOpen = 3,
                    byState =
                        mapOf(
                            IssueState.Reported to 1,
                            IssueState.Confirmed to 1,
                            IssueState.InProgress to 1,
                            IssueState.Fixed to 1,
                            IssueState.Rejected to 1,
                        ),
                    byType = mapOf(IssueType.POTHOLE to 5),
                    avgResolutionDays = null,
                    reportedThisWeek = 5,
                )
        }

        @Test
        fun `should return null when sector not found`() {
            every { sectorService.findById(testSectorId) } returns null

            val result = service.getDashboardStats(testSectorId)

            result shouldBe null
        }

        @Test
        fun `should count by type correctly`() {
            val sector = createTestSector()
            val issues =
                listOf(
                    createTestIssue(type = IssueType.POTHOLE),
                    createTestIssue(type = IssueType.POTHOLE),
                    createTestIssue(type = IssueType.WATER_LEAK),
                    createTestIssue(type = IssueType.STREET_LIGHT),
                )

            every { sectorService.findById(testSectorId) } returns sector
            every { issueRepository.findBySectorId(testSectorId) } returns issues

            val result = service.getDashboardStats(testSectorId)

            result?.byType shouldBe
                mapOf(
                    IssueType.POTHOLE to 2,
                    IssueType.WATER_LEAK to 1,
                    IssueType.STREET_LIGHT to 1,
                )
        }

        @Test
        fun `should count issues reported this week`() {
            val sector = createTestSector()
            val oneWeekAgo = fixedInstant.minus(7, ChronoUnit.DAYS)
            val twoWeeksAgo = fixedInstant.minus(14, ChronoUnit.DAYS)

            val issues =
                listOf(
                    // This week
                    createTestIssue(createdAt = fixedInstant),
                    // This week
                    createTestIssue(createdAt = fixedInstant.minus(3, ChronoUnit.DAYS)),
                    // Over a week ago
                    createTestIssue(createdAt = oneWeekAgo.minus(1, ChronoUnit.HOURS)),
                    // Two weeks ago
                    createTestIssue(createdAt = twoWeeksAgo),
                )

            every { sectorService.findById(testSectorId) } returns sector
            every { issueRepository.findBySectorId(testSectorId) } returns issues

            val result = service.getDashboardStats(testSectorId)

            result?.reportedThisWeek shouldBe 2
        }

        @Test
        fun `should return zero stats for empty sector`() {
            val sector = createTestSector()

            every { sectorService.findById(testSectorId) } returns sector
            every { issueRepository.findBySectorId(testSectorId) } returns emptyList()

            val result = service.getDashboardStats(testSectorId)

            result shouldBe
                DashboardStats(
                    sectorId = testSectorId,
                    sectorName = "Ward 42 - Northcliff",
                    totalOpen = 0,
                    byState = emptyMap(),
                    byType = emptyMap(),
                    avgResolutionDays = null,
                    reportedThisWeek = 0,
                )
        }
    }
}
