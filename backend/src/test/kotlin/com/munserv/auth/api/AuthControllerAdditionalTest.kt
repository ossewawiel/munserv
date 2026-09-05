package com.munserv.auth.api

import com.munserv.TestContainersConfig
import com.munserv.auth.service.JwtService
import com.munserv.shared.types.MemberId
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc
import org.springframework.context.annotation.Import
import org.springframework.http.MediaType
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.post
import tools.jackson.databind.ObjectMapper

/**
 * Additional tests for AuthController endpoints not covered by AuthControllerTest.
 */
@SpringBootTest
@Import(TestContainersConfig::class)
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AuthControllerAdditionalTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    @Autowired
    private lateinit var jwtService: JwtService

    private val testSectorId = "550e8400-e29b-41d4-a716-446655440001"
    private val testMemberId = MemberId.fromString("550e8400-e29b-41d4-a716-446655440010")

    private lateinit var memberToken: String

    @BeforeEach
    fun setup() {
        memberToken = jwtService.generateAccessToken(testMemberId, "member")
    }

    @Nested
    inner class VerifyOtp {
        @Test
        fun `POST api-v1-auth-verify-otp should return 401 for invalid OTP`() {
            val request = VerifyOtpRequest(phone = "+27821234567", code = "999999")

            mockMvc
                .post("/api/v1/auth/verify-otp") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isUnauthorized() }
                    jsonPath("$.error") { value("invalid_otp") }
                }
        }

        @Test
        fun `POST api-v1-auth-verify-otp should return 400 for invalid phone`() {
            val request = VerifyOtpRequest(phone = "invalid", code = "123456")

            mockMvc
                .post("/api/v1/auth/verify-otp") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isBadRequest() }
                    jsonPath("$.error") { value("invalid_phone") }
                }
        }
    }

    @Nested
    inner class AdminLogin {
        @Test
        fun `POST api-v1-auth-admin-login should return tokens for valid credentials`() {
            val request =
                AdminLoginRequest(
                    email = "admin@ward42.example.com",
                    password = "admin123",
                )

            mockMvc
                .post("/api/v1/auth/admin/login") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isOk() }
                    jsonPath("$.tokens.accessToken") { isNotEmpty() }
                    jsonPath("$.tokens.refreshToken") { isNotEmpty() }
                    jsonPath("$.tokens.expiresAt") { isNotEmpty() }
                    jsonPath("$.profile.admin.email") { value("admin@ward42.example.com") }
                    jsonPath("$.profile.admin.sectorId") { value(testSectorId) }
                    jsonPath("$.profile.sector.id") { value(testSectorId) }
                }
        }

        @Test
        fun `POST api-v1-auth-admin-login should return 401 for invalid password`() {
            val request =
                AdminLoginRequest(
                    email = "admin@ward42.example.com",
                    password = "wrongpassword",
                )

            mockMvc
                .post("/api/v1/auth/admin/login") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isUnauthorized() }
                    jsonPath("$.error") { value("invalid_credentials") }
                }
        }

        @Test
        fun `POST api-v1-auth-admin-login should return 401 for unknown email`() {
            val request =
                AdminLoginRequest(
                    email = "unknown@example.com",
                    password = "admin123",
                )

            mockMvc
                .post("/api/v1/auth/admin/login") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isUnauthorized() }
                    jsonPath("$.error") { value("invalid_credentials") }
                }
        }
    }

    @Nested
    inner class CheckPhone {
        @Test
        fun `GET api-v1-auth-check-phone should return isRegistered true for existing phone`() {
            mockMvc
                .get("/api/v1/auth/check-phone") {
                    param("phone", "+27821234567")
                }.andExpect {
                    status { isOk() }
                    jsonPath("$.isRegistered") { value(true) }
                }
        }

        @Test
        fun `GET api-v1-auth-check-phone should return isRegistered false for new phone`() {
            mockMvc
                .get("/api/v1/auth/check-phone") {
                    param("phone", "+27829999999")
                }.andExpect {
                    status { isOk() }
                    jsonPath("$.isRegistered") { value(false) }
                }
        }

        @Test
        fun `GET api-v1-auth-check-phone should return 400 for invalid phone`() {
            mockMvc
                .get("/api/v1/auth/check-phone") {
                    param("phone", "invalid")
                }.andExpect {
                    status { isBadRequest() }
                    jsonPath("$.error") { value("invalid_phone") }
                }
        }
    }

    @Nested
    inner class WebRegister {
        @Test
        fun `POST api-v1-auth-register-web should create pending member`() {
            val uniqueEmail = "test-${System.currentTimeMillis()}@example.com"
            val request =
                WebRegisterRequest(
                    email = uniqueEmail,
                    firstName = "Test",
                    surname = "User",
                    phone = "+27821234567",
                    address = "123 Test Street",
                    latitude = -26.1350,
                    longitude = 27.9800,
                    sectorId = testSectorId,
                )

            mockMvc
                .post("/api/v1/auth/register/web") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isCreated() }
                    jsonPath("$.message") { isNotEmpty() }
                    jsonPath("$.memberId") { isNotEmpty() }
                }
        }

        @Test
        fun `POST api-v1-auth-register-web should return 409 for duplicate email`() {
            val email = "duplicate-${System.currentTimeMillis()}@example.com"
            val request =
                WebRegisterRequest(
                    email = email,
                    firstName = "Test",
                    surname = "User",
                    phone = "+27821234567",
                    address = "123 Test Street",
                    latitude = -26.1350,
                    longitude = 27.9800,
                    sectorId = testSectorId,
                )

            // First registration
            mockMvc
                .post("/api/v1/auth/register/web") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isCreated() }
                }

            // Second registration with same email
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
        fun `POST api-v1-auth-register-web should return 400 for invalid sector`() {
            val request =
                WebRegisterRequest(
                    email = "test-invalid-sector@example.com",
                    firstName = "Test",
                    surname = "User",
                    phone = "+27821234567",
                    address = "123 Test Street",
                    latitude = -26.1350,
                    longitude = 27.9800,
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
    inner class MemberLogin {
        @Test
        fun `POST api-v1-auth-member-login should return 401 for invalid credentials`() {
            val request =
                MemberLoginRequest(
                    email = "unknown@example.com",
                    password = "wrongpassword",
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
    }

    @Nested
    inner class ChangePassword {
        @Test
        fun `POST api-v1-auth-change-password should return 401 without token`() {
            val request =
                ChangePasswordRequest(
                    currentPassword = "oldpassword",
                    newPassword = "newpassword123",
                )

            mockMvc
                .post("/api/v1/auth/change-password") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isForbidden() }
                }
        }

        @Test
        fun `POST api-v1-auth-change-password should return 401 for invalid current password`() {
            val request =
                ChangePasswordRequest(
                    currentPassword = "wrongpassword",
                    newPassword = "newpassword123",
                )

            mockMvc
                .post("/api/v1/auth/change-password") {
                    header("Authorization", "Bearer $memberToken")
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isUnauthorized() }
                    jsonPath("$.error") { value("invalid_password") }
                }
        }
    }

    @Nested
    inner class ResponseMappings {
        @Test
        fun `ErrorResponse should contain error field with code and message`() {
            val response = ErrorResponse("test_error", "Test message")

            response.error shouldBe "test_error"
            response.message shouldBe "Test message"
        }

        @Test
        fun `OtpResponse should contain message field`() {
            val response = OtpResponse("OTP sent")

            response.message shouldBe "OTP sent"
        }

        @Test
        fun `CheckPhoneResponse should contain isRegistered field`() {
            val response = CheckPhoneResponse(isRegistered = true)

            response.isRegistered shouldBe true
        }
    }
}
