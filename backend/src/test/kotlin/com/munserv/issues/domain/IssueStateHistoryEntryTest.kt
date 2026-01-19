package com.munserv.issues.domain

import com.munserv.shared.types.AdminId
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import java.time.Instant
import java.util.UUID

class IssueStateHistoryEntryTest {
    private val testIssueId = IssueId(UUID.fromString("550e8400-e29b-41d4-a716-446655440100"))
    private val testAdminId = AdminId(UUID.fromString("550e8400-e29b-41d4-a716-446655440020"))
    private val testInstant = Instant.parse("2026-01-15T10:00:00Z")

    @Nested
    inner class Creation {
        @Test
        fun `should create entry with all fields`() {
            val entry =
                IssueStateHistoryEntry(
                    id = IssueStateHistoryId.generate(),
                    issueId = testIssueId,
                    state = IssueState.Confirmed,
                    changedAt = testInstant,
                    changedBy = testAdminId,
                    note = "Confirmed by field inspection",
                )

            entry.issueId shouldBe testIssueId
            entry.state shouldBe IssueState.Confirmed
            entry.changedAt shouldBe testInstant
            entry.changedBy shouldBe testAdminId
            entry.note shouldBe "Confirmed by field inspection"
        }

        @Test
        fun `should create entry with null actor for system-initiated changes`() {
            val entry =
                IssueStateHistoryEntry(
                    id = IssueStateHistoryId.generate(),
                    issueId = testIssueId,
                    state = IssueState.Reported,
                    changedAt = testInstant,
                    changedBy = null,
                    note = null,
                )

            entry.changedBy shouldBe null
            entry.note shouldBe null
        }
    }

    @Nested
    inner class IssueStateHistoryIdGeneration {
        @Test
        fun `should generate unique IDs`() {
            val id1 = IssueStateHistoryId.generate()
            val id2 = IssueStateHistoryId.generate()

            id1 shouldNotBe id2
        }

        @Test
        fun `should wrap UUID value`() {
            val uuid = UUID.randomUUID()
            val id = IssueStateHistoryId(uuid)

            id.value shouldBe uuid
        }
    }
}
