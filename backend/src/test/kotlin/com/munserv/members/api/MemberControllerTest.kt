package com.munserv.members.api

import com.munserv.TestContainersConfig
import com.munserv.auth.domain.Member
import com.munserv.auth.domain.MemberStatus
import com.munserv.auth.service.JwtService
import com.munserv.members.service.MemberResult
import com.munserv.members.service.MemberService
import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import com.ninjasquad.springmockk.MockkBean
import io.mockk.every
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.context.annotation.Import
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import java.time.Instant

@SpringBootTest
@Import(TestContainersConfig::class)
@AutoConfigureMockMvc
@ActiveProfiles("test")
class MemberControllerTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var jwtService: JwtService

    @MockkBean
    private lateinit var memberService: MemberService

    private val testSectorId = SectorId.generate()
    private lateinit var memberToken: String
    private val testMemberIdStr = "550e8400-e29b-41d4-a716-446655440010"

    @BeforeEach
    fun setup() {
        val memberId = MemberId.fromString(testMemberIdStr)
        memberToken = jwtService.generateAccessToken(memberId, "member")
    }

    @Test
    fun `GET me should return 403 when not authenticated`() {
        // Spring Security returns 403 Forbidden for missing authentication token
        mockMvc.get("/api/v1/members/me")
            .andExpect {
                status { isForbidden() }
            }
    }

    @Test
    fun `GET me should return 200 with member profile when authenticated`() {
        // Arrange
        val memberId = MemberId.fromString(testMemberIdStr)
        val member = createTestMember(memberId)
        every { memberService.findById(memberId) } returns MemberResult.Success(member)

        // Act & Assert
        mockMvc.get("/api/v1/members/me") {
            header("Authorization", "Bearer $memberToken")
        }
            .andExpect {
                status { isOk() }
                jsonPath("$.id") { value(memberId.value.toString()) }
                jsonPath("$.firstName") { value("Test") }
                jsonPath("$.surname") { value("Member") }
                jsonPath("$.status") { value("active") }
            }
    }

    @Test
    fun `GET me should return 404 when member not found`() {
        // Arrange
        val memberId = MemberId.fromString(testMemberIdStr)
        every { memberService.findById(memberId) } returns MemberResult.NotFound(memberId)

        // Act & Assert
        mockMvc.get("/api/v1/members/me") {
            header("Authorization", "Bearer $memberToken")
        }
            .andExpect {
                status { isNotFound() }
            }
    }

    @Test
    fun `GET me should return 403 when token is invalid`() {
        // Spring Security returns 403 Forbidden for invalid authentication token
        mockMvc.get("/api/v1/members/me") {
            header("Authorization", "Bearer invalid-token")
        }
            .andExpect {
                status { isForbidden() }
            }
    }

    private fun createTestMember(id: MemberId): Member =
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
            firstName = "Test",
            surname = "Member",
            address = "123 Test Street",
            registrationLocation = GeoPoint(latitude = -26.2041, longitude = 28.0473),
            status = MemberStatus.Active,
            createdAt = Instant.now(),
            updatedAt = Instant.now(),
        )
}
