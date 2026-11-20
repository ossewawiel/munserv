package com.munserv.admin.domain

import com.munserv.issues.domain.IssueId
import com.munserv.issues.domain.IssueState
import com.munserv.issues.domain.IssueStateHistoryEntry
import com.munserv.issues.domain.IssueStateHistoryId
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.Test
import java.time.Instant
import java.time.temporal.ChronoUnit

class ResolutionTimeTest {
    private val now = Instant.parse("2025-01-15T10:00:00Z")
    private val windowStart = now.minus(90, ChronoUnit.DAYS)

    private fun entry(
        issueId: IssueId,
        state: IssueState,
        changedAt: Instant,
    ) = IssueStateHistoryEntry(
        id = IssueStateHistoryId.generate(),
        issueId = issueId,
        state = state,
        changedAt = changedAt,
        changedBy = null,
        note = null,
    )

    @Test
    fun `should return null when no issue was fixed`() {
        val id = IssueId.generate()
        val histories = mapOf(id to listOf(entry(id, IssueState.Reported, now.minus(5, ChronoUnit.DAYS))))

        ResolutionTime.averageDays(histories, windowStart) shouldBe null
    }

    @Test
    fun `should return null when every fix is older than the window`() {
        val id = IssueId.generate()
        val reported = windowStart.minus(10, ChronoUnit.DAYS)
        val histories =
            mapOf(
                id to
                    listOf(
                        entry(id, IssueState.Reported, reported),
                        entry(id, IssueState.Fixed, windowStart.minus(1, ChronoUnit.DAYS)),
                    ),
            )

        ResolutionTime.averageDays(histories, windowStart) shouldBe null
    }

    @Test
    fun `should average days from reported to fixed`() {
        val a = IssueId.generate()
        val b = IssueId.generate()
        val base = now.minus(30, ChronoUnit.DAYS)
        val histories =
            mapOf(
                a to
                    listOf(
                        entry(a, IssueState.Reported, base),
                        entry(a, IssueState.Fixed, base.plus(2, ChronoUnit.DAYS)),
                    ),
                b to
                    listOf(
                        entry(b, IssueState.Reported, base),
                        entry(b, IssueState.Fixed, base.plus(4, ChronoUnit.DAYS)),
                    ),
            )

        ResolutionTime.averageDays(histories, windowStart) shouldBe 3.0
    }

    @Test
    fun `should use the latest fix inside the window when an issue was fixed twice`() {
        val id = IssueId.generate()
        val base = now.minus(30, ChronoUnit.DAYS)
        val histories =
            mapOf(
                id to
                    listOf(
                        entry(id, IssueState.Reported, base),
                        entry(id, IssueState.Fixed, base.plus(1, ChronoUnit.DAYS)),
                        entry(id, IssueState.Reopened, base.plus(2, ChronoUnit.DAYS)),
                        entry(id, IssueState.Fixed, base.plus(5, ChronoUnit.DAYS)),
                    ),
            )

        ResolutionTime.averageDays(histories, windowStart) shouldBe 5.0
    }

    @Test
    fun `should round half up to one decimal place`() {
        val id = IssueId.generate()
        val base = now.minus(30, ChronoUnit.DAYS)
        val histories =
            mapOf(
                id to
                    listOf(
                        entry(id, IssueState.Reported, base),
                        entry(id, IssueState.Fixed, base.plus(30, ChronoUnit.HOURS)),
                    ),
            )

        ResolutionTime.averageDays(histories, windowStart) shouldBe 1.3
    }

    @Test
    fun `should skip an issue that has no reported entry`() {
        val withoutReported = IssueId.generate()
        val complete = IssueId.generate()
        val base = now.minus(30, ChronoUnit.DAYS)
        val histories =
            mapOf(
                withoutReported to listOf(entry(withoutReported, IssueState.Fixed, base.plus(9, ChronoUnit.DAYS))),
                complete to
                    listOf(
                        entry(complete, IssueState.Reported, base),
                        entry(complete, IssueState.Fixed, base.plus(2, ChronoUnit.DAYS)),
                    ),
            )

        ResolutionTime.averageDays(histories, windowStart) shouldBe 2.0
    }
}
