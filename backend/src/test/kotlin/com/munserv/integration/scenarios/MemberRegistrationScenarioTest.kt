package com.munserv.integration.scenarios

import com.fasterxml.jackson.databind.ObjectMapper
import com.munserv.auth.api.LoginRequest
import com.munserv.auth.api.RefreshTokenRequest
import com.munserv.auth.api.RegisterRequest
import com.munserv.auth.api.VerifyOtpRequest
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import org.junit.jupiter.api.MethodOrderer
import org.junit.jupiter.api.Order
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestMethodOrder
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.http.MediaType
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.post

/**
 * Scenario test: Complete member registration flow.
 * Tests the full journey from phone registration to login.
 *
 * Flow:
 * 1. POST /auth/register - Request OTP
 * 2. POST /auth/verify-otp - Verify OTP (returns new_user)
 * 3. POST /auth/complete-registration - Complete profile (returns tokens)
 * 4. POST /auth/login - Login with PIN
 * 5. POST /auth/refresh - Refresh tokens
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@TestMethodOrder(MethodOrderer.OrderAnnotation::class)
class MemberRegistrationScenarioTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    // Test data for existing member (from seed data)
    private val existingPhone = "+27821234567"
    private val existingPin = "1234"

    companion object {
        // Store tokens across tests
        var accessToken: String? = null
        var refreshToken: String? = null
    }

    @Test
    @Order(1)
    fun `step 1 - POST auth-register for existing phone returns conflict`() {
        val request = RegisterRequest(phone = existingPhone)

        mockMvc
            .post("/api/v1/auth/register") {
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(request)
            }
            .andExpect {
                // Existing phone returns 409 Conflict
                status { isConflict() }
            }
    }

    @Test
    @Order(2)
    fun `step 2 - POST auth-login should authenticate and return tokens for existing member`() {
        val request = LoginRequest(phone = existingPhone, pin = existingPin)

        val result =
            mockMvc
                .post("/api/v1/auth/login") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }
                .andExpect {
                    status { isOk() }
                    jsonPath("$.accessToken") { isNotEmpty() }
                    jsonPath("$.refreshToken") { isNotEmpty() }
                    jsonPath("$.tokenType") { value("Bearer") }
                    jsonPath("$.memberId") { isNotEmpty() }
                }
                .andReturn()

        // Extract tokens for next steps
        val response = objectMapper.readTree(result.response.contentAsString)
        accessToken = response.get("accessToken").asText()
        refreshToken = response.get("refreshToken").asText()

        accessToken shouldNotBe null
        refreshToken shouldNotBe null
    }

    @Test
    @Order(3)
    fun `step 3 - POST auth-refresh should return new tokens`() {
        // Must have run step 2 first
        val token = refreshToken ?: throw IllegalStateException("Must run login test first")

        val request = RefreshTokenRequest(refreshToken = token)

        val result =
            mockMvc
                .post("/api/v1/auth/refresh") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }
                .andExpect {
                    status { isOk() }
                    jsonPath("$.accessToken") { isNotEmpty() }
                    jsonPath("$.refreshToken") { isNotEmpty() }
                }
                .andReturn()

        // Verify response matches contract
        val content = result.response.contentAsString
        content.contains("\"accessToken\"") shouldBe true
        content.contains("\"refreshToken\"") shouldBe true
        content.contains("\"expiresIn\"") shouldBe true
    }

    @Test
    @Order(4)
    fun `step 4 - invalid credentials should return 401`() {
        val request = LoginRequest(phone = existingPhone, pin = "9999")

        mockMvc
            .post("/api/v1/auth/login") {
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(request)
            }
            .andExpect {
                status { isUnauthorized() }
                jsonPath("$.error") { value("invalid_credentials") }
            }
    }

    @Test
    @Order(5)
    fun `step 5 - unknown phone should return 401`() {
        val request = LoginRequest(phone = "+27820000000", pin = "1234")

        mockMvc
            .post("/api/v1/auth/login") {
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(request)
            }
            .andExpect {
                status { isUnauthorized() }
                jsonPath("$.error") { value("invalid_credentials") }
            }
    }

    @Test
    @Order(6)
    fun `step 6 - invalid refresh token should return 401`() {
        val request = RefreshTokenRequest(refreshToken = "invalid.token.here")

        mockMvc
            .post("/api/v1/auth/refresh") {
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(request)
            }
            .andExpect {
                status { isUnauthorized() }
                jsonPath("$.error") { value("invalid_token") }
            }
    }
}
