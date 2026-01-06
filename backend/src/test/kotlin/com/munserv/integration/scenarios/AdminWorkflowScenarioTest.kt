package com.munserv.integration.scenarios

import com.fasterxml.jackson.databind.ObjectMapper
import com.munserv.auth.service.JwtService
import com.munserv.issues.api.CreateIssueRequest
import com.munserv.issues.api.UpdateIssueStateRequest
import com.munserv.shared.types.MemberId
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import org.junit.jupiter.api.BeforeEach
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
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.patch
import org.springframework.test.web.servlet.post

/**
 * Scenario test: Complete admin workflow.
 * Tests the full admin journey from viewing dashboard to managing issues.
 *
 * Flow:
 * 1. GET /admin/dashboard - View dashboard stats
 * 2. GET /admin/reports/heat - View heat report
 * 3. GET /admin/members - View sector members
 * 4. GET /issues - View issues list
 * 5. PATCH /issues/{id}/state - Update issue state (valid transition)
 * 6. PATCH /issues/{id}/state - Update issue state (invalid transition - should fail)
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@TestMethodOrder(MethodOrderer.OrderAnnotation::class)
class AdminWorkflowScenarioTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    @Autowired
    private lateinit var jwtService: JwtService

    private val testSectorId = "550e8400-e29b-41d4-a716-446655440001"
    private val testAdminId = MemberId.fromString("550e8400-e29b-41d4-a716-446655440020")
    private val testMemberId = MemberId.fromString("550e8400-e29b-41d4-a716-446655440010")

    private lateinit var adminToken: String
    private lateinit var memberToken: String

    companion object {
        // Issue ID created for state transition tests
        var stateTestIssueId: String? = null
    }

    @BeforeEach
    fun setup() {
        adminToken = jwtService.generateAccessToken(testAdminId, "admin")
        memberToken = jwtService.generateAccessToken(testMemberId, "member")
    }

    @Test
    @Order(1)
    fun `step 1 - admin can view dashboard stats`() {
        mockMvc
            .get("/api/v1/admin/dashboard") {
                header("Authorization", "Bearer $adminToken")
                param("sectorId", testSectorId)
                accept = MediaType.APPLICATION_JSON
            }
            .andExpect {
                status { isOk() }
                jsonPath("$.sectorId") { value(testSectorId) }
                jsonPath("$.sectorName") { isNotEmpty() }
                jsonPath("$.stats.totalOpen") { isNumber() }
                jsonPath("$.stats.byState") { isMap() }
                jsonPath("$.stats.byType") { isMap() }
                jsonPath("$.stats.reportedThisWeek") { isNumber() }
            }
    }

    @Test
    @Order(2)
    fun `step 2 - admin can view heat report`() {
        mockMvc
            .get("/api/v1/admin/reports/heat") {
                header("Authorization", "Bearer $adminToken")
                param("sectorId", testSectorId)
                accept = MediaType.APPLICATION_JSON
            }
            .andExpect {
                status { isOk() }
                jsonPath("$.generatedAt") { isNotEmpty() }
                jsonPath("$.items") { isArray() }
            }
    }

    @Test
    @Order(3)
    fun `step 3 - admin can view members list`() {
        mockMvc
            .get("/api/v1/admin/members") {
                header("Authorization", "Bearer $adminToken")
                param("sectorId", testSectorId)
                accept = MediaType.APPLICATION_JSON
            }
            .andExpect {
                status { isOk() }
                jsonPath("$.items") { isArray() }
                jsonPath("$.pagination.page") { value(1) }
                jsonPath("$.pagination.limit") { value(20) }
                jsonPath("$.pagination.totalItems") { isNumber() }
                jsonPath("$.pagination.totalPages") { isNumber() }
            }
    }

    @Test
    @Order(4)
    fun `step 4 - admin can view issues`() {
        mockMvc
            .get("/api/v1/issues") {
                header("Authorization", "Bearer $adminToken")
                param("sectorId", testSectorId)
                accept = MediaType.APPLICATION_JSON
            }
            .andExpect {
                status { isOk() }
                jsonPath("$.items") { isArray() }
                jsonPath("$.pagination") { isMap() }
            }
    }

    @Test
    @Order(5)
    fun `step 5 - admin can update issue state with valid transition`() {
        // Create a fresh issue for state transition testing
        val createRequest =
            CreateIssueRequest(
                type = "pothole",
                latitude = -26.1350,
                longitude = 27.9800,
                description = "Admin workflow test issue",
            )

        val createResult =
            mockMvc
                .post("/api/v1/issues") {
                    header("Authorization", "Bearer $memberToken")
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(createRequest)
                }
                .andExpect { status { isCreated() } }
                .andReturn()

        val createResponse = objectMapper.readTree(createResult.response.contentAsString)
        stateTestIssueId = createResponse.get("id").asText()
        stateTestIssueId shouldNotBe null

        // Now update the state
        val request =
            UpdateIssueStateRequest(
                state = "confirmed",
                note = "Verified on site visit",
            )

        mockMvc
            .patch("/api/v1/issues/$stateTestIssueId/state") {
                header("Authorization", "Bearer $adminToken")
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(request)
            }
            .andExpect {
                status { isOk() }
                jsonPath("$.id") { value(stateTestIssueId) }
                jsonPath("$.state") { value("confirmed") }
            }
    }

    @Test
    @Order(6)
    fun `step 6 - invalid state transition returns 422`() {
        val issueId = stateTestIssueId ?: throw IllegalStateException("Must run step 5 first")

        // Try to go directly from confirmed to fixed (invalid - must go through in_progress)
        val request =
            UpdateIssueStateRequest(
                state = "fixed",
                note = "Trying to fix directly",
            )

        mockMvc
            .patch("/api/v1/issues/$issueId/state") {
                header("Authorization", "Bearer $adminToken")
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(request)
            }
            .andExpect {
                status { isUnprocessableEntity() }
                jsonPath("$.error.code") { value("INVALID_STATE_TRANSITION") }
            }
    }

    @Test
    @Order(7)
    fun `step 7 - valid transition to in_progress`() {
        val issueId = stateTestIssueId ?: throw IllegalStateException("Must run step 5 first")

        val request =
            UpdateIssueStateRequest(
                state = "in_progress",
                note = "Work started",
            )

        mockMvc
            .patch("/api/v1/issues/$issueId/state") {
                header("Authorization", "Bearer $adminToken")
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(request)
            }
            .andExpect {
                status { isOk() }
                jsonPath("$.state") { value("in_progress") }
            }
    }

    @Test
    @Order(8)
    fun `step 8 - valid transition to fixed`() {
        val issueId = stateTestIssueId ?: throw IllegalStateException("Must run step 5 first")

        val request =
            UpdateIssueStateRequest(
                state = "fixed",
                note = "Issue resolved",
            )

        mockMvc
            .patch("/api/v1/issues/$issueId/state") {
                header("Authorization", "Bearer $adminToken")
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(request)
            }
            .andExpect {
                status { isOk() }
                jsonPath("$.state") { value("fixed") }
            }
    }

    @Test
    @Order(9)
    fun `step 9 - regular member cannot access admin endpoints`() {
        mockMvc
            .get("/api/v1/admin/dashboard") {
                header("Authorization", "Bearer $memberToken")
                param("sectorId", testSectorId)
                accept = MediaType.APPLICATION_JSON
            }
            .andExpect {
                status { isForbidden() }
            }

        mockMvc
            .get("/api/v1/admin/reports/heat") {
                header("Authorization", "Bearer $memberToken")
                param("sectorId", testSectorId)
                accept = MediaType.APPLICATION_JSON
            }
            .andExpect {
                status { isForbidden() }
            }

        mockMvc
            .get("/api/v1/admin/members") {
                header("Authorization", "Bearer $memberToken")
                param("sectorId", testSectorId)
                accept = MediaType.APPLICATION_JSON
            }
            .andExpect {
                status { isForbidden() }
            }
    }

    @Test
    @Order(10)
    fun `step 10 - dashboard response matches mock API contract`() {
        val result =
            mockMvc
                .get("/api/v1/admin/dashboard") {
                    header("Authorization", "Bearer $adminToken")
                    param("sectorId", testSectorId)
                    accept = MediaType.APPLICATION_JSON
                }
                .andExpect {
                    status { isOk() }
                }
                .andReturn()

        val content = result.response.contentAsString
        content.contains("\"sectorId\"") shouldBe true
        content.contains("\"sectorName\"") shouldBe true
        content.contains("\"stats\"") shouldBe true
        content.contains("\"totalOpen\"") shouldBe true
        content.contains("\"byState\"") shouldBe true
        content.contains("\"byType\"") shouldBe true
        content.contains("\"reportedThisWeek\"") shouldBe true
    }

    @Test
    @Order(11)
    fun `step 11 - heat report response matches mock API contract`() {
        val result =
            mockMvc
                .get("/api/v1/admin/reports/heat") {
                    header("Authorization", "Bearer $adminToken")
                    param("sectorId", testSectorId)
                    accept = MediaType.APPLICATION_JSON
                }
                .andExpect {
                    status { isOk() }
                }
                .andReturn()

        val content = result.response.contentAsString
        content.contains("\"generatedAt\"") shouldBe true
        content.contains("\"items\"") shouldBe true
    }

    @Test
    @Order(12)
    fun `step 12 - members list response matches mock API contract`() {
        val result =
            mockMvc
                .get("/api/v1/admin/members") {
                    header("Authorization", "Bearer $adminToken")
                    param("sectorId", testSectorId)
                    accept = MediaType.APPLICATION_JSON
                }
                .andExpect {
                    status { isOk() }
                }
                .andReturn()

        val content = result.response.contentAsString
        content.contains("\"items\"") shouldBe true
        content.contains("\"pagination\"") shouldBe true
        content.contains("\"page\"") shouldBe true
        content.contains("\"limit\"") shouldBe true
        content.contains("\"totalItems\"") shouldBe true
        content.contains("\"totalPages\"") shouldBe true
    }
}
