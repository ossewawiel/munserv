package com.munserv.admin.service

import com.munserv.issues.domain.Issue
import com.munserv.issues.domain.IssueId
import com.munserv.issues.domain.IssueState
import com.munserv.issues.domain.IssueType
import com.munserv.issues.repository.IssueRepository
import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldHaveSize
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

class HeatReportServiceTest {
    private lateinit var issueRepository: IssueRepository
    private lateinit var clock: Clock
    private lateinit var service: HeatReportService

    private val fixedInstant = Instant.parse("2025-01-15T10:00:00Z")
    private val testSectorId = SectorId.fromString("550e8400-e29b-41d4-a716-446655440001")
    private val testReporterId = MemberId.fromString("550e8400-e29b-41d4-a716-446655440010")
    private val testLocation = GeoPoint(-26.1350, 27.9800)

    @BeforeEach
    fun setUp() {
        issueRepository = mockk()
        clock = Clock.fixed(fixedInstant, ZoneId.of("UTC"))
        service = HeatReportService(issueRepository, clock)
    }

    private fun createTestIssue(
        id: IssueId = IssueId.generate(),
        state: IssueState = IssueState.Reported,
        type: IssueType = IssueType.POTHOLE,
        heat: Int = 10,
        reportCount: Int = 1,
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
        heat = heat,
        reportCount = reportCount,
        createdAt = createdAt,
        updatedAt = createdAt,
    )

    @Nested
    inner class GetHeatReport {
        @Test
        fun `should return issues sorted by heat descending`() {
            val issues =
                listOf(
                    createTestIssue(heat = 30),
                    createTestIssue(heat = 95),
                    createTestIssue(heat = 50),
                    createTestIssue(heat = 75),
                )

            every { issueRepository.findBySectorId(testSectorId) } returns issues

            val result = service.getHeatReport(testSectorId, limit = 20)

            result shouldHaveSize 4
            result[0].heat shouldBe 95
            result[1].heat shouldBe 75
            result[2].heat shouldBe 50
            result[3].heat shouldBe 30
        }

        @Test
        fun `should only return open issues`() {
            val issues =
                listOf(
                    createTestIssue(state = IssueState.Reported, heat = 80),
                    // Fixed = Closed
                    createTestIssue(state = IssueState.Fixed, heat = 90),
                    createTestIssue(state = IssueState.InProgress, heat = 70),
                    // Rejected = Closed
                    createTestIssue(state = IssueState.Rejected, heat = 85),
                )

            every { issueRepository.findBySectorId(testSectorId) } returns issues

            val result = service.getHeatReport(testSectorId, limit = 20)

            result shouldHaveSize 2
            result[0].heat shouldBe 80
            result[1].heat shouldBe 70
        }

        @Test
        fun `should calculate days open correctly`() {
            val sevenDaysAgo = fixedInstant.minus(7, ChronoUnit.DAYS)
            val issue = createTestIssue(createdAt = sevenDaysAgo)

            every { issueRepository.findBySectorId(testSectorId) } returns listOf(issue)

            val result = service.getHeatReport(testSectorId, limit = 20)

            result shouldHaveSize 1
            result[0].daysOpen shouldBe 7
        }

        @Test
        fun `should respect limit parameter`() {
            val issues = (1..30).map { createTestIssue(heat = it) }

            every { issueRepository.findBySectorId(testSectorId) } returns issues

            val result = service.getHeatReport(testSectorId, limit = 10)

            result shouldHaveSize 10
            result[0].heat shouldBe 30 // Highest heat first
        }

        @Test
        fun `should return empty list when no issues exist`() {
            every { issueRepository.findBySectorId(testSectorId) } returns emptyList()

            val result = service.getHeatReport(testSectorId, limit = 20)

            result.shouldBeEmpty()
        }

        @Test
        fun `should include correct issue details`() {
            val issueId = IssueId.generate()
            val issue =
                createTestIssue(
                    id = issueId,
                    type = IssueType.SEWAGE_LEAK,
                    state = IssueState.Confirmed,
                    heat = 85,
                    reportCount = 5,
                )

            every { issueRepository.findBySectorId(testSectorId) } returns listOf(issue)

            val result = service.getHeatReport(testSectorId, limit = 20)

            result shouldHaveSize 1
            val item = result[0]
            item.id shouldBe issueId
            item.type shouldBe IssueType.SEWAGE_LEAK
            item.state shouldBe IssueState.Confirmed
            item.heat shouldBe 85
            item.reportCount shouldBe 5
            item.location shouldBe testLocation
            item.thumbnailUrl shouldBe null // No photos yet
        }
    }
}
