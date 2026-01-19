package com.munserv.auth.domain

import com.munserv.shared.enums.GroundAdminStatus
import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import java.math.BigDecimal
import java.time.Instant

/**
 * Tests for Ground Admin functionality on the Member domain entity.
 * These tests verify the GA lifecycle methods added to Member.
 */
class MemberGroundAdminTest {
    private val sectorId = SectorId.generate()
    private val memberId = MemberId.generate()
    private val location = GeoPoint(27.9833, -26.1367)
    private val now = Instant.parse("2026-01-05T10:00:00Z")

    private fun createMember(
        id: MemberId = memberId,
        status: MemberStatus = MemberStatus.Active,
        isGroundAdmin: Boolean = false,
        groundAdminStatus: GroundAdminStatus? = null,
        groundAdminSince: Instant? = null,
        groundAdminResponseRate: BigDecimal? = null,
    ): Member =
        Member(
            id = id,
            sectorId = sectorId,
            email = "john.doe@example.com",
            emailHash = "836f82db99121b3481011f16b49dfa5fbc714a0d1b1b9f784a1ebbbf5b39577f",
            passwordHash = "\$2a\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.Q8JKQz8vZ8B7Hy",
            mustChangePassword = false,
            phoneHash = null,
            pinHash = null,
            phone = "+27821234567",
            firstName = "John",
            surname = "Doe",
            address = "123 Main Street, Northcliff",
            registrationLocation = location,
            status = status,
            createdAt = now,
            updatedAt = now,
            isGroundAdmin = isGroundAdmin,
            groundAdminStatus = groundAdminStatus,
            groundAdminSince = groundAdminSince,
            groundAdminResponseRate = groundAdminResponseRate,
        )

    @Nested
    inner class GroundAdminFields {
        @Test
        fun `should create member with default non-ground-admin values`() {
            val member = createMember()

            member.isGroundAdmin shouldBe false
            member.groundAdminStatus shouldBe null
            member.groundAdminSince shouldBe null
            member.groundAdminResponseRate shouldBe null
        }

        @Test
        fun `should create member with ground admin fields set`() {
            val since = Instant.parse("2025-06-01T00:00:00Z")
            val responseRate = BigDecimal("95.50")

            val member =
                createMember(
                    isGroundAdmin = true,
                    groundAdminStatus = GroundAdminStatus.ACTIVE,
                    groundAdminSince = since,
                    groundAdminResponseRate = responseRate,
                )

            member.isGroundAdmin shouldBe true
            member.groundAdminStatus shouldBe GroundAdminStatus.ACTIVE
            member.groundAdminSince shouldBe since
            member.groundAdminResponseRate shouldBe responseRate
        }
    }

    @Nested
    inner class PromoteToGroundAdmin {
        @Test
        fun `promoteToGroundAdmin should set all GA fields correctly`() {
            val member = createMember()

            val promoted = member.promoteToGroundAdmin()

            promoted.isGroundAdmin shouldBe true
            promoted.groundAdminStatus shouldBe GroundAdminStatus.ACTIVE
            promoted.groundAdminSince shouldNotBe null
            promoted.groundAdminResponseRate shouldBe BigDecimal("100.00")
            promoted.updatedAt shouldNotBe member.updatedAt
        }

        @Test
        fun `promoteToGroundAdmin should preserve original member data`() {
            val member = createMember()

            val promoted = member.promoteToGroundAdmin()

            promoted.id shouldBe member.id
            promoted.sectorId shouldBe member.sectorId
            promoted.email shouldBe member.email
            promoted.firstName shouldBe member.firstName
        }

        @Test
        fun `promoteToGroundAdmin should not mutate original`() {
            val original = createMember()
            original.promoteToGroundAdmin()

            original.isGroundAdmin shouldBe false
            original.groundAdminStatus shouldBe null
        }
    }

    @Nested
    inner class DemoteFromGroundAdmin {
        @Test
        fun `demoteFromGroundAdmin should set isGroundAdmin to false`() {
            val member =
                createMember(
                    isGroundAdmin = true,
                    groundAdminStatus = GroundAdminStatus.ACTIVE,
                    groundAdminSince = Instant.now(),
                    groundAdminResponseRate = BigDecimal("90.00"),
                )

            val demoted = member.demoteFromGroundAdmin()

            demoted.isGroundAdmin shouldBe false
            demoted.groundAdminStatus shouldBe GroundAdminStatus.INACTIVE
            demoted.updatedAt shouldNotBe member.updatedAt
        }

        @Test
        fun `demoteFromGroundAdmin should preserve groundAdminSince for history`() {
            val since = Instant.parse("2025-01-01T00:00:00Z")
            val member =
                createMember(
                    isGroundAdmin = true,
                    groundAdminStatus = GroundAdminStatus.ACTIVE,
                    groundAdminSince = since,
                )

            val demoted = member.demoteFromGroundAdmin()

            // Keep historical record of when they became GA
            demoted.groundAdminSince shouldBe since
        }
    }

    @Nested
    inner class GroundAdminStatusChanges {
        @Test
        fun `setGroundAdminOnHold should change status to ON_HOLD`() {
            val member =
                createMember(
                    isGroundAdmin = true,
                    groundAdminStatus = GroundAdminStatus.ACTIVE,
                )

            val onHold = member.setGroundAdminOnHold()

            onHold.isGroundAdmin shouldBe true
            onHold.groundAdminStatus shouldBe GroundAdminStatus.ON_HOLD
        }

        @Test
        fun `reactivateGroundAdmin should change status to ACTIVE`() {
            val member =
                createMember(
                    isGroundAdmin = true,
                    groundAdminStatus = GroundAdminStatus.ON_HOLD,
                )

            val reactivated = member.reactivateGroundAdmin()

            reactivated.isGroundAdmin shouldBe true
            reactivated.groundAdminStatus shouldBe GroundAdminStatus.ACTIVE
        }
    }

    @Nested
    inner class UpdateResponseRate {
        @Test
        fun `updateResponseRate should change the rate`() {
            val member =
                createMember(
                    isGroundAdmin = true,
                    groundAdminStatus = GroundAdminStatus.ACTIVE,
                    groundAdminResponseRate = BigDecimal("100.00"),
                )

            val updated = member.updateResponseRate(BigDecimal("85.50"))

            updated.groundAdminResponseRate shouldBe BigDecimal("85.50")
            updated.updatedAt shouldNotBe member.updatedAt
        }
    }

    @Nested
    inner class Immutability {
        @Test
        fun `all GA methods should return new instance without mutating original`() {
            val original = createMember()

            val promoted = original.promoteToGroundAdmin()
            val onHold = promoted.setGroundAdminOnHold()
            val reactivated = onHold.reactivateGroundAdmin()
            val demoted = reactivated.demoteFromGroundAdmin()

            // Original should be unchanged
            original.isGroundAdmin shouldBe false
            original.groundAdminStatus shouldBe null

            // Each step should have correct values
            promoted.groundAdminStatus shouldBe GroundAdminStatus.ACTIVE
            onHold.groundAdminStatus shouldBe GroundAdminStatus.ON_HOLD
            reactivated.groundAdminStatus shouldBe GroundAdminStatus.ACTIVE
            demoted.groundAdminStatus shouldBe GroundAdminStatus.INACTIVE
        }
    }
}
