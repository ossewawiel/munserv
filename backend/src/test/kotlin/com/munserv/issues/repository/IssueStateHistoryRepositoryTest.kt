package com.munserv.issues.repository

import com.munserv.issues.domain.IssueId
import com.munserv.issues.domain.IssueState
import com.munserv.issues.domain.IssueStateHistoryEntry
import com.munserv.issues.domain.IssueStateHistoryId
import com.munserv.shared.types.AdminId
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest
import org.springframework.context.annotation.Import
import org.springframework.test.context.ActiveProfiles
import java.time.Instant
import java.util.UUID

@DataJpaTest
@ActiveProfiles("test")
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Import(JpaIssueStateHistoryRepository::class)
class IssueStateHistoryRepositoryTest {
    @Autowired
    private lateinit var repository: IssueStateHistoryRepository

    private val testIssueId = IssueId(UUID.fromString("550e8400-e29b-41d4-a716-446655440100"))
    private val testAdminId = AdminId(UUID.fromString("550e8400-e29b-41d4-a716-446655440020"))

    @Nested
    inner class Save {
        @Test
        fun `should save history entry`() {
            val entry =
                IssueStateHistoryEntry(
                    id = IssueStateHistoryId.generate(),
                    issueId = testIssueId,
                    state = IssueState.Confirmed,
                    changedAt = Instant.now(),
                    changedBy = testAdminId,
                    note = "Test note",
                )

            val saved = repository.save(entry)

            saved.id shouldBe entry.id
            saved.issueId shouldBe entry.issueId
            saved.state shouldBe entry.state
            saved.changedBy shouldBe entry.changedBy
            saved.note shouldBe entry.note
        }

        @Test
        fun `should save entry with null actor`() {
            val entry =
                IssueStateHistoryEntry(
                    id = IssueStateHistoryId.generate(),
                    issueId = testIssueId,
                    state = IssueState.Reported,
                    changedAt = Instant.now(),
                    changedBy = null,
                    note = null,
                )

            val saved = repository.save(entry)

            saved.changedBy shouldBe null
            saved.note shouldBe null
        }
    }

    @Nested
    inner class FindByIssueId {
        @Test
        fun `should return history entries ordered by changedAt ascending`() {
            // The seed data includes history for issue 550e8400-e29b-41d4-a716-446655440100
            val history = repository.findByIssueId(testIssueId)

            history.shouldHaveSize(1) // Seed data has one entry for this issue
            history[0].issueId shouldBe testIssueId
            history[0].state shouldBe IssueState.Reported
        }

        @Test
        fun `should return empty list for issue with no history`() {
            val nonExistentIssueId = IssueId(UUID.randomUUID())

            val history = repository.findByIssueId(nonExistentIssueId)

            history.shouldBeEmpty()
        }

        @Test
        fun `should return multiple entries in chronological order`() {
            // Issue 550e8400-e29b-41d4-a716-446655440102 has 3 history entries in seed data
            val issueWithMultipleHistory = IssueId(UUID.fromString("550e8400-e29b-41d4-a716-446655440102"))

            val history = repository.findByIssueId(issueWithMultipleHistory)

            history.shouldHaveSize(3)
            history[0].state shouldBe IssueState.Reported
            history[1].state shouldBe IssueState.Confirmed
            history[2].state shouldBe IssueState.InProgress
            // Verify chronological order
            history.zipWithNext().forEach { (earlier, later) ->
                (earlier.changedAt <= later.changedAt) shouldBe true
            }
        }
    }
}
