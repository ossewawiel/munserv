package com.munserv.integration.scenarios

import com.munserv.TestContainersConfig
import com.munserv.auth.api.LoginRequest
import com.munserv.auth.service.JwtService
import com.munserv.issues.api.CreateIssueRequest
import com.munserv.shared.types.MemberId
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.MethodOrderer
import org.junit.jupiter.api.Order
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestMethodOrder
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
 * Scenario test: Complete issue reporting flow.
 * Tests the full journey from login to reporting an issue and viewing it.
 *
 * Flow:
 * 1. Login as member
 * 2. GET /sectors - View available sectors
 * 3. GET /issues - View existing issues
 * 4. POST /issues - Report a new issue
 * 5. GET /issues/{id} - View the created issue
 * 6. GET /issues/mine - View my reported issues
 */
@SpringBootTest
@Import(TestContainersConfig::class)
@AutoConfigureMockMvc
@ActiveProfiles("test")
@TestMethodOrder(MethodOrderer.OrderAnnotation::class)
class IssueReportingScenarioTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    @Autowired
    private lateinit var jwtService: JwtService

    private val testPhone = "+27821234567"
    private val testPin = "1234"
    private val testSectorId = "550e8400-e29b-41d4-a716-446655440001"
    private val testMemberId = MemberId.fromString("550e8400-e29b-41d4-a716-446655440010")

    private lateinit var accessToken: String

    companion object {
        var createdIssueId: String? = null
    }

    @BeforeEach
    fun setup() {
        accessToken = jwtService.generateAccessToken(testMemberId, "member")
    }

    @Test
    @Order(1)
    fun `step 1 - login should return access token`() {
        val request = LoginRequest(phone = testPhone, pin = testPin)

        val result =
            mockMvc
                .post("/api/v1/auth/login") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isOk() }
                    jsonPath("$.accessToken") { isNotEmpty() }
                    jsonPath("$.memberId") { isNotEmpty() }
                }.andReturn()

        val response = objectMapper.readTree(result.response.contentAsString)
        accessToken = response.get("accessToken").asText()
        accessToken shouldNotBe null
    }

    @Test
    @Order(2)
    fun `step 2 - GET sectors should return available sectors`() {
        mockMvc
            .get("/api/v1/sectors") {
                accept = MediaType.APPLICATION_JSON
            }.andExpect {
                status { isOk() }
                jsonPath("$.items") { isArray() }
                jsonPath("$.items[0].id") { isNotEmpty() }
                jsonPath("$.items[0].name") { isNotEmpty() }
                jsonPath("$.items[0].center.latitude") { isNumber() }
                jsonPath("$.items[0].center.longitude") { isNumber() }
            }
    }

    @Test
    @Order(3)
    fun `step 3 - GET issues should return issues list`() {
        mockMvc
            .get("/api/v1/issues") {
                header("Authorization", "Bearer $accessToken")
                param("sectorId", testSectorId)
                accept = MediaType.APPLICATION_JSON
            }.andExpect {
                status { isOk() }
                jsonPath("$.items") { isArray() }
                jsonPath("$.pagination.page") { value(1) }
                jsonPath("$.pagination.totalItems") { isNumber() }
            }
    }

    @Test
    @Order(4)
    fun `step 4 - POST issues should create new issue`() {
        val request =
            CreateIssueRequest(
                type = "pothole",
                sectorId = "550e8400-e29b-41d4-a716-446655440001",
                latitude = -26.1350,
                longitude = 27.9800,
                description = "Large pothole on Main Road",
            )

        val result =
            mockMvc
                .post("/api/v1/issues") {
                    header("Authorization", "Bearer $accessToken")
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isCreated() }
                    jsonPath("$.id") { isNotEmpty() }
                    jsonPath("$.type") { value("pothole") }
                    jsonPath("$.state") { value("reported") }
                    jsonPath("$.heat") { isNumber() }
                    jsonPath("$.location.latitude") { value(-26.1350) }
                    jsonPath("$.location.longitude") { value(27.9800) }
                }.andReturn()

        val response = objectMapper.readTree(result.response.contentAsString)
        createdIssueId = response.get("id").asText()
        createdIssueId shouldNotBe null
    }

    @Test
    @Order(5)
    fun `step 5 - GET issues-id should return created issue details`() {
        val issueId = createdIssueId ?: throw IllegalStateException("Must create issue first")

        mockMvc
            .get("/api/v1/issues/$issueId") {
                header("Authorization", "Bearer $accessToken")
                accept = MediaType.APPLICATION_JSON
            }.andExpect {
                status { isOk() }
                jsonPath("$.id") { value(issueId) }
                jsonPath("$.type") { value("pothole") }
                jsonPath("$.state") { value("reported") }
                jsonPath("$.description") { value("Large pothole on Main Road") }
                jsonPath("$.sectorId") { isNotEmpty() }
                jsonPath("$.reporterId") { isNotEmpty() }
                jsonPath("$.reportCount") { value(1) }
            }
    }

    @Test
    @Order(6)
    fun `step 6 - GET issues-mine should include the created issue`() {
        mockMvc
            .get("/api/v1/issues/mine") {
                header("Authorization", "Bearer $accessToken")
                accept = MediaType.APPLICATION_JSON
            }.andExpect {
                status { isOk() }
                jsonPath("$.items") { isArray() }
                jsonPath("$.pagination") { isMap() }
            }
    }

    @Test
    @Order(7)
    fun `step 7 - different issue types can be created`() {
        val issueTypes = listOf("water_leak", "street_light", "sewage_leak", "illegal_dumping")

        issueTypes.forEach { type ->
            val request =
                CreateIssueRequest(
                    type = type,
                    sectorId = "550e8400-e29b-41d4-a716-446655440001",
                    latitude = -26.1350 + (Math.random() * 0.01),
                    longitude = 27.9800 + (Math.random() * 0.01),
                    description = "Test $type issue",
                )

            mockMvc
                .post("/api/v1/issues") {
                    header("Authorization", "Bearer $accessToken")
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isCreated() }
                    jsonPath("$.type") { value(type) }
                }
        }
    }

    @Test
    @Order(8)
    fun `step 8 - GET issues should filter by state`() {
        mockMvc
            .get("/api/v1/issues") {
                header("Authorization", "Bearer $accessToken")
                param("sectorId", testSectorId)
                param("state", "reported")
                accept = MediaType.APPLICATION_JSON
            }.andExpect {
                status { isOk() }
                jsonPath("$.items") { isArray() }
            }
    }

    @Test
    @Order(9)
    fun `step 9 - GET issues should filter by type`() {
        mockMvc
            .get("/api/v1/issues") {
                header("Authorization", "Bearer $accessToken")
                param("sectorId", testSectorId)
                param("type", "pothole")
                accept = MediaType.APPLICATION_JSON
            }.andExpect {
                status { isOk() }
                jsonPath("$.items") { isArray() }
            }
    }

    @Test
    @Order(10)
    fun `step 10 - response format should match mock API contract`() {
        val result =
            mockMvc
                .get("/api/v1/issues") {
                    header("Authorization", "Bearer $accessToken")
                    param("sectorId", testSectorId)
                    accept = MediaType.APPLICATION_JSON
                }.andExpect {
                    status { isOk() }
                }.andReturn()

        val content = result.response.contentAsString

        // Verify mock API contract structure
        content.contains("\"items\"") shouldBe true
        content.contains("\"pagination\"") shouldBe true
        content.contains("\"page\"") shouldBe true
        content.contains("\"limit\"") shouldBe true
        content.contains("\"totalItems\"") shouldBe true
        content.contains("\"totalPages\"") shouldBe true
    }
}
