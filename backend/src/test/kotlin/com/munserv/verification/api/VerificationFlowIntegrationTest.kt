package com.munserv.verification.api

import com.munserv.TestContainersConfig
import com.munserv.auth.service.JwtService
import com.munserv.shared.types.MemberId
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc
import org.springframework.context.annotation.Import
import org.springframework.http.MediaType
import org.springframework.jdbc.core.JdbcTemplate
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.post
import tools.jackson.databind.ObjectMapper
import java.util.UUID

/**
 * Not @Transactional on purpose: the service transaction must commit so PostgreSQL sees the INSERT.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import(TestContainersConfig::class)
class VerificationFlowIntegrationTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var jdbc: JdbcTemplate

    @Autowired
    private lateinit var jwtService: JwtService

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    private val issueId = UUID.fromString("550e8400-e29b-41d4-a716-446655440103")
    private val groundAdminId = UUID.fromString("550e8400-e29b-41d4-a716-446655440010")
    private val adminId = UUID.fromString("550e8400-e29b-41d4-a716-446655440020")

    private val adminToken get() = jwtService.generateAccessToken(MemberId(adminId), "admin")
    private val groundAdminToken get() = jwtService.generateAccessToken(MemberId(groundAdminId), "member")

    @BeforeEach
    fun makeGroundAdmin() {
        jdbc.update(
            "UPDATE members SET is_ground_admin = true, ground_admin_status = 'active'::ground_admin_status WHERE id = ?",
            groundAdminId,
        )
    }

    @AfterEach
    fun cleanUp() {
        jdbc.update("DELETE FROM messages WHERE recipient_id = ?", groundAdminId)
        jdbc.update("DELETE FROM issue_verifications WHERE issue_id = ?", issueId)
        jdbc.update("UPDATE members SET is_ground_admin = false, ground_admin_status = NULL WHERE id = ?", groundAdminId)
    }

    private fun requestVerification(): String {
        val response =
            mockMvc
                .post("/api/v1/issues/$issueId/request-verification") {
                    header("Authorization", "Bearer $adminToken")
                    contentType = MediaType.APPLICATION_JSON
                    content = """{"type":"existence"}"""
                }.andReturn()
                .response
        response.status shouldBe 200
        return objectMapper.readTree(response.contentAsString).get("id").asString()
    }

    @Test
    fun `POST request-verification should return 200 when the issue is reported`() {
        mockMvc
            .post("/api/v1/issues/$issueId/request-verification") {
                header("Authorization", "Bearer $adminToken")
                contentType = MediaType.APPLICATION_JSON
                content = """{"type":"existence"}"""
            }.andExpect {
                status { isOk() }
                jsonPath("$.status") { value("pending") }
            }

        jdbc.queryForObject(
            "SELECT count(*) FROM issue_verifications WHERE issue_id = ? AND reason IS NULL",
            Int::class.java,
            issueId,
        ) shouldBe 1
        jdbc.queryForObject(
            "SELECT count(*) FROM messages WHERE recipient_id = ? AND type = 'verify_new_issue'::message_type",
            Int::class.java,
            groundAdminId,
        ) shouldBe 1
    }

    @Test
    fun `POST verify should return 200 and store the reason when the ground admin cannot verify`() {
        val verificationId = requestVerification()

        mockMvc
            .post("/api/v1/issues/$issueId/verify") {
                header("Authorization", "Bearer $groundAdminToken")
                contentType = MediaType.APPLICATION_JSON
                content = """{"verificationId":"$verificationId","result":"cannot_verify","reason":"busy"}"""
            }.andExpect { status { isOk() } }

        mockMvc
            .get("/api/v1/issues/$issueId/verifications") {
                header("Authorization", "Bearer $groundAdminToken")
            }.andExpect {
                status { isOk() }
                jsonPath("$.items[0].reason") { value("busy") }
            }
    }
}
