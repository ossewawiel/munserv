package com.munserv.issues.domain

import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

class IssueStateTest {
    @Test
    fun `should create state from valid string - reported`() {
        val state = IssueState.fromString("reported")
        state shouldBe IssueState.Reported
    }

    @Test
    fun `should create state from valid string - confirmed`() {
        val state = IssueState.fromString("confirmed")
        state shouldBe IssueState.Confirmed
    }

    @Test
    fun `should create state from valid string - in_progress`() {
        val state = IssueState.fromString("in_progress")
        state shouldBe IssueState.InProgress
    }

    @Test
    fun `should create state from valid string - fixed`() {
        val state = IssueState.fromString("fixed")
        state shouldBe IssueState.Fixed
    }

    @Test
    fun `should create state from valid string - rejected`() {
        val state = IssueState.fromString("rejected")
        state shouldBe IssueState.Rejected
    }

    @Test
    fun `should create state from valid string - reopened`() {
        val state = IssueState.fromString("reopened")
        state shouldBe IssueState.Reopened
    }

    @Test
    fun `should be case insensitive`() {
        IssueState.fromString("REPORTED") shouldBe IssueState.Reported
        IssueState.fromString("Confirmed") shouldBe IssueState.Confirmed
        IssueState.fromString("IN_PROGRESS") shouldBe IssueState.InProgress
    }

    @Test
    fun `should throw for unknown state`() {
        shouldThrow<IllegalArgumentException> {
            IssueState.fromString("unknown")
        }
    }

    @Test
    fun `toString should return snake_case value`() {
        IssueState.Reported.toApiString() shouldBe "reported"
        IssueState.Confirmed.toApiString() shouldBe "confirmed"
        IssueState.InProgress.toApiString() shouldBe "in_progress"
        IssueState.Fixed.toApiString() shouldBe "fixed"
        IssueState.Rejected.toApiString() shouldBe "rejected"
        IssueState.Reopened.toApiString() shouldBe "reopened"
    }

    @Nested
    inner class StateTransitions {
        // Reported state transitions
        @Test
        fun `Reported can transition to Confirmed`() {
            IssueState.Reported.canTransitionTo(IssueState.Confirmed) shouldBe true
        }

        @Test
        fun `Reported can transition to Rejected`() {
            IssueState.Reported.canTransitionTo(IssueState.Rejected) shouldBe true
        }

        @Test
        fun `Reported cannot transition to InProgress`() {
            IssueState.Reported.canTransitionTo(IssueState.InProgress) shouldBe false
        }

        @Test
        fun `Reported cannot transition to Fixed`() {
            IssueState.Reported.canTransitionTo(IssueState.Fixed) shouldBe false
        }

        @Test
        fun `Reported cannot transition to Reported`() {
            IssueState.Reported.canTransitionTo(IssueState.Reported) shouldBe false
        }

        // Confirmed state transitions
        @Test
        fun `Confirmed can transition to InProgress`() {
            IssueState.Confirmed.canTransitionTo(IssueState.InProgress) shouldBe true
        }

        @Test
        fun `Confirmed can transition to Rejected`() {
            IssueState.Confirmed.canTransitionTo(IssueState.Rejected) shouldBe true
        }

        @Test
        fun `Confirmed cannot transition to Fixed`() {
            IssueState.Confirmed.canTransitionTo(IssueState.Fixed) shouldBe false
        }

        @Test
        fun `Confirmed cannot transition to Reported`() {
            IssueState.Confirmed.canTransitionTo(IssueState.Reported) shouldBe false
        }

        // InProgress state transitions
        @Test
        fun `InProgress can transition to Fixed`() {
            IssueState.InProgress.canTransitionTo(IssueState.Fixed) shouldBe true
        }

        @Test
        fun `InProgress can transition to Rejected`() {
            IssueState.InProgress.canTransitionTo(IssueState.Rejected) shouldBe true
        }

        @Test
        fun `InProgress cannot transition to Confirmed`() {
            IssueState.InProgress.canTransitionTo(IssueState.Confirmed) shouldBe false
        }

        @Test
        fun `InProgress cannot transition to Reported`() {
            IssueState.InProgress.canTransitionTo(IssueState.Reported) shouldBe false
        }

        // Fixed state transitions
        @Test
        fun `Fixed can transition to Reopened`() {
            IssueState.Fixed.canTransitionTo(IssueState.Reopened) shouldBe true
        }

        @Test
        fun `Fixed cannot transition to any other state`() {
            IssueState.Fixed.canTransitionTo(IssueState.Reported) shouldBe false
            IssueState.Fixed.canTransitionTo(IssueState.Confirmed) shouldBe false
            IssueState.Fixed.canTransitionTo(IssueState.InProgress) shouldBe false
            IssueState.Fixed.canTransitionTo(IssueState.Rejected) shouldBe false
            IssueState.Fixed.canTransitionTo(IssueState.Fixed) shouldBe false
        }

        // Rejected state transitions
        @Test
        fun `Rejected cannot transition to any state`() {
            IssueState.Rejected.canTransitionTo(IssueState.Reported) shouldBe false
            IssueState.Rejected.canTransitionTo(IssueState.Confirmed) shouldBe false
            IssueState.Rejected.canTransitionTo(IssueState.InProgress) shouldBe false
            IssueState.Rejected.canTransitionTo(IssueState.Fixed) shouldBe false
            IssueState.Rejected.canTransitionTo(IssueState.Reopened) shouldBe false
            IssueState.Rejected.canTransitionTo(IssueState.Rejected) shouldBe false
        }

        // Reopened state transitions
        @Test
        fun `Reopened can transition to Confirmed`() {
            IssueState.Reopened.canTransitionTo(IssueState.Confirmed) shouldBe true
        }

        @Test
        fun `Reopened cannot transition to Reported`() {
            IssueState.Reopened.canTransitionTo(IssueState.Reported) shouldBe false
        }

        @Test
        fun `Reopened cannot transition to InProgress`() {
            IssueState.Reopened.canTransitionTo(IssueState.InProgress) shouldBe false
        }
    }

    @Test
    fun `isOpen should return true for open states`() {
        IssueState.Reported.isOpen shouldBe true
        IssueState.Confirmed.isOpen shouldBe true
        IssueState.InProgress.isOpen shouldBe true
        IssueState.Reopened.isOpen shouldBe true
    }

    @Test
    fun `isOpen should return false for closed states`() {
        IssueState.Fixed.isOpen shouldBe false
        IssueState.Rejected.isOpen shouldBe false
    }

    @Test
    fun `isClosed should be inverse of isOpen`() {
        IssueState.entries.forEach { state ->
            state.isClosed shouldBe !state.isOpen
        }
    }
}
