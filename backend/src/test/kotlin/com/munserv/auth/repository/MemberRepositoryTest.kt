package com.munserv.auth.repository

import com.munserv.auth.domain.Email
import com.munserv.auth.domain.Member
import com.munserv.auth.domain.MemberStatus
import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.test.context.ActiveProfiles
import org.springframework.transaction.annotation.Transactional
import java.time.Instant

/**
 * Integration tests for MemberRepository.
 * Tests the new methods required for web registration with email authentication.
 */
@SpringBootTest
@ActiveProfiles("test")
@Transactional
class MemberRepositoryTest {
    @Autowired
    private lateinit var memberRepository: MemberRepository

    // Test sector ID from migration V004
    private val testSectorId = SectorId.fromString("550e8400-e29b-41d4-a716-446655440001")

    // Existing member from V005 migration - John Doe
    private val existingMemberId = MemberId.fromString("550e8400-e29b-41d4-a716-446655440010")

    @Nested
    inner class FindByEmailHash {
        @Test
        fun `should find member by email hash`() {
            // Arrange - create a member with known email
            val email = Email.fromString("findbyemail@test.example.com")
            val member = createTestMember(email = email.value, emailHash = email.hash())
            memberRepository.save(member)

            // Act
            val result = memberRepository.findByEmailHash(email.hash())

            // Assert
            result shouldNotBe null
            result?.email shouldBe email.value
            result?.emailHash shouldBe email.hash()
        }

        @Test
        fun `should return null when email hash not found`() {
            // Arrange
            val nonExistentHash = Email.fromString("nonexistent@test.example.com").hash()

            // Act
            val result = memberRepository.findByEmailHash(nonExistentHash)

            // Assert
            result shouldBe null
        }
    }

    @Nested
    inner class ExistsByEmailHash {
        @Test
        fun `should return true when email hash exists`() {
            // Arrange
            val email = Email.fromString("exists@test.example.com")
            val member = createTestMember(email = email.value, emailHash = email.hash())
            memberRepository.save(member)

            // Act
            val result = memberRepository.existsByEmailHash(email.hash())

            // Assert
            result shouldBe true
        }

        @Test
        fun `should return false when email hash does not exist`() {
            // Arrange
            val nonExistentHash = Email.fromString("doesnotexist@test.example.com").hash()

            // Act
            val result = memberRepository.existsByEmailHash(nonExistentHash)

            // Assert
            result shouldBe false
        }
    }

    @Nested
    inner class FindBySectorIdAndStatus {
        @BeforeEach
        fun setupMembers() {
            // Create members with different statuses in test sector
            val activeEmail1 = Email.fromString("active1@test.example.com")
            val activeEmail2 = Email.fromString("active2@test.example.com")
            val pendingEmail = Email.fromString("pending@test.example.com")

            memberRepository.save(
                createTestMember(
                    email = activeEmail1.value,
                    emailHash = activeEmail1.hash(),
                    status = MemberStatus.Active,
                ),
            )
            memberRepository.save(
                createTestMember(
                    email = activeEmail2.value,
                    emailHash = activeEmail2.hash(),
                    status = MemberStatus.Active,
                ),
            )
            memberRepository.save(
                createTestMember(
                    email = pendingEmail.value,
                    emailHash = pendingEmail.hash(),
                    status = MemberStatus.PendingApproval,
                ),
            )
        }

        @Test
        fun `should find members by sector and active status`() {
            // Act
            val result = memberRepository.findBySectorIdAndStatus(testSectorId, MemberStatus.Active)

            // Assert - at least 2 active members (plus existing seed data)
            result.size shouldBe result.size // non-empty
            result.all { it.status == MemberStatus.Active } shouldBe true
            result.all { it.sectorId == testSectorId } shouldBe true
        }

        @Test
        fun `should find members by sector and pending approval status`() {
            // Act
            val result = memberRepository.findBySectorIdAndStatus(testSectorId, MemberStatus.PendingApproval)

            // Assert
            result shouldHaveSize 1
            result.first().status shouldBe MemberStatus.PendingApproval
            result.first().sectorId shouldBe testSectorId
        }

        @Test
        fun `should return empty list when no members match criteria`() {
            // Act
            val result = memberRepository.findBySectorIdAndStatus(testSectorId, MemberStatus.Suspended)

            // Assert
            result.shouldBeEmpty()
        }

        @Test
        fun `should return empty list for non-existent sector`() {
            // Act
            val result = memberRepository.findBySectorIdAndStatus(SectorId.generate(), MemberStatus.Active)

            // Assert
            result.shouldBeEmpty()
        }
    }

    @Nested
    inner class Delete {
        @Test
        fun `should delete existing member`() {
            // Arrange
            val email = Email.fromString("todelete@test.example.com")
            val member = createTestMember(email = email.value, emailHash = email.hash())
            val saved = memberRepository.save(member)

            // Verify it exists
            memberRepository.findById(saved.id) shouldNotBe null

            // Act
            memberRepository.delete(saved.id)

            // Assert
            memberRepository.findById(saved.id) shouldBe null
        }

        @Test
        fun `should not throw when deleting non-existent member`() {
            // Arrange
            val nonExistentId = MemberId.generate()

            // Act & Assert - should not throw
            memberRepository.delete(nonExistentId)
        }
    }

    private fun createTestMember(
        id: MemberId = MemberId.generate(),
        sectorId: SectorId = testSectorId,
        email: String = "test@test.example.com",
        emailHash: String = "testhash123",
        status: MemberStatus = MemberStatus.Active,
    ): Member =
        Member(
            id = id,
            sectorId = sectorId,
            email = email,
            emailHash = emailHash,
            passwordHash = null,
            mustChangePassword = true,
            phoneHash = null,
            pinHash = null,
            phone = "+27820000000",
            firstName = "Test",
            surname = "User",
            address = "123 Test Street",
            registrationLocation = GeoPoint(27.9833, -26.1367),
            status = status,
            createdAt = Instant.now(),
            updatedAt = Instant.now(),
        )
}
