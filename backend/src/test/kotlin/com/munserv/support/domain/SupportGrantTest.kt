package com.munserv.support.domain

import com.munserv.admin.domain.AdminRole
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.PodId
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.Test
import java.time.Duration
import java.time.Instant
import java.util.UUID

class SupportGrantTest {
    private val testPodId = PodId(UUID.fromString("550e8400-e29b-41d4-a716-446655440000"))
    private val testAdminId = AdminId(UUID.fromString("550e8400-e29b-41d4-a716-446655440031"))
    private val grantedAt = Instant.parse("2026-09-05T10:00:00Z")

    private fun testGrant(): SupportGrant =
        SupportGrant.create(
            id = SupportGrantId.generate(),
            podId = testPodId,
            grantedRole = AdminRole.POD_ADMIN,
            purpose = "Investigate duplicate issue reports",
            grantedBy = testAdminId,
            grantedAt = grantedAt,
        )

    @Test
    fun `should set expiry one hour after grant when created`() {
        val grant = testGrant()

        grant.expiresAt shouldBe grantedAt.plus(Duration.ofHours(1))
        grant.status shouldBe SupportGrantStatus.ACTIVE
        grant.lastActivity shouldBe null
    }

    @Test
    fun `should slide expiry one hour forward when activity is recorded`() {
        val grant = testGrant()
        val activityAt = grantedAt.plus(Duration.ofMinutes(30))

        val updated = grant.withActivity(activityAt)

        updated.lastActivity shouldBe activityAt
        updated.expiresAt shouldBe activityAt.plus(Duration.ofHours(1))
    }

    @Test
    fun `should be active at a time before expiry`() {
        val grant = testGrant()

        grant.isActiveAt(grantedAt.plus(Duration.ofMinutes(59))) shouldBe true
    }

    @Test
    fun `should not be active at a time after expiry`() {
        val grant = testGrant()

        grant.isActiveAt(grantedAt.plus(Duration.ofHours(2))) shouldBe false
    }

    @Test
    fun `should transition to revoked with the revoking admin`() {
        val grant = testGrant()
        val revokedAt = grantedAt.plus(Duration.ofMinutes(10))

        val revoked = grant.revoked(revokedAt, testAdminId)

        revoked.status shouldBe SupportGrantStatus.REVOKED
        revoked.revokedAt shouldBe revokedAt
        revoked.revokedBy shouldBe testAdminId
    }

    @Test
    fun `should transition to revoked with null actor on logout`() {
        val grant = testGrant()
        val revokedAt = grantedAt.plus(Duration.ofMinutes(10))

        val revoked = grant.revoked(revokedAt, null)

        revoked.revokedBy shouldBe null
    }

    @Test
    fun `should transition to expired`() {
        val grant = testGrant()
        val expiredAt = grantedAt.plus(Duration.ofHours(1))

        val expired = grant.expired(expiredAt)

        expired.status shouldBe SupportGrantStatus.EXPIRED
        expired.expiredAt shouldBe expiredAt
    }
}
