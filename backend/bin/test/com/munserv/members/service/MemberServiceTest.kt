package com.munserv.members.service

import com.munserv.auth.domain.Member
import com.munserv.auth.domain.MemberStatus
import com.munserv.auth.repository.MemberRepository
import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.clearAllMocks
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import java.time.Instant

class MemberServiceTest {
    private lateinit var memberService: MemberService
    private lateinit var memberRepository: MemberRepository

    private val testMemberId = MemberId.generate()
    private val testSectorId = SectorId.generate()
    private val testMember = createTestMember(testMemberId)

    @BeforeEach
    fun setup() {
        clearAllMocks()
        memberRepository = mockk()
        memberService = MemberService(memberRepository)
    }

    @Test
    fun `findById should return Success when member exists`() {
        // Arrange
        every { memberRepository.findById(testMemberId) } returns testMember

        // Act
        val result = memberService.findById(testMemberId)

        // Assert
        result.shouldBeInstanceOf<MemberResult.Success>()
        val success = result as MemberResult.Success
        success.member.id shouldBe testMemberId
        success.member.firstName shouldBe testMember.firstName
        success.member.surname shouldBe testMember.surname
        verify { memberRepository.findById(testMemberId) }
    }

    @Test
    fun `findById should return NotFound when member does not exist`() {
        // Arrange
        val unknownId = MemberId.generate()
        every { memberRepository.findById(unknownId) } returns null

        // Act
        val result = memberService.findById(unknownId)

        // Assert
        result.shouldBeInstanceOf<MemberResult.NotFound>()
        val notFound = result as MemberResult.NotFound
        notFound.id shouldBe unknownId
        verify { memberRepository.findById(unknownId) }
    }

    @Test
    fun `findById should return correct member data`() {
        // Arrange
        val member =
            createTestMember(
                id = testMemberId,
                firstName = "John",
                surname = "Doe",
                status = MemberStatus.Active,
            )
        every { memberRepository.findById(testMemberId) } returns member

        // Act
        val result = memberService.findById(testMemberId)

        // Assert
        result.shouldBeInstanceOf<MemberResult.Success>()
        val success = result as MemberResult.Success
        success.member.firstName shouldBe "John"
        success.member.surname shouldBe "Doe"
        success.member.status shouldBe MemberStatus.Active
        success.member.sectorId shouldBe testSectorId
    }

    private fun createTestMember(
        id: MemberId,
        firstName: String = "Test",
        surname: String = "Member",
        status: MemberStatus = MemberStatus.Active,
    ): Member =
        Member(
            id = id,
            sectorId = testSectorId,
            email = "test@example.com",
            emailHash = "abc123def456",
            passwordHash = null,
            mustChangePassword = false,
            phoneHash = "hashedphone123",
            pinHash = "hashedpin456",
            phone = "+27821234567",
            firstName = firstName,
            surname = surname,
            address = "123 Test Street",
            registrationLocation = GeoPoint(latitude = -26.2041, longitude = 28.0473),
            status = status,
            createdAt = Instant.now(),
            updatedAt = Instant.now(),
        )
}
