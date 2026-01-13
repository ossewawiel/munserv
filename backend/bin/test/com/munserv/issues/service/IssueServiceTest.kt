package com.munserv.issues.service

import com.munserv.issues.domain.Issue
import com.munserv.issues.domain.IssueId
import com.munserv.issues.domain.IssueState
import com.munserv.issues.domain.IssueType
import com.munserv.issues.repository.IssueRepository
import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import java.time.Clock
import java.time.Instant
import java.time.ZoneId
import java.util.UUID

class IssueServiceTest {
    private lateinit var repository: IssueRepository
    private lateinit var clock: Clock
    private lateinit var service: IssueService

    private val fixedInstant = Instant.parse("2025-01-15T10:00:00Z")
    private val testIssueId = IssueId(UUID.fromString("550e8400-e29b-41d4-a716-446655440100"))
    private val testSectorId = SectorId(UUID.fromString("550e8400-e29b-41d4-a716-446655440001"))
    private val testReporterId = MemberId(UUID.fromString("550e8400-e29b-41d4-a716-446655440010"))
    private val testLocation = GeoPoint(-26.1350, 27.9800)

    @BeforeEach
    fun setUp() {
        repository = mockk()
        clock = Clock.fixed(fixedInstant, ZoneId.of("UTC"))
        service = IssueService(repository, clock)
    }

    private fun createTestIssue(
        id: IssueId = testIssueId,
        state: IssueState = IssueState.Reported,
        heat: Int = 10,
        reportCount: Int = 1,
    ) = Issue(
        id = id,
        sectorId = testSectorId,
        reporterId = testReporterId,
        type = IssueType.POTHOLE,
        state = state,
        location = testLocation,
        address = "123 Test Street",
        description = "A large pothole",
        heat = heat,
        reportCount = reportCount,
        createdAt = fixedInstant,
        updatedAt = fixedInstant,
    )

    @Nested
    inner class FindById {
        @Test
        fun `should return Success when issue exists`() {
            val issue = createTestIssue()
            every { repository.findById(testIssueId) } returns issue

            val result = service.findById(testIssueId)

            result.shouldBeInstanceOf<IssueResult.Success>()
            (result as IssueResult.Success).issue shouldBe issue
        }

        @Test
        fun `should return NotFound when issue does not exist`() {
            every { repository.findById(testIssueId) } returns null

            val result = service.findById(testIssueId)

            result.shouldBeInstanceOf<IssueResult.NotFound>()
            (result as IssueResult.NotFound).id shouldBe testIssueId
        }
    }

    @Nested
    inner class FindAll {
        @Test
        fun `should return all issues`() {
            val issues = listOf(createTestIssue(), createTestIssue(id = IssueId.generate()))
            every { repository.findAll() } returns issues

            val result = service.findAll()

            result shouldBe issues
        }

        @Test
        fun `should return empty list when no issues exist`() {
            every { repository.findAll() } returns emptyList()

            val result = service.findAll()

            result shouldBe emptyList()
        }
    }

    @Nested
    inner class FindByReporter {
        @Test
        fun `should return issues for reporter`() {
            val issues = listOf(createTestIssue())
            every { repository.findByReporterId(testReporterId) } returns issues

            val result = service.findByReporter(testReporterId)

            result shouldBe issues
        }
    }

    @Nested
    inner class FindOpenIssues {
        @Test
        fun `should return open issues sorted by heat`() {
            val issues =
                listOf(
                    createTestIssue(heat = 80),
                    createTestIssue(id = IssueId.generate(), heat = 60),
                )
            every { repository.findOpenIssues() } returns issues

            val result = service.findOpenIssues()

            result shouldBe issues
        }
    }

    @Nested
    inner class CreateIssue {
        @Test
        fun `should create issue with initial state and default heat`() {
            val savedIssueSlot = slot<Issue>()
            every { repository.save(capture(savedIssueSlot)) } answers { savedIssueSlot.captured }

            val command =
                CreateIssueCommand(
                    sectorId = testSectorId,
                    reporterId = testReporterId,
                    type = IssueType.POTHOLE,
                    location = testLocation,
                    address = "123 Test Street",
                    description = "A large pothole",
                )

            val result = service.create(command)

            result.shouldBeInstanceOf<IssueResult.Success>()
            val savedIssue = savedIssueSlot.captured
            savedIssue.state shouldBe IssueState.Reported
            savedIssue.heat shouldBe 10
            savedIssue.reportCount shouldBe 1
            savedIssue.createdAt shouldBe fixedInstant
            savedIssue.updatedAt shouldBe fixedInstant
        }
    }

    @Nested
    inner class UpdateState {
        @Test
        fun `should update state when transition is valid`() {
            val issue = createTestIssue(state = IssueState.Reported)
            val updatedIssueSlot = slot<Issue>()

            every { repository.findByIdForUpdate(testIssueId) } returns issue
            every { repository.save(capture(updatedIssueSlot)) } answers { updatedIssueSlot.captured }

            val result = service.updateState(testIssueId, IssueState.Confirmed)

            result.shouldBeInstanceOf<IssueResult.Success>()
            val updatedIssue = updatedIssueSlot.captured
            updatedIssue.state shouldBe IssueState.Confirmed
            updatedIssue.updatedAt shouldBe fixedInstant
        }

        @Test
        fun `should return NotFound when issue does not exist`() {
            every { repository.findByIdForUpdate(testIssueId) } returns null

            val result = service.updateState(testIssueId, IssueState.Confirmed)

            result.shouldBeInstanceOf<IssueResult.NotFound>()
        }

        @Test
        fun `should return InvalidTransition when transition is not allowed`() {
            val issue = createTestIssue(state = IssueState.Reported)
            every { repository.findByIdForUpdate(testIssueId) } returns issue

            val result = service.updateState(testIssueId, IssueState.Fixed)

            result.shouldBeInstanceOf<IssueResult.InvalidTransition>()
            val invalidTransition = result as IssueResult.InvalidTransition
            invalidTransition.from shouldBe IssueState.Reported
            invalidTransition.to shouldBe IssueState.Fixed
        }

        @Test
        fun `should transition Confirmed to InProgress`() {
            val issue = createTestIssue(state = IssueState.Confirmed)
            val updatedIssueSlot = slot<Issue>()

            every { repository.findByIdForUpdate(testIssueId) } returns issue
            every { repository.save(capture(updatedIssueSlot)) } answers { updatedIssueSlot.captured }

            val result = service.updateState(testIssueId, IssueState.InProgress)

            result.shouldBeInstanceOf<IssueResult.Success>()
            updatedIssueSlot.captured.state shouldBe IssueState.InProgress
        }

        @Test
        fun `should transition InProgress to Fixed`() {
            val issue = createTestIssue(state = IssueState.InProgress)
            val updatedIssueSlot = slot<Issue>()

            every { repository.findByIdForUpdate(testIssueId) } returns issue
            every { repository.save(capture(updatedIssueSlot)) } answers { updatedIssueSlot.captured }

            val result = service.updateState(testIssueId, IssueState.Fixed)

            result.shouldBeInstanceOf<IssueResult.Success>()
            updatedIssueSlot.captured.state shouldBe IssueState.Fixed
        }

        @Test
        fun `should transition Fixed to Reopened`() {
            val issue = createTestIssue(state = IssueState.Fixed)
            val updatedIssueSlot = slot<Issue>()

            every { repository.findByIdForUpdate(testIssueId) } returns issue
            every { repository.save(capture(updatedIssueSlot)) } answers { updatedIssueSlot.captured }

            val result = service.updateState(testIssueId, IssueState.Reopened)

            result.shouldBeInstanceOf<IssueResult.Success>()
            updatedIssueSlot.captured.state shouldBe IssueState.Reopened
        }

        @Test
        fun `should not allow transition from Rejected`() {
            val issue = createTestIssue(state = IssueState.Rejected)
            every { repository.findByIdForUpdate(testIssueId) } returns issue

            val result = service.updateState(testIssueId, IssueState.Confirmed)

            result.shouldBeInstanceOf<IssueResult.InvalidTransition>()
        }
    }

    @Nested
    inner class IncrementReportCount {
        @Test
        fun `should increment report count and recalculate heat`() {
            val issue = createTestIssue(reportCount = 1, heat = 10)
            val updatedIssueSlot = slot<Issue>()

            every { repository.findByIdForUpdate(testIssueId) } returns issue
            every { repository.save(capture(updatedIssueSlot)) } answers { updatedIssueSlot.captured }

            val result = service.incrementReportCount(testIssueId)

            result.shouldBeInstanceOf<IssueResult.Success>()
            val updatedIssue = updatedIssueSlot.captured
            updatedIssue.reportCount shouldBe 2
            // Heat increases based on report count
            updatedIssue.heat shouldBe 15
        }

        @Test
        fun `should return NotFound when issue does not exist`() {
            every { repository.findByIdForUpdate(testIssueId) } returns null

            val result = service.incrementReportCount(testIssueId)

            result.shouldBeInstanceOf<IssueResult.NotFound>()
        }

        @Test
        fun `should cap heat at 100`() {
            val issue = createTestIssue(reportCount = 19, heat = 95)
            val updatedIssueSlot = slot<Issue>()

            every { repository.findByIdForUpdate(testIssueId) } returns issue
            every { repository.save(capture(updatedIssueSlot)) } answers { updatedIssueSlot.captured }

            val result = service.incrementReportCount(testIssueId)

            result.shouldBeInstanceOf<IssueResult.Success>()
            updatedIssueSlot.captured.heat shouldBe 100
        }
    }

    @Nested
    inner class UpdateHeat {
        @Test
        fun `should update heat value`() {
            val issue = createTestIssue(heat = 10)
            val updatedIssueSlot = slot<Issue>()

            every { repository.findByIdForUpdate(testIssueId) } returns issue
            every { repository.save(capture(updatedIssueSlot)) } answers { updatedIssueSlot.captured }

            val result = service.updateHeat(testIssueId, 75)

            result.shouldBeInstanceOf<IssueResult.Success>()
            updatedIssueSlot.captured.heat shouldBe 75
        }

        @Test
        fun `should return NotFound when issue does not exist`() {
            every { repository.findByIdForUpdate(testIssueId) } returns null

            val result = service.updateHeat(testIssueId, 50)

            result.shouldBeInstanceOf<IssueResult.NotFound>()
        }
    }
}
