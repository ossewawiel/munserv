package com.munserv.auth.api

import com.munserv.TestContainersConfig
import com.munserv.auth.domain.Email
import com.munserv.auth.domain.Member
import com.munserv.auth.domain.MemberStatus
import com.munserv.auth.domain.Password
import com.munserv.auth.repository.MemberRepository
import com.munserv.auth.service.JwtService
import com.munserv.shared.config.TestEmailConfig
import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc
import org.springframework.context.annotation.Import
import org.springframework.http.MediaType
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.delete
import org.springframework.test.web.servlet.post
import tools.jackson.databind.ObjectMapper
import java.time.Instant

/**
 * API contract tests for web registration endpoints.
 * Tests the new registration flow: web form → pending approval → admin approval → email login.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import(TestContainersConfig::class, TestEmailConfig::class)
class WebRegistrationApiContractTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    @Autowired
    private lateinit var memberRepository: MemberRepository

    @Autowired
    private lateinit var jwtService: JwtService

    private val testSectorId = "550e8400-e29b-41d4-a716-446655440001"
    private val testEmail = "newmember@example.com"

    @Nested
    inner class WebRegistration {
        @Test
        fun `POST api-v1-auth-register-web should create pending member`() {
            val request =
                WebRegisterRequest(
                    email = "unique-${System.currentTimeMillis()}@example.com",
                    firstName = "John",
                    surname = "Doe",
                    phone = "+27821234567",
                    address = "123 Main Street, Pretoria",
                    latitude = -26.2041,
                    longitude = 28.0473,
                    sectorId = testSectorId,
                )

            mockMvc
                .post("/api/v1/auth/register/web") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isCreated() }
                    jsonPath("$.memberId") { isNotEmpty() }
                    jsonPath("$.message") { value("Registration submitted. You will be notified once approved.") }
                }
        }

        @Test
        fun `POST api-v1-auth-register-web should fail for invalid email`() {
            val request =
                WebRegisterRequest(
                    email = "invalid-email",
                    firstName = "John",
                    surname = "Doe",
                    phone = "+27821234567",
                    address = "123 Main Street",
                    latitude = -26.2041,
                    longitude = 28.0473,
                    sectorId = testSectorId,
                )

            mockMvc
                .post("/api/v1/auth/register/web") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isBadRequest() }
                }
        }

        @Test
        fun `POST api-v1-auth-register-web should fail for duplicate email`() {
            // First registration
            val email = "duplicate-${System.currentTimeMillis()}@example.com"
            val request =
                WebRegisterRequest(
                    email = email,
                    firstName = "John",
                    surname = "Doe",
                    phone = "+27821234567",
                    address = "123 Main Street",
                    latitude = -26.2041,
                    longitude = 28.0473,
                    sectorId = testSectorId,
                )

            // First request should succeed
            mockMvc
                .post("/api/v1/auth/register/web") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isCreated() }
                }

            // Second request with same email should fail
            mockMvc
                .post("/api/v1/auth/register/web") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isConflict() }
                    jsonPath("$.error") { value("email_registered") }
                }
        }

        @Test
        fun `POST api-v1-auth-register-web should fail for invalid sector`() {
            val request =
                WebRegisterRequest(
                    email = "test-${System.currentTimeMillis()}@example.com",
                    firstName = "John",
                    surname = "Doe",
                    phone = "+27821234567",
                    address = "123 Main Street",
                    latitude = -26.2041,
                    longitude = 28.0473,
                    // Non-existent sector
                    sectorId = "00000000-0000-0000-0000-000000000000",
                )

            mockMvc
                .post("/api/v1/auth/register/web") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isBadRequest() }
                    jsonPath("$.error") { value("invalid_sector") }
                }
        }
    }

    @Nested
    inner class MemberEmailLogin {
        @Test
        fun `POST api-v1-auth-member-login should return tokens for approved member`() {
            // Create an approved member with password
            val email = "approved-${System.currentTimeMillis()}@example.com"
            val password = "TestPassword123"
            val member = createApprovedMember(email, password)

            val request =
                MemberLoginRequest(
                    email = email,
                    password = password,
                )

            mockMvc
                .post("/api/v1/auth/member/login") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isOk() }
                    jsonPath("$.memberId") { value(member.id.value.toString()) }
                    jsonPath("$.accessToken") { isNotEmpty() }
                    jsonPath("$.refreshToken") { isNotEmpty() }
                    jsonPath("$.expiresIn") { isNumber() }
                    jsonPath("$.mustChangePassword") { isBoolean() }
                }
        }

        @Test
        fun `POST api-v1-auth-member-login should fail for wrong password`() {
            val email = "wrongpass-${System.currentTimeMillis()}@example.com"
            val password = "TestPassword123"
            createApprovedMember(email, password)

            val request =
                MemberLoginRequest(
                    email = email,
                    password = "WrongPassword123",
                )

            mockMvc
                .post("/api/v1/auth/member/login") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isUnauthorized() }
                    jsonPath("$.error") { value("invalid_credentials") }
                }
        }

        @Test
        fun `POST api-v1-auth-member-login should fail for pending member`() {
            val email = "pending-${System.currentTimeMillis()}@example.com"
            createPendingMember(email)

            val request =
                MemberLoginRequest(
                    email = email,
                    password = "AnyPassword123",
                )

            mockMvc
                .post("/api/v1/auth/member/login") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isForbidden() }
                    jsonPath("$.error") { value("pending_approval") }
                }
        }

        @Test
        fun `POST api-v1-auth-member-login should fail for suspended member`() {
            val email = "suspended-${System.currentTimeMillis()}@example.com"
            val password = "TestPassword123"
            createSuspendedMember(email, password)

            val request =
                MemberLoginRequest(
                    email = email,
                    password = password,
                )

            mockMvc
                .post("/api/v1/auth/member/login") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isForbidden() }
                    jsonPath("$.error") { value("account_suspended") }
                }
        }
    }

    @Nested
    inner class ChangePassword {
        @Test
        fun `POST api-v1-auth-change-password should change password for authenticated member`() {
            val email = "changepass-${System.currentTimeMillis()}@example.com"
            val currentPassword = "OldPassword123"
            val newPassword = "NewPassword456"
            val member = createApprovedMember(email, currentPassword, mustChangePassword = true)

            // Get auth token
            val token = jwtService.generateAccessToken(member.id, "member")

            val request =
                ChangePasswordRequest(
                    currentPassword = currentPassword,
                    newPassword = newPassword,
                )

            mockMvc
                .post("/api/v1/auth/change-password") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                    header("Authorization", "Bearer $token")
                }.andExpect {
                    status { isOk() }
                    jsonPath("$.message") { value("Password changed successfully") }
                }
        }

        @Test
        fun `POST api-v1-auth-change-password should fail for wrong current password`() {
            val email = "wrongcurrent-${System.currentTimeMillis()}@example.com"
            val currentPassword = "OldPassword123"
            val member = createApprovedMember(email, currentPassword)

            val token = jwtService.generateAccessToken(member.id, "member")

            val request =
                ChangePasswordRequest(
                    currentPassword = "WrongOldPassword",
                    newPassword = "NewPassword456",
                )

            mockMvc
                .post("/api/v1/auth/change-password") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                    header("Authorization", "Bearer $token")
                }.andExpect {
                    status { isUnauthorized() }
                    jsonPath("$.error") { value("invalid_password") }
                }
        }

        @Test
        fun `POST api-v1-auth-change-password should fail for weak new password`() {
            val email = "weakpass-${System.currentTimeMillis()}@example.com"
            val currentPassword = "OldPassword123"
            val member = createApprovedMember(email, currentPassword)

            val token = jwtService.generateAccessToken(member.id, "member")

            val request =
                ChangePasswordRequest(
                    currentPassword = currentPassword,
                    // Too short - must be at least 8 characters
                    newPassword = "weak",
                )

            mockMvc
                .post("/api/v1/auth/change-password") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                    header("Authorization", "Bearer $token")
                }.andExpect {
                    status { isBadRequest() }
                    // Global exception handler returns nested error format
                    jsonPath("$.error.code") { value("VALIDATION_ERROR") }
                }
        }

        @Test
        fun `POST api-v1-auth-change-password should require authentication`() {
            val request =
                ChangePasswordRequest(
                    currentPassword = "OldPassword123",
                    newPassword = "NewPassword456",
                )

            mockMvc
                .post("/api/v1/auth/change-password") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    // Spring Security returns 403 Forbidden for unauthenticated requests to authenticated() endpoints
                    status { isForbidden() }
                }
        }
    }

    @Nested
    inner class AdminMemberApproval {
        @Test
        fun `POST api-v1-admin-members-id-approve should approve pending member`() {
            val email = "toapprove-${System.currentTimeMillis()}@example.com"
            val member = createPendingMember(email)

            // Get admin token (using test admin credentials)
            val adminToken = getAdminToken()

            mockMvc
                .post("/api/v1/admin/members/${member.id.value}/approve") {
                    header("Authorization", "Bearer $adminToken")
                }.andExpect {
                    status { isOk() }
                    jsonPath("$.memberId") { value(member.id.value.toString()) }
                    jsonPath("$.email") { value(email) }
                    jsonPath("$.message") { prefix("Member approved. Temporary password: ") }
                }
        }

        @Test
        fun `POST api-v1-admin-members-id-approve should fail for non-pending member`() {
            val email = "alreadyactive-${System.currentTimeMillis()}@example.com"
            val member = createApprovedMember(email, "Password123")

            val adminToken = getAdminToken()

            mockMvc
                .post("/api/v1/admin/members/${member.id.value}/approve") {
                    header("Authorization", "Bearer $adminToken")
                }.andExpect {
                    status { isBadRequest() }
                    jsonPath("$.error") { value("invalid_status") }
                }
        }

        @Test
        fun `POST api-v1-admin-members-id-approve should fail for non-existent member`() {
            val adminToken = getAdminToken()
            val nonExistentId = "00000000-0000-0000-0000-000000000099"

            mockMvc
                .post("/api/v1/admin/members/$nonExistentId/approve") {
                    header("Authorization", "Bearer $adminToken")
                }.andExpect {
                    status { isNotFound() }
                    jsonPath("$.error") { value("not_found") }
                }
        }

        @Test
        fun `POST api-v1-admin-members-id-approve should require admin role`() {
            val email = "noadmin-${System.currentTimeMillis()}@example.com"
            val member = createPendingMember(email)

            // Get member token (not admin)
            val memberToken = jwtService.generateAccessToken(member.id, "member")

            mockMvc
                .post("/api/v1/admin/members/${member.id.value}/approve") {
                    header("Authorization", "Bearer $memberToken")
                }.andExpect {
                    status { isForbidden() }
                }
        }
    }

    @Nested
    inner class AdminMemberRejection {
        @Test
        fun `DELETE api-v1-admin-members-id should reject pending member`() {
            val email = "toreject-${System.currentTimeMillis()}@example.com"
            val member = createPendingMember(email)

            val adminToken = getAdminToken()

            mockMvc
                .delete("/api/v1/admin/members/${member.id.value}") {
                    header("Authorization", "Bearer $adminToken")
                }.andExpect {
                    status { isNoContent() }
                }

            // Verify member is deleted
            memberRepository.findById(member.id) shouldBe null
        }

        @Test
        fun `DELETE api-v1-admin-members-id should fail for non-pending member`() {
            val email = "cantreject-${System.currentTimeMillis()}@example.com"
            val member = createApprovedMember(email, "Password123")

            val adminToken = getAdminToken()

            mockMvc
                .delete("/api/v1/admin/members/${member.id.value}") {
                    header("Authorization", "Bearer $adminToken")
                }.andExpect {
                    status { isBadRequest() }
                    jsonPath("$.error") { value("invalid_status") }
                }
        }
    }

    // Helper methods

    private fun createPendingMember(email: String): Member {
        val emailObj = Email.fromString(email)
        val member =
            Member(
                id = MemberId.generate(),
                sectorId = SectorId.fromString(testSectorId),
                email = email,
                emailHash = emailObj.hash(),
                passwordHash = null,
                mustChangePassword = true,
                phoneHash = null,
                pinHash = null,
                phone = "+27821234567",
                firstName = "Pending",
                surname = "Member",
                address = "123 Test Street",
                registrationLocation = GeoPoint(-26.2041, 28.0473),
                status = MemberStatus.PendingApproval,
                createdAt = Instant.now(),
                updatedAt = Instant.now(),
            )
        return memberRepository.save(member)
    }

    private fun createApprovedMember(
        email: String,
        password: String,
        mustChangePassword: Boolean = false,
    ): Member {
        val emailObj = Email.fromString(email)
        val member =
            Member(
                id = MemberId.generate(),
                sectorId = SectorId.fromString(testSectorId),
                email = email,
                emailHash = emailObj.hash(),
                passwordHash = Password.hash(password),
                mustChangePassword = mustChangePassword,
                phoneHash = null,
                pinHash = null,
                phone = "+27821234567",
                firstName = "Approved",
                surname = "Member",
                address = "123 Test Street",
                registrationLocation = GeoPoint(-26.2041, 28.0473),
                status = MemberStatus.Active,
                createdAt = Instant.now(),
                updatedAt = Instant.now(),
            )
        return memberRepository.save(member)
    }

    private fun createSuspendedMember(
        email: String,
        password: String,
    ): Member {
        val emailObj = Email.fromString(email)
        val member =
            Member(
                id = MemberId.generate(),
                sectorId = SectorId.fromString(testSectorId),
                email = email,
                emailHash = emailObj.hash(),
                passwordHash = Password.hash(password),
                mustChangePassword = false,
                phoneHash = null,
                pinHash = null,
                phone = "+27821234567",
                firstName = "Suspended",
                surname = "Member",
                address = "123 Test Street",
                registrationLocation = GeoPoint(-26.2041, 28.0473),
                status = MemberStatus.Suspended,
                createdAt = Instant.now(),
                updatedAt = Instant.now(),
            )
        return memberRepository.save(member)
    }

    private fun getAdminToken(): String {
        // Login as admin to get token
        val loginRequest =
            AdminLoginRequest(
                email = "admin@ward42.example.com",
                password = "admin123",
            )

        val result =
            mockMvc
                .post("/api/v1/auth/admin/login") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(loginRequest)
                }.andReturn()

        val response = objectMapper.readTree(result.response.contentAsString)
        return response.get("tokens").get("accessToken").asText()
    }
}
