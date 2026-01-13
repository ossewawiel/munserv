package com.munserv.issues.domain

import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import org.junit.jupiter.api.Test
import java.util.UUID

class IssueIdTest {
    @Test
    fun `should create IssueId with valid UUID`() {
        val uuid = UUID.randomUUID()
        val issueId = IssueId(uuid)

        issueId.value shouldBe uuid
    }

    @Test
    fun `should create IssueId from string`() {
        val uuidString = "550e8400-e29b-41d4-a716-446655440100"
        val issueId = IssueId.fromString(uuidString)

        issueId.value.toString() shouldBe uuidString
    }

    @Test
    fun `should throw exception for invalid UUID string`() {
        shouldThrow<IllegalArgumentException> {
            IssueId.fromString("not-a-uuid")
        }
    }

    @Test
    fun `should have correct equality`() {
        val uuid = UUID.randomUUID()
        val issueId1 = IssueId(uuid)
        val issueId2 = IssueId(uuid)
        val issueId3 = IssueId(UUID.randomUUID())

        issueId1 shouldBe issueId2
        issueId1 shouldNotBe issueId3
    }

    @Test
    fun `should have meaningful toString`() {
        val uuidString = "550e8400-e29b-41d4-a716-446655440100"
        val issueId = IssueId.fromString(uuidString)

        issueId.toString() shouldBe uuidString
    }

    @Test
    fun `should generate new IssueId`() {
        val issueId = IssueId.generate()

        issueId.value shouldNotBe null
    }
}
