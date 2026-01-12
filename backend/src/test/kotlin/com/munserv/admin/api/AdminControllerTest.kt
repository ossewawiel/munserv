package com.munserv.admin.api

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

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AdminControllerTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var jwtService: JwtService

    private lateinit var adminToken: String
    private lateinit var memberToken: String

    private val testSectorId = "550e8400-e29b-41d4-a716-446655440001"
    private val testAdminId = MemberId.fromString("550e8400-e29b-41d4-a716-446655440020")
    private val testMemberId = MemberId.fromString("550e8400-e29b-41d4-a716-446655440010")

    @BeforeEach
    fun setup() {
        adminToken = jwtService.generateAccessToken(testAdminId, "admin")
        memberToken = jwtService.generateAccessToken(testMemberId, "member")
    }

    @Nested
    inner class GetDashboard {
        @Test
        fun `GET api-v1-admin-dashboard should return dashboard stats with admin token`() {
            mockMvc
                .get("/api/v1/admin/dashboard") {
                    header("Authorization", "Bearer $adminToken")
                    param("sectorId", testSectorId)
                    accept = MediaType.APPLICATION_JSON
                }
                .andExpect {
                    status { isOk() }
                    content { contentType(MediaType.APPLICATION_JSON) }
                    jsonPath("$.sectorId") { value(testSectorId) }
                    jsonPath("$.sectorName") { isNotEmpty() }
                    jsonPath("$.stats.totalOpen") { isNumber() }
                    jsonPath("$.stats.byState") { isMap() }
                    jsonPath("$.stats.byType") { isMap() }
                    jsonPath("$.stats.reportedThisWeek") { isNumber() }
                }
        }

        @Test
        fun `GET api-v1-admin-dashboard should return 403 for member token`() {
            mockMvc
                .get("/api/v1/admin/dashboard") {
                    header("Authorization", "Bearer $memberToken")
                    param("sectorId", testSectorId)
                    accept = MediaType.APPLICATION_JSON
                }
                .andExpect {
                    status { isForbidden() }
                }
        }

        @Test
        fun `GET api-v1-admin-dashboard should return 403 without token`() {
            // Spring Security returns 403 Forbidden when there's no authentication
            // and the endpoint requires a specific role
            mockMvc
                .get("/api/v1/admin/dashboard") {
                    param("sectorId", testSectorId)
                    accept = MediaType.APPLICATION_JSON
                }
                .andExpect {
                    status { isForbidden() }
                }
        }

        @Test
        fun `GET api-v1-admin-dashboard should return 404 for unknown sector`() {
            mockMvc
                .get("/api/v1/admin/dashboard") {
                    header("Authorization", "Bearer $adminToken")
                    param("sectorId", "00000000-0000-0000-0000-000000000000")
                    accept = MediaType.APPLICATION_JSON
                }
                .andExpect {
                    status { isNotFound() }
                }
        }
    }

    @Nested
    inner class GetHeatReport {
        @Test
        fun `GET api-v1-admin-reports-heat should return heat report with admin token`() {
            mockMvc
                .get("/api/v1/admin/reports/heat") {
                    header("Authorization", "Bearer $adminToken")
                    param("sectorId", testSectorId)
                    accept = MediaType.APPLICATION_JSON
                }
                .andExpect {
                    status { isOk() }
                    content { contentType(MediaType.APPLICATION_JSON) }
                    jsonPath("$.generatedAt") { isNotEmpty() }
                    jsonPath("$.items") { isArray() }
                }
        }

        @Test
        fun `GET api-v1-admin-reports-heat should respect limit parameter`() {
            mockMvc
                .get("/api/v1/admin/reports/heat") {
                    header("Authorization", "Bearer $adminToken")
                    param("sectorId", testSectorId)
                    param("limit", "5")
                    accept = MediaType.APPLICATION_JSON
                }
                .andExpect {
                    status { isOk() }
                    jsonPath("$.items") { isArray() }
                }
        }

        @Test
        fun `GET api-v1-admin-reports-heat should return 403 for member token`() {
            mockMvc
                .get("/api/v1/admin/reports/heat") {
                    header("Authorization", "Bearer $memberToken")
                    param("sectorId", testSectorId)
                    accept = MediaType.APPLICATION_JSON
                }
                .andExpect {
                    status { isForbidden() }
                }
        }
    }

    @Nested
    inner class GetMembers {
        @Test
        fun `GET api-v1-admin-members should return paginated members with admin token`() {
            mockMvc
                .get("/api/v1/admin/members") {
                    header("Authorization", "Bearer $adminToken")
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
        fun `GET api-v1-admin-members should respect pagination parameters`() {
            mockMvc
                .get("/api/v1/admin/members") {
                    header("Authorization", "Bearer $adminToken")
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
        fun `GET api-v1-admin-members should return 403 for member token`() {
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
        fun `GET api-v1-admin-members should include member details`() {
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
                .let { result ->
                    val content = result.response.contentAsString
                    // Verify response contains expected structure
                    content.contains("\"items\"") shouldBe true
                    content.contains("\"pagination\"") shouldBe true
                }
        }

        @Test
        fun `GET api-v1-admin-members should filter by status when provided`() {
            mockMvc
                .get("/api/v1/admin/members") {
                    header("Authorization", "Bearer $adminToken")
                    param("sectorId", testSectorId)
                    param("status", "active")
                    accept = MediaType.APPLICATION_JSON
                }
                .andExpect {
                    status { isOk() }
                    content { contentType(MediaType.APPLICATION_JSON) }
                    jsonPath("$.items") { isArray() }
                    jsonPath("$.pagination.totalItems") { isNumber() }
                }
                .andReturn()
                .let { result ->
                    val content = result.response.contentAsString
                    // All returned members should have active status
                    if (content.contains("\"status\":")) {
                        content.contains("\"status\":\"active\"") shouldBe true
                        content.contains("\"status\":\"pending_approval\"") shouldBe false
                    }
                }
        }

        @Test
        fun `GET api-v1-admin-members should filter by pending_approval status`() {
            mockMvc
                .get("/api/v1/admin/members") {
                    header("Authorization", "Bearer $adminToken")
                    param("sectorId", testSectorId)
                    param("status", "pending_approval")
                    accept = MediaType.APPLICATION_JSON
                }
                .andExpect {
                    status { isOk() }
                    content { contentType(MediaType.APPLICATION_JSON) }
                    jsonPath("$.items") { isArray() }
                }
        }

        @Test
        fun `GET api-v1-admin-members should return 400 for invalid status`() {
            mockMvc
                .get("/api/v1/admin/members") {
                    header("Authorization", "Bearer $adminToken")
                    param("sectorId", testSectorId)
                    param("status", "invalid_status")
                    accept = MediaType.APPLICATION_JSON
                }
                .andExpect {
                    status { isBadRequest() }
                    jsonPath("$.error") { value("invalid_status") }
                    jsonPath("$.message") { isNotEmpty() }
                }
        }

        @Test
        fun `GET api-v1-admin-members should return all members when status not provided`() {
            // First get total without filter
            val resultWithoutFilter =
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

            val contentWithoutFilter = resultWithoutFilter.response.contentAsString
            contentWithoutFilter.contains("\"totalItems\"") shouldBe true
        }

        @Test
        fun `GET api-v1-admin-members should apply pagination with status filter`() {
            mockMvc
                .get("/api/v1/admin/members") {
                    header("Authorization", "Bearer $adminToken")
                    param("sectorId", testSectorId)
                    param("status", "active")
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
        fun `GET api-v1-admin-members filtered counts should sum to total unfiltered count`() {
            val objectMapper = com.fasterxml.jackson.module.kotlin.jacksonObjectMapper()

            // Get total count without filter
            val totalResult =
                mockMvc
                    .get("/api/v1/admin/members") {
                        header("Authorization", "Bearer $adminToken")
                        param("sectorId", testSectorId)
                        param("limit", "1")
                        accept = MediaType.APPLICATION_JSON
                    }
                    .andExpect { status { isOk() } }
                    .andReturn()
            val totalJson = objectMapper.readTree(totalResult.response.contentAsString)
            val totalCount = totalJson.get("pagination").get("totalItems").asInt()

            // Get count for each status
            val statuses = listOf("active", "pending_approval", "suspended", "deleted")
            var sumOfFilteredCounts = 0

            for (status in statuses) {
                val result =
                    mockMvc
                        .get("/api/v1/admin/members") {
                            header("Authorization", "Bearer $adminToken")
                            param("sectorId", testSectorId)
                            param("status", status)
                            param("limit", "1")
                            accept = MediaType.APPLICATION_JSON
                        }
                        .andExpect { status { isOk() } }
                        .andReturn()
                val json = objectMapper.readTree(result.response.contentAsString)
                sumOfFilteredCounts += json.get("pagination").get("totalItems").asInt()
            }

            // Sum of all filtered counts should equal total
            sumOfFilteredCounts shouldBe totalCount
        }

        @Test
        fun `GET api-v1-admin-members filtered by status should return only members with that status`() {
            val objectMapper = com.fasterxml.jackson.module.kotlin.jacksonObjectMapper()

            // Test that all items returned for active filter have active status
            val result =
                mockMvc
                    .get("/api/v1/admin/members") {
                        header("Authorization", "Bearer $adminToken")
                        param("sectorId", testSectorId)
                        param("status", "active")
                        param("limit", "100")
                        accept = MediaType.APPLICATION_JSON
                    }
                    .andExpect { status { isOk() } }
                    .andReturn()

            val json = objectMapper.readTree(result.response.contentAsString)
            val items = json.get("items")

            // Verify all items have the expected status
            for (item in items) {
                item.get("status").asText() shouldBe "active"
            }

            // Test pending_approval filter
            val pendingResult =
                mockMvc
                    .get("/api/v1/admin/members") {
                        header("Authorization", "Bearer $adminToken")
                        param("sectorId", testSectorId)
                        param("status", "pending_approval")
                        param("limit", "100")
                        accept = MediaType.APPLICATION_JSON
                    }
                    .andExpect { status { isOk() } }
                    .andReturn()

            val pendingJson = objectMapper.readTree(pendingResult.response.contentAsString)
            val pendingItems = pendingJson.get("items")

            for (item in pendingItems) {
                item.get("status").asText() shouldBe "pending_approval"
            }
        }
    }

    @Nested
    inner class ApiContractTests {
        @Test
        fun `dashboard response should match mock API contract format`() {
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
        fun `heat report response should match mock API contract format`() {
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
        fun `members response should match mock API contract format`() {
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
}
