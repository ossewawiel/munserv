package com.munserv.issues.domain

import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import java.time.Instant
import java.util.UUID

class IssueTest {
    private val testId = IssueId(UUID.fromString("550e8400-e29b-41d4-a716-446655440001"))
    private val testSectorId = SectorId(UUID.fromString("550e8400-e29b-41d4-a716-446655440002"))
    private val testReporterId = MemberId(UUID.fromString("550e8400-e29b-41d4-a716-446655440003"))
    private val testLocation = GeoPoint(-26.1350, 27.9800)
    private val testCreatedAt = Instant.parse("2025-01-01T10:00:00Z")

    private fun createTestIssue(
        state: IssueState = IssueState.Reported,
        heat: Int = 10,
        reportCount: Int = 1,
    ) = Issue(
        id = testId,
        sectorId = testSectorId,
        reporterId = testReporterId,
        type = IssueType.POTHOLE,
        state = state,
        location = testLocation,
        address = "123 Test Street",
        description = "A large pothole",
        heat = heat,
        reportCount = reportCount,
        createdAt = testCreatedAt,
        updatedAt = testCreatedAt,
    )

    @Test
    fun `should create issue with all properties`() {
        val issue = createTestIssue()

        issue.id shouldBe testId
        issue.sectorId shouldBe testSectorId
        issue.reporterId shouldBe testReporterId
        issue.type shouldBe IssueType.POTHOLE
        issue.state shouldBe IssueState.Reported
        issue.location shouldBe testLocation
        issue.address shouldBe "123 Test Street"
        issue.description shouldBe "A large pothole"
        issue.heat shouldBe 10
        issue.reportCount shouldBe 1
        issue.createdAt shouldBe testCreatedAt
        issue.updatedAt shouldBe testCreatedAt
    }

    @Test
    fun `should create issue with null optional fields`() {
        val issue =
            Issue(
                id = testId,
                sectorId = testSectorId,
                reporterId = testReporterId,
                type = IssueType.OTHER,
                state = IssueState.Reported,
                location = testLocation,
                address = null,
                description = null,
                heat = 5,
                reportCount = 1,
                createdAt = testCreatedAt,
                updatedAt = testCreatedAt,
            )

        issue.address shouldBe null
        issue.description shouldBe null
    }

    @Nested
    inner class StateTransitions {
        @Test
        fun `canTransitionTo should delegate to state for valid transition`() {
            val issue = createTestIssue(state = IssueState.Reported)
            issue.canTransitionTo(IssueState.Confirmed) shouldBe true
        }

        @Test
        fun `canTransitionTo should delegate to state for invalid transition`() {
            val issue = createTestIssue(state = IssueState.Reported)
            issue.canTransitionTo(IssueState.Fixed) shouldBe false
        }

        @Test
        fun `canTransitionTo from Confirmed to InProgress should be true`() {
            val issue = createTestIssue(state = IssueState.Confirmed)
            issue.canTransitionTo(IssueState.InProgress) shouldBe true
        }

        @Test
        fun `canTransitionTo from InProgress to Fixed should be true`() {
            val issue = createTestIssue(state = IssueState.InProgress)
            issue.canTransitionTo(IssueState.Fixed) shouldBe true
        }

        @Test
        fun `canTransitionTo from Fixed to Reopened should be true`() {
            val issue = createTestIssue(state = IssueState.Fixed)
            issue.canTransitionTo(IssueState.Reopened) shouldBe true
        }

        @Test
        fun `canTransitionTo from Rejected should be false for any state`() {
            val issue = createTestIssue(state = IssueState.Rejected)
            issue.canTransitionTo(IssueState.Reported) shouldBe false
            issue.canTransitionTo(IssueState.Confirmed) shouldBe false
            issue.canTransitionTo(IssueState.InProgress) shouldBe false
            issue.canTransitionTo(IssueState.Fixed) shouldBe false
        }
    }

    @Nested
    inner class ImmutableUpdates {
        @Test
        fun `withState should return new instance with updated state`() {
            val original = createTestIssue(state = IssueState.Reported)
            val updated = original.withState(IssueState.Confirmed)

            updated.state shouldBe IssueState.Confirmed
            original.state shouldBe IssueState.Reported
            updated shouldNotBe original
        }

        @Test
        fun `withState should preserve all other properties`() {
            val original = createTestIssue()
            val updated = original.withState(IssueState.Confirmed)

            updated.id shouldBe original.id
            updated.sectorId shouldBe original.sectorId
            updated.reporterId shouldBe original.reporterId
            updated.type shouldBe original.type
            updated.location shouldBe original.location
            updated.address shouldBe original.address
            updated.description shouldBe original.description
            updated.heat shouldBe original.heat
            updated.reportCount shouldBe original.reportCount
            updated.createdAt shouldBe original.createdAt
        }

        @Test
        fun `withHeat should return new instance with updated heat`() {
            val original = createTestIssue(heat = 10)
            val updated = original.withHeat(50)

            updated.heat shouldBe 50
            original.heat shouldBe 10
            updated shouldNotBe original
        }

        @Test
        fun `withReportCount should return new instance with updated count`() {
            val original = createTestIssue(reportCount = 1)
            val updated = original.withReportCount(5)

            updated.reportCount shouldBe 5
            original.reportCount shouldBe 1
            updated shouldNotBe original
        }

        @Test
        fun `withUpdatedAt should return new instance with new timestamp`() {
            val original = createTestIssue()
            val newTimestamp = Instant.parse("2025-01-02T15:30:00Z")
            val updated = original.withUpdatedAt(newTimestamp)

            updated.updatedAt shouldBe newTimestamp
            original.updatedAt shouldBe testCreatedAt
            updated shouldNotBe original
        }
    }

    @Nested
    inner class StatusProperties {
        @Test
        fun `isOpen should be true for Reported state`() {
            val issue = createTestIssue(state = IssueState.Reported)
            issue.isOpen shouldBe true
            issue.isClosed shouldBe false
        }

        @Test
        fun `isOpen should be true for Confirmed state`() {
            val issue = createTestIssue(state = IssueState.Confirmed)
            issue.isOpen shouldBe true
            issue.isClosed shouldBe false
        }

        @Test
        fun `isOpen should be true for InProgress state`() {
            val issue = createTestIssue(state = IssueState.InProgress)
            issue.isOpen shouldBe true
            issue.isClosed shouldBe false
        }

        @Test
        fun `isOpen should be true for Reopened state`() {
            val issue = createTestIssue(state = IssueState.Reopened)
            issue.isOpen shouldBe true
            issue.isClosed shouldBe false
        }

        @Test
        fun `isClosed should be true for Fixed state`() {
            val issue = createTestIssue(state = IssueState.Fixed)
            issue.isOpen shouldBe false
            issue.isClosed shouldBe true
        }

        @Test
        fun `isClosed should be true for Rejected state`() {
            val issue = createTestIssue(state = IssueState.Rejected)
            issue.isOpen shouldBe false
            issue.isClosed shouldBe true
        }
    }

    @Nested
    inner class Equality {
        @Test
        fun `issues with same id should be equal`() {
            val issue1 = createTestIssue()
            val issue2 = createTestIssue()

            issue1 shouldBe issue2
        }

        @Test
        fun `issues with different ids should not be equal`() {
            val issue1 = createTestIssue()
            val issue2 =
                Issue(
                    id = IssueId(UUID.randomUUID()),
                    sectorId = testSectorId,
                    reporterId = testReporterId,
                    type = IssueType.POTHOLE,
                    state = IssueState.Reported,
                    location = testLocation,
                    address = "123 Test Street",
                    description = "A large pothole",
                    heat = 10,
                    reportCount = 1,
                    createdAt = testCreatedAt,
                    updatedAt = testCreatedAt,
                )

            issue1 shouldNotBe issue2
        }
    }
}
