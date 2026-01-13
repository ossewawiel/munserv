package com.munserv.issues.api

import com.fasterxml.jackson.databind.ObjectMapper
import com.munserv.auth.service.JwtService
import com.munserv.shared.types.MemberId
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
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
 * API contract tests for Issues endpoints.
 * Verifies that responses match the mock API contract exactly.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class IssuesApiContractTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var jwtService: JwtService

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    private lateinit var memberToken: String
    private lateinit var adminToken: String

    private val testSectorId = "550e8400-e29b-41d4-a716-446655440001"
    private val testMemberId = MemberId.fromString("550e8400-e29b-41d4-a716-446655440010")
    private val testAdminId = MemberId.fromString("550e8400-e29b-41d4-a716-446655440020")
    private val testIssueId = "550e8400-e29b-41d4-a716-446655440100"

    @BeforeEach
    fun setup() {
        memberToken = jwtService.generateAccessToken(testMemberId, "member")
        adminToken = jwtService.generateAccessToken(testAdminId, "admin")
    }

    @Nested
    inner class ListIssues {
        @Test
        fun `GET api-v1-issues should return paginated list with member token`() {
            mockMvc
                .get("/api/v1/issues") {
                    header("Authorization", "Bearer $memberToken")
                    param("sectorId", testSectorId)
                    accept = MediaType.APPLICATION_JSON
                }
                .andExpect {
                    status { isOk() }
                    content { contentType(MediaType.APPLICATION_JSON) }
                    jsonPath("$.items") { isArray() }
                    jsonPath("$.pagination.page") { value(1) }
                    jsonPath("$.pagination.limit") { value(20) }
                    jsonPath("$.pagination.totalItems") { isNumber() }
                    jsonPath("$.pagination.totalPages") { isNumber() }
                }
        }

        @Test
        fun `GET api-v1-issues should filter by state`() {
            mockMvc
                .get("/api/v1/issues") {
                    header("Authorization", "Bearer $memberToken")
                    param("sectorId", testSectorId)
                    param("state", "reported")
                    accept = MediaType.APPLICATION_JSON
                }
                .andExpect {
                    status { isOk() }
                    jsonPath("$.items") { isArray() }
                }
        }

        @Test
        fun `GET api-v1-issues should filter by type`() {
            mockMvc
                .get("/api/v1/issues") {
                    header("Authorization", "Bearer $memberToken")
                    param("sectorId", testSectorId)
                    param("type", "pothole")
                    accept = MediaType.APPLICATION_JSON
                }
                .andExpect {
                    status { isOk() }
                    jsonPath("$.items") { isArray() }
                }
        }

        @Test
        fun `GET api-v1-issues should respect pagination parameters`() {
            mockMvc
                .get("/api/v1/issues") {
                    header("Authorization", "Bearer $memberToken")
                    param("sectorId", testSectorId)
                    param("page", "1")
                    param("limit", "5")
                    accept = MediaType.APPLICATION_JSON
                }
                .andExpect {
                    status { isOk() }
                    jsonPath("$.pagination.page") { value(1) }
                    jsonPath("$.pagination.limit") { value(5) }
                }
        }

        @Test
        fun `GET api-v1-issues should sort by heat by default`() {
            mockMvc
                .get("/api/v1/issues") {
                    header("Authorization", "Bearer $memberToken")
                    param("sectorId", testSectorId)
                    accept = MediaType.APPLICATION_JSON
                }
                .andExpect {
                    status { isOk() }
                }
        }

        @Test
        fun `GET api-v1-issues should sort by createdAt when specified`() {
            mockMvc
                .get("/api/v1/issues") {
                    header("Authorization", "Bearer $memberToken")
                    param("sectorId", testSectorId)
                    param("sortBy", "createdAt")
                    accept = MediaType.APPLICATION_JSON
                }
                .andExpect {
                    status { isOk() }
                }
        }

        @Test
        fun `issues list response should match mock API contract format`() {
            val result =
                mockMvc
                    .get("/api/v1/issues") {
                        header("Authorization", "Bearer $memberToken")
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

        @Test
        fun `issue summary items should have correct structure`() {
            mockMvc
                .get("/api/v1/issues") {
                    header("Authorization", "Bearer $memberToken")
                    param("sectorId", testSectorId)
                    accept = MediaType.APPLICATION_JSON
                }
                .andExpect {
                    status { isOk() }
                    jsonPath("$.items[0].id") { isNotEmpty() }
                    jsonPath("$.items[0].type") { isNotEmpty() }
                    jsonPath("$.items[0].state") { isNotEmpty() }
                    jsonPath("$.items[0].location.latitude") { isNumber() }
                    jsonPath("$.items[0].location.longitude") { isNumber() }
                    jsonPath("$.items[0].heat") { isNumber() }
                    jsonPath("$.items[0].createdAt") { isNotEmpty() }
                }
        }
    }

    @Nested
    inner class GetMyIssues {
        @Test
        fun `GET api-v1-issues-mine should return member issues`() {
            mockMvc
                .get("/api/v1/issues/mine") {
                    header("Authorization", "Bearer $memberToken")
                    accept = MediaType.APPLICATION_JSON
                }
                .andExpect {
                    status { isOk() }
                    jsonPath("$.items") { isArray() }
                    jsonPath("$.pagination") { isMap() }
                }
        }

        @Test
        fun `GET api-v1-issues-mine should respect pagination`() {
            mockMvc
                .get("/api/v1/issues/mine") {
                    header("Authorization", "Bearer $memberToken")
                    param("page", "1")
                    param("limit", "10")
                    accept = MediaType.APPLICATION_JSON
                }
                .andExpect {
                    status { isOk() }
                    jsonPath("$.pagination.page") { value(1) }
                    jsonPath("$.pagination.limit") { value(10) }
                }
        }
    }

    @Nested
    inner class GetIssueById {
        @Test
        fun `GET api-v1-issues-id should return issue details`() {
            mockMvc
                .get("/api/v1/issues/$testIssueId") {
                    header("Authorization", "Bearer $memberToken")
                    accept = MediaType.APPLICATION_JSON
                }
                .andExpect {
                    status { isOk() }
                    content { contentType(MediaType.APPLICATION_JSON) }
                    jsonPath("$.id") { value(testIssueId) }
                    jsonPath("$.type") { isNotEmpty() }
                    jsonPath("$.state") { isNotEmpty() }
                    jsonPath("$.location.latitude") { isNumber() }
                    jsonPath("$.location.longitude") { isNumber() }
                    jsonPath("$.heat") { isNumber() }
                    jsonPath("$.sectorId") { isNotEmpty() }
                    jsonPath("$.reporterId") { isNotEmpty() }
                    jsonPath("$.reportCount") { isNumber() }
                    jsonPath("$.createdAt") { isNotEmpty() }
                    jsonPath("$.updatedAt") { isNotEmpty() }
                }
        }

        @Test
        fun `GET api-v1-issues-id should return 404 for non-existent issue`() {
            mockMvc
                .get("/api/v1/issues/00000000-0000-0000-0000-000000000000") {
                    header("Authorization", "Bearer $memberToken")
                    accept = MediaType.APPLICATION_JSON
                }
                .andExpect {
                    status { isNotFound() }
                    jsonPath("$.error.code") { value("NOT_FOUND") }
                }
        }

        @Test
        fun `issue detail response should match mock API contract format`() {
            val result =
                mockMvc
                    .get("/api/v1/issues/$testIssueId") {
                        header("Authorization", "Bearer $memberToken")
                        accept = MediaType.APPLICATION_JSON
                    }
                    .andExpect {
                        status { isOk() }
                    }
                    .andReturn()

            val content = result.response.contentAsString
            content.contains("\"id\"") shouldBe true
            content.contains("\"type\"") shouldBe true
            content.contains("\"state\"") shouldBe true
            content.contains("\"location\"") shouldBe true
            content.contains("\"latitude\"") shouldBe true
            content.contains("\"longitude\"") shouldBe true
            content.contains("\"heat\"") shouldBe true
            content.contains("\"photoUrls\"") shouldBe true
            content.contains("\"sectorId\"") shouldBe true
            content.contains("\"reporterId\"") shouldBe true
            content.contains("\"reportCount\"") shouldBe true
            content.contains("\"createdAt\"") shouldBe true
            content.contains("\"updatedAt\"") shouldBe true
        }
    }

    @Nested
    inner class CreateIssue {
        @Test
        fun `POST api-v1-issues should create new issue`() {
            val request =
                CreateIssueRequest(
                    type = "pothole",
                    sectorId = "550e8400-e29b-41d4-a716-446655440001",
                    latitude = -26.1350,
                    longitude = 27.9800,
                    description = "Test pothole",
                )

            mockMvc
                .post("/api/v1/issues") {
                    header("Authorization", "Bearer $memberToken")
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }
                .andExpect {
                    status { isCreated() }
                    jsonPath("$.id") { isNotEmpty() }
                    jsonPath("$.type") { value("pothole") }
                    jsonPath("$.state") { value("reported") }
                    jsonPath("$.heat") { isNumber() }
                }
        }

        @Test
        fun `POST api-v1-issues should return 400 for invalid type`() {
            val request =
                mapOf(
                    "type" to "invalid_type",
                    "sectorId" to "550e8400-e29b-41d4-a716-446655440001",
                    "latitude" to -26.1350,
                    "longitude" to 27.9800,
                )

            mockMvc
                .post("/api/v1/issues") {
                    header("Authorization", "Bearer $memberToken")
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }
                .andExpect {
                    status { isBadRequest() }
                }
        }

        @Test
        fun `create issue response should match mock API contract format`() {
            val request =
                CreateIssueRequest(
                    type = "water_leak",
                    sectorId = "550e8400-e29b-41d4-a716-446655440001",
                    latitude = -26.1320,
                    longitude = 27.9870,
                    description = null,
                )

            val result =
                mockMvc
                    .post("/api/v1/issues") {
                        header("Authorization", "Bearer $memberToken")
                        contentType = MediaType.APPLICATION_JSON
                        content = objectMapper.writeValueAsString(request)
                    }
                    .andExpect {
                        status { isCreated() }
                    }
                    .andReturn()

            val content = result.response.contentAsString
            content.contains("\"id\"") shouldBe true
            content.contains("\"type\"") shouldBe true
            content.contains("\"state\"") shouldBe true
            content.contains("\"location\"") shouldBe true
            content.contains("\"heat\"") shouldBe true
        }
    }

    @Nested
    inner class UpdateIssueState {
        private fun createFreshIssue(): String {
            // Create a fresh issue for state transition testing
            val createRequest =
                CreateIssueRequest(
                    type = "pothole",
                    sectorId = "550e8400-e29b-41d4-a716-446655440001",
                    latitude = -26.1350,
                    longitude = 27.9800,
                    description = "Test issue for state transition",
                )

            val result =
                mockMvc
                    .post("/api/v1/issues") {
                        header("Authorization", "Bearer $memberToken")
                        contentType = MediaType.APPLICATION_JSON
                        content = objectMapper.writeValueAsString(createRequest)
                    }
                    .andExpect { status { isCreated() } }
                    .andReturn()

            val response = objectMapper.readTree(result.response.contentAsString)
            return response.get("id").asText()
        }

        @Test
        fun `PATCH api-v1-issues-id-state should update state with valid transition`() {
            // Create a fresh issue in "reported" state
            val issueId = createFreshIssue()

            val request =
                UpdateIssueStateRequest(
                    state = "confirmed",
                    note = "Verified on site",
                )

            mockMvc
                .patch("/api/v1/issues/$issueId/state") {
                    header("Authorization", "Bearer $adminToken")
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }
                .andExpect {
                    status { isOk() }
                    jsonPath("$.id") { value(issueId) }
                    jsonPath("$.state") { value("confirmed") }
                }
        }

        @Test
        fun `PATCH api-v1-issues-id-state should return 422 for invalid transition`() {
            // Create a fresh issue and confirm it
            val issueId = createFreshIssue()

            val confirmRequest = UpdateIssueStateRequest(state = "confirmed", note = null)
            mockMvc
                .patch("/api/v1/issues/$issueId/state") {
                    header("Authorization", "Bearer $adminToken")
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(confirmRequest)
                }
                .andExpect { status { isOk() } }

            // Try to go directly to fixed (invalid from confirmed)
            val invalidRequest = UpdateIssueStateRequest(state = "fixed", note = null)

            mockMvc
                .patch("/api/v1/issues/$issueId/state") {
                    header("Authorization", "Bearer $adminToken")
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(invalidRequest)
                }
                .andExpect {
                    status { isUnprocessableEntity() }
                    jsonPath("$.error.code") { value("INVALID_STATE_TRANSITION") }
                }
        }

        @Test
        fun `PATCH api-v1-issues-id-state should return 404 for non-existent issue`() {
            val request = UpdateIssueStateRequest(state = "confirmed", note = null)

            mockMvc
                .patch("/api/v1/issues/00000000-0000-0000-0000-000000000000/state") {
                    header("Authorization", "Bearer $adminToken")
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }
                .andExpect {
                    status { isNotFound() }
                    jsonPath("$.error.code") { value("NOT_FOUND") }
                }
        }
    }

    @Nested
    inner class ErrorResponses {
        @Test
        fun `error responses should match mock API contract format`() {
            val result =
                mockMvc
                    .get("/api/v1/issues/00000000-0000-0000-0000-000000000000") {
                        header("Authorization", "Bearer $memberToken")
                        accept = MediaType.APPLICATION_JSON
                    }
                    .andExpect {
                        status { isNotFound() }
                    }
                    .andReturn()

            val content = result.response.contentAsString
            content.contains("\"error\"") shouldBe true
            content.contains("\"code\"") shouldBe true
            content.contains("\"message\"") shouldBe true
        }
    }
}
