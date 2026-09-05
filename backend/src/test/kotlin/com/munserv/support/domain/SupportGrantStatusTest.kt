package com.munserv.support.domain

import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.Test

class SupportGrantStatusTest {
    @Test
    fun `should allow transition from active to expired`() {
        SupportGrantStatus.ACTIVE.canTransitionTo(SupportGrantStatus.EXPIRED) shouldBe true
    }

    @Test
    fun `should allow transition from active to revoked`() {
        SupportGrantStatus.ACTIVE.canTransitionTo(SupportGrantStatus.REVOKED) shouldBe true
    }

    @Test
    fun `should reject transition when status is terminal`() {
        SupportGrantStatus.EXPIRED.canTransitionTo(SupportGrantStatus.ACTIVE) shouldBe false
        SupportGrantStatus.EXPIRED.canTransitionTo(SupportGrantStatus.REVOKED) shouldBe false
        SupportGrantStatus.REVOKED.canTransitionTo(SupportGrantStatus.ACTIVE) shouldBe false
        SupportGrantStatus.REVOKED.canTransitionTo(SupportGrantStatus.EXPIRED) shouldBe false
    }

    @Test
    fun `should round trip db value`() {
        SupportGrantStatus.fromDbValue(SupportGrantStatus.ACTIVE.toDbValue()) shouldBe SupportGrantStatus.ACTIVE
        SupportGrantStatus.fromDbValue(SupportGrantStatus.EXPIRED.toDbValue()) shouldBe SupportGrantStatus.EXPIRED
        SupportGrantStatus.fromDbValue(SupportGrantStatus.REVOKED.toDbValue()) shouldBe SupportGrantStatus.REVOKED
    }
}
