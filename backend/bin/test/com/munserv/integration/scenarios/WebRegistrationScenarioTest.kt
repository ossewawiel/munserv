package com.munserv.integration.scenarios

import com.fasterxml.jackson.databind.ObjectMapper
import com.munserv.auth.api.ChangePasswordRequest
import com.munserv.auth.api.MemberLoginRequest
import com.munserv.auth.api.WebRegisterRequest
import com.munserv.auth.repository.MemberRepository
import com.munserv.shared.config.TestEmailConfig
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import org.junit.jupiter.api.MethodOrderer
import org.junit.jupiter.api.Order
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestMethodOrder
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.context.annotation.Import
import org.springframework.http.MediaType
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.delete
import org.springframework.test.web.servlet.post

/**
 * Scenario test: Complete web registration flow with admin approval.
 * Tests the full journey from registration request to member login.
 *
 * Flow:
 * 1. POST /auth/register/web - Submit registration request
 * 2. POST /admin/members/{id}/approve - Admin approves member
 * 3. POST /auth/member/login - Member logs in with temporary password
 * 4. POST /auth/change-password - Member changes password
 * 5. POST /auth/member/login - Member logs in with new password
 *
 * Rejection Flow:
 * 1. POST /auth/register/web - Submit registration request
 * 2. DELETE /admin/members/{id} - Admin rejects member
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import(TestEmailConfig::class)
@TestMethodOrder(MethodOrderer.OrderAnnotation::class)
class WebRegistrationScenarioTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    @Autowired
    private lateinit var memberRepository: MemberRepository

    // Admin credentials (from seed data)
    private val adminEmail = "admin@ward42.example.com"
    private val adminPassword = "admin123"

    // Test sector from migration
    private val testSectorId = "550e8400-e29b-41d4-a716-446655440001"

    companion object {
        var adminAccessToken: String? = null
        var pendingMemberId: String? = null
        var rejectionMemberId: String? = null
        var memberAccessToken: String? = null
        var memberEmail: String? = null
        var temporaryPassword: String? = null
    }

    @Test
    @Order(1)
    fun `step 1 - admin login to get access token`() {
        val request = mapOf("email" to adminEmail, "password" to adminPassword)

        val result =
            mockMvc
                .post("/api/v1/auth/admin/login") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }
                .andExpect {
                    status { isOk() }
                    jsonPath("$.tokens.accessToken") { isNotEmpty() }
                }
                .andReturn()

        val response = objectMapper.readTree(result.response.contentAsString)
        adminAccessToken = response.get("tokens").get("accessToken").asText()
        adminAccessToken shouldNotBe null
    }

    @Test
    @Order(2)
    fun `step 2 - POST auth-register-web creates pending member`() {
        memberEmail = "scenario-${System.currentTimeMillis()}@example.com"
        val request =
            WebRegisterRequest(
                email = memberEmail!!,
                firstName = "Test",
                surname = "Member",
                phone = "+27821234567",
                address = "123 Test Street",
                latitude = -26.2041,
                longitude = 28.0473,
                sectorId = testSectorId,
            )

        val result =
            mockMvc
                .post("/api/v1/auth/register/web") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }
                .andExpect {
                    status { isCreated() }
                    jsonPath("$.message") { value("Registration submitted. You will be notified once approved.") }
                    jsonPath("$.memberId") { isNotEmpty() }
                }
                .andReturn()

        val response = objectMapper.readTree(result.response.contentAsString)
        pendingMemberId = response.get("memberId").asText()
        pendingMemberId shouldNotBe null
    }

    @Test
    @Order(3)
    fun `step 3 - member login should fail while pending approval`() {
        val request =
            MemberLoginRequest(
                email = memberEmail!!,
                password = "anypassword",
            )

        mockMvc
            .post("/api/v1/auth/member/login") {
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(request)
            }
            .andExpect {
                status { isForbidden() }
                jsonPath("$.error") { value("pending_approval") }
            }
    }

    @Test
    @Order(4)
    fun `step 4 - admin approves member and receives temporary password`() {
        val token = adminAccessToken ?: throw IllegalStateException("Admin must login first")
        val memberId = pendingMemberId ?: throw IllegalStateException("Member must be registered first")

        val result =
            mockMvc
                .post("/api/v1/admin/members/$memberId/approve") {
                    header("Authorization", "Bearer $token")
                }
                .andExpect {
                    status { isOk() }
                    jsonPath("$.memberId") { value(memberId) }
                    jsonPath("$.email") { value(memberEmail) }
                    jsonPath("$.message") { isNotEmpty() }
                }
                .andReturn()

        // Extract temporary password from message
        val response = objectMapper.readTree(result.response.contentAsString)
        val message = response.get("message").asText()
        // Message format: "Member approved. Temporary password: XXXXX"
        temporaryPassword = message.substringAfter("Temporary password: ").trim()
        temporaryPassword shouldNotBe null
        temporaryPassword!!.isNotEmpty() shouldBe true
    }

    @Test
    @Order(5)
    fun `step 5 - member logs in with temporary password and mustChangePassword is true`() {
        val request =
            MemberLoginRequest(
                email = memberEmail!!,
                password = temporaryPassword!!,
            )

        val result =
            mockMvc
                .post("/api/v1/auth/member/login") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }
                .andExpect {
                    status { isOk() }
                    jsonPath("$.accessToken") { isNotEmpty() }
                    jsonPath("$.refreshToken") { isNotEmpty() }
                    jsonPath("$.mustChangePassword") { value(true) }
                }
                .andReturn()

        val response = objectMapper.readTree(result.response.contentAsString)
        memberAccessToken = response.get("accessToken").asText()
        memberAccessToken shouldNotBe null
    }

    @Test
    @Order(6)
    fun `step 6 - member changes password`() {
        val token = memberAccessToken ?: throw IllegalStateException("Member must login first")
        val newPassword = "NewSecurePassword123!"

        val request =
            ChangePasswordRequest(
                currentPassword = temporaryPassword!!,
                newPassword = newPassword,
            )

        mockMvc
            .post("/api/v1/auth/change-password") {
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(request)
                header("Authorization", "Bearer $token")
            }
            .andExpect {
                status { isOk() }
                jsonPath("$.message") { value("Password changed successfully") }
            }

        // Update for next test
        temporaryPassword = newPassword
    }

    @Test
    @Order(7)
    fun `step 7 - member logs in with new password and mustChangePassword is false`() {
        val request =
            MemberLoginRequest(
                email = memberEmail!!,
                password = temporaryPassword!!,
            )

        mockMvc
            .post("/api/v1/auth/member/login") {
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(request)
            }
            .andExpect {
                status { isOk() }
                jsonPath("$.accessToken") { isNotEmpty() }
                jsonPath("$.mustChangePassword") { value(false) }
            }
    }

    @Test
    @Order(10)
    fun `rejection flow step 1 - register another member for rejection`() {
        val email = "reject-scenario-${System.currentTimeMillis()}@example.com"
        val request =
            WebRegisterRequest(
                email = email,
                firstName = "Reject",
                surname = "Test",
                phone = "+27829876543",
                address = "456 Reject Street",
                latitude = -26.2041,
                longitude = 28.0473,
                sectorId = testSectorId,
            )

        val result =
            mockMvc
                .post("/api/v1/auth/register/web") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }
                .andExpect {
                    status { isCreated() }
                    jsonPath("$.memberId") { isNotEmpty() }
                }
                .andReturn()

        val response = objectMapper.readTree(result.response.contentAsString)
        rejectionMemberId = response.get("memberId").asText()
    }

    @Test
    @Order(11)
    fun `rejection flow step 2 - admin rejects member`() {
        // Ensure admin token is available (login if needed)
        val token = adminAccessToken ?: getAdminToken()
        val memberId = rejectionMemberId ?: throw IllegalStateException("Member must be registered first")

        mockMvc
            .delete("/api/v1/admin/members/$memberId") {
                header("Authorization", "Bearer $token")
            }
            .andExpect {
                // 204 No Content is returned for successful deletion
                status { isNoContent() }
            }
    }

    /**
     * Helper to get admin token - used when tests run in isolation.
     */
    private fun getAdminToken(): String {
        val request = mapOf("email" to adminEmail, "password" to adminPassword)
        val result =
            mockMvc
                .post("/api/v1/auth/admin/login") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }
                .andExpect { status { isOk() } }
                .andReturn()

        val response = objectMapper.readTree(result.response.contentAsString)
        val token = response.get("tokens").get("accessToken").asText()
        adminAccessToken = token
        return token
    }
}
