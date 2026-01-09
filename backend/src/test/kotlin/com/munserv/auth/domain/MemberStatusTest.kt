package com.munserv.auth.domain

import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.Test

class MemberStatusTest {
    @Test
    fun `should create status from valid string - active`() {
        val status = MemberStatus.fromString("active")

        status shouldBe MemberStatus.Active
    }

    @Test
    fun `should create status from valid string - suspended`() {
        val status = MemberStatus.fromString("suspended")

        status shouldBe MemberStatus.Suspended
    }

    @Test
    fun `should create status from valid string - deleted`() {
        val status = MemberStatus.fromString("deleted")

        status shouldBe MemberStatus.Deleted
    }

    @Test
    fun `should be case insensitive`() {
        MemberStatus.fromString("ACTIVE") shouldBe MemberStatus.Active
        MemberStatus.fromString("Active") shouldBe MemberStatus.Active
        MemberStatus.fromString("SUSPENDED") shouldBe MemberStatus.Suspended
    }

    @Test
    fun `should create status from valid string - pending_approval`() {
        val status = MemberStatus.fromString("pending_approval")

        status shouldBe MemberStatus.PendingApproval
    }

    @Test
    fun `should throw for unknown status`() {
        shouldThrow<IllegalArgumentException> {
            MemberStatus.fromString("unknown")
        }
    }

    @Test
    fun `Active status should allow transition to Suspended`() {
        MemberStatus.Active.canTransitionTo(MemberStatus.Suspended) shouldBe true
    }

    @Test
    fun `Active status should allow transition to Deleted`() {
        MemberStatus.Active.canTransitionTo(MemberStatus.Deleted) shouldBe true
    }

    @Test
    fun `Active status should not allow transition to Active`() {
        MemberStatus.Active.canTransitionTo(MemberStatus.Active) shouldBe false
    }

    @Test
    fun `Suspended status should allow transition to Active`() {
        MemberStatus.Suspended.canTransitionTo(MemberStatus.Active) shouldBe true
    }

    @Test
    fun `Suspended status should allow transition to Deleted`() {
        MemberStatus.Suspended.canTransitionTo(MemberStatus.Deleted) shouldBe true
    }

    @Test
    fun `Deleted status should not allow any transitions`() {
        MemberStatus.Deleted.canTransitionTo(MemberStatus.Active) shouldBe false
        MemberStatus.Deleted.canTransitionTo(MemberStatus.Suspended) shouldBe false
        MemberStatus.Deleted.canTransitionTo(MemberStatus.Deleted) shouldBe false
    }

    @Test
    fun `toString should return lowercase value`() {
        MemberStatus.Active.toString() shouldBe "active"
        MemberStatus.Suspended.toString() shouldBe "suspended"
        MemberStatus.Deleted.toString() shouldBe "deleted"
        MemberStatus.PendingApproval.toString() shouldBe "pending_approval"
    }

    // PendingApproval transition tests
    @Test
    fun `PendingApproval status should allow transition to Active`() {
        MemberStatus.PendingApproval.canTransitionTo(MemberStatus.Active) shouldBe true
    }

    @Test
    fun `PendingApproval status should allow transition to Deleted`() {
        MemberStatus.PendingApproval.canTransitionTo(MemberStatus.Deleted) shouldBe true
    }

    @Test
    fun `PendingApproval status should not allow transition to Suspended`() {
        MemberStatus.PendingApproval.canTransitionTo(MemberStatus.Suspended) shouldBe false
    }

    @Test
    fun `PendingApproval status should not allow transition to PendingApproval`() {
        MemberStatus.PendingApproval.canTransitionTo(MemberStatus.PendingApproval) shouldBe false
    }

    @Test
    fun `should parse PENDING_APPROVAL case insensitively`() {
        MemberStatus.fromString("PENDING_APPROVAL") shouldBe MemberStatus.PendingApproval
        MemberStatus.fromString("Pending_Approval") shouldBe MemberStatus.PendingApproval
    }
}
