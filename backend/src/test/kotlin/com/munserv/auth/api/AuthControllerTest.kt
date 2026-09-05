package com.munserv.auth.api

import com.fasterxml.jackson.databind.ObjectMapper
import com.munserv.TestContainersConfig
import com.munserv.auth.repository.MemberRepository
import com.munserv.auth.service.OtpService
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.context.annotation.Import
import org.springframework.http.MediaType
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.post

@SpringBootTest
@Import(TestContainersConfig::class)
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AuthControllerTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    @Autowired
    private lateinit var memberRepository: MemberRepository

    @Autowired
    private lateinit var otpService: OtpService

    private val testPhone = "+27821234567"
    private val testPin = "1234"
    private val testSectorId = "550e8400-e29b-41d4-a716-446655440001"

    @BeforeEach
    fun setup() {
        // Clean test state if needed
    }

    @Test
    fun `POST api-v1-auth-register should send OTP for new phone`() {
        val request = RegisterRequest(phone = "+27829999888")

        mockMvc
            .post("/api/v1/auth/register") {
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(request)
            }
            .andExpect {
                status { isOk() }
                jsonPath("$.message") { value("OTP sent successfully") }
            }
    }

    @Test
    fun `POST api-v1-auth-register should fail for invalid phone`() {
        val request = RegisterRequest(phone = "invalid")

        mockMvc
            .post("/api/v1/auth/register") {
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(request)
            }
            .andExpect {
                status { isBadRequest() }
                jsonPath("$.error") { value("invalid_phone") }
            }
    }

    @Test
    fun `POST api-v1-auth-login should return tokens for valid credentials`() {
        // The seed data has a member with phone hash for +27821234567 and PIN 1234
        val request = LoginRequest(phone = testPhone, pin = testPin)

        mockMvc
            .post("/api/v1/auth/login") {
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(request)
            }
            .andExpect {
                status { isOk() }
                jsonPath("$.accessToken") { isNotEmpty() }
                jsonPath("$.refreshToken") { isNotEmpty() }
                jsonPath("$.expiresIn") { isNumber() }
                jsonPath("$.tokenType") { value("Bearer") }
            }
    }

    @Test
    fun `POST api-v1-auth-login should fail for wrong PIN`() {
        val request = LoginRequest(phone = testPhone, pin = "9999")

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
    fun `POST api-v1-auth-login should fail for unknown phone`() {
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
    fun `POST api-v1-auth-refresh should return new tokens`() {
        // First login to get a refresh token
        val loginRequest = LoginRequest(phone = testPhone, pin = testPin)

        val loginResult =
            mockMvc
                .post("/api/v1/auth/login") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(loginRequest)
                }
                .andExpect {
                    status { isOk() }
                }
                .andReturn()

        val loginResponse = objectMapper.readTree(loginResult.response.contentAsString)
        val refreshToken = loginResponse.get("refreshToken").asText()

        // Now use the refresh token
        val refreshRequest = RefreshTokenRequest(refreshToken = refreshToken)

        mockMvc
            .post("/api/v1/auth/refresh") {
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(refreshRequest)
            }
            .andExpect {
                status { isOk() }
                jsonPath("$.accessToken") { isNotEmpty() }
                jsonPath("$.refreshToken") { isNotEmpty() }
                jsonPath("$.expiresIn") { isNumber() }
            }
    }

    @Test
    fun `POST api-v1-auth-refresh should fail for invalid token`() {
        val request = RefreshTokenRequest(refreshToken = "invalid.token")

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

    @Test
    fun `auth endpoints should match mock API contract response format`() {
        val request = LoginRequest(phone = testPhone, pin = testPin)

        val result =
            mockMvc
                .post("/api/v1/auth/login") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }
                .andExpect {
                    status { isOk() }
                }
                .andReturn()

        // Verify response matches mock API format
        val content = result.response.contentAsString
        content.contains("\"accessToken\"") shouldBe true
        content.contains("\"refreshToken\"") shouldBe true
        content.contains("\"expiresIn\"") shouldBe true
        content.contains("\"tokenType\"") shouldBe true
        content.contains("\"memberId\"") shouldBe true
    }
}
