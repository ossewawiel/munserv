package com.munserv.auth.domain

import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import org.junit.jupiter.api.Test
import java.time.Instant

class MemberTest {
    private val sectorId = SectorId.generate()
    private val memberId = MemberId.generate()
    private val phoneHash = "a1b2c3d4e5f6789012345678901234567890123456789012345678901234abcd"
    private val pinHash = "03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4"
    private val location = GeoPoint(27.9833, -26.1367)
    private val now = Instant.parse("2026-01-05T10:00:00Z")

    private fun createMember(
        id: MemberId = memberId,
        status: MemberStatus = MemberStatus.Active,
    ): Member =
        Member(
            id = id,
            sectorId = sectorId,
            phoneHash = phoneHash,
            pinHash = pinHash,
            firstName = "John",
            surname = "Doe",
            address = "123 Main Street, Northcliff",
            registrationLocation = location,
            status = status,
            createdAt = now,
            updatedAt = now,
        )

    @Test
    fun `should create Member with all fields`() {
        val member = createMember()

        member.id shouldBe memberId
        member.sectorId shouldBe sectorId
        member.phoneHash shouldBe phoneHash
        member.pinHash shouldBe pinHash
        member.firstName shouldBe "John"
        member.surname shouldBe "Doe"
        member.address shouldBe "123 Main Street, Northcliff"
        member.registrationLocation shouldBe location
        member.status shouldBe MemberStatus.Active
    }

    @Test
    fun `should have fullName property`() {
        val member = createMember()

        member.fullName shouldBe "John Doe"
    }

    @Test
    fun `should transition status from Active to Suspended`() {
        val member = createMember(status = MemberStatus.Active)

        val updated = member.withStatus(MemberStatus.Suspended)

        updated.status shouldBe MemberStatus.Suspended
        updated.id shouldBe member.id
    }

    @Test
    fun `should transition status from Suspended to Active`() {
        val member = createMember(status = MemberStatus.Suspended)

        val updated = member.withStatus(MemberStatus.Active)

        updated.status shouldBe MemberStatus.Active
    }

    @Test
    fun `canTransitionTo should delegate to MemberStatus`() {
        val activeMember = createMember(status = MemberStatus.Active)
        val suspendedMember = createMember(status = MemberStatus.Suspended)
        val deletedMember = createMember(status = MemberStatus.Deleted)

        activeMember.canTransitionTo(MemberStatus.Suspended) shouldBe true
        activeMember.canTransitionTo(MemberStatus.Deleted) shouldBe true
        suspendedMember.canTransitionTo(MemberStatus.Active) shouldBe true
        deletedMember.canTransitionTo(MemberStatus.Active) shouldBe false
    }

    @Test
    fun `isActive should return true only for Active status`() {
        createMember(status = MemberStatus.Active).isActive shouldBe true
        createMember(status = MemberStatus.Suspended).isActive shouldBe false
        createMember(status = MemberStatus.Deleted).isActive shouldBe false
    }

    @Test
    fun `should update PIN hash`() {
        val member = createMember()
        val newPinHash = "new_pin_hash_value_here_64_chars_0000000000000000000000000000"

        val updated = member.withPinHash(newPinHash)

        updated.pinHash shouldBe newPinHash
        updated.id shouldBe member.id
    }

    @Test
    fun `should have correct equality`() {
        val member1 = createMember()
        val member2 = createMember()
        val member3 = createMember(id = MemberId.generate())

        member1 shouldBe member2
        member1 shouldNotBe member3
    }

    @Test
    fun `copy should preserve immutability`() {
        val member = createMember()
        val updated = member.withStatus(MemberStatus.Suspended)

        member.status shouldBe MemberStatus.Active
        updated.status shouldBe MemberStatus.Suspended
    }
}
