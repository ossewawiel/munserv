package com.munserv.issues.api

import com.munserv.TestContainersConfig
import com.munserv.admin.domain.AdminRole
import com.munserv.auth.service.JwtService
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.PodId
import com.munserv.support.domain.SupportGrant
import com.munserv.support.domain.SupportGrantId
import com.munserv.support.repository.SupportGrantRepository
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.ValueSource
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc
import org.springframework.context.annotation.Import
import org.springframework.http.MediaType
import org.springframework.jdbc.core.JdbcTemplate
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.ResultActionsDsl
import org.springframework.test.web.servlet.patch
import org.springframework.test.web.servlet.post
import tools.jackson.databind.ObjectMapper
import java.time.Instant
import java.util.UUID

/**
 * Not @Transactional on purpose: the service transaction must commit so PostgreSQL runs the foreign key check.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import(TestContainersConfig::class)
class IssueAdminEndpointsAccessTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var jdbc: JdbcTemplate

    @Autowired
    private lateinit var jwtService: JwtService

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    @Autowired
    private lateinit var supportGrantRepository: SupportGrantRepository

    private val memberId = UUID.fromString("550e8400-e29b-41d4-a716-446655440010")
    private val groundAdminId = memberId
    private val podChiefId = AdminId.fromString("550e8400-e29b-41d4-a716-446655440031")
    private val testPodId = PodId.fromString("550e8400-e29b-41d4-a716-446655440000")

    private val memberToken get() = jwtService.generateAccessToken(MemberId(memberId), "member")
    private val createdIssues = mutableListOf<String>()
    private var createdGrantId: SupportGrantId? = null

    private fun makeGroundAdmin() {
        jdbc.update(
            "UPDATE members SET is_ground_admin = true, ground_admin_status = 'active'::ground_admin_status WHERE id = ?",
            groundAdminId,
        )
    }

    @AfterEach
    fun cleanUp() {
        jdbc.update("DELETE FROM messages WHERE recipient_id = ?", groundAdminId)
        createdIssues.forEach { id ->
            jdbc.update("DELETE FROM issue_verifications WHERE issue_id = ?", UUID.fromString(id))
        }
        createdIssues.clear()
        jdbc.update("UPDATE members SET is_ground_admin = false, ground_admin_status = NULL WHERE id = ?", groundAdminId)
        createdGrantId?.let { id ->
            supportGrantRepository.findById(id)?.let { grant ->
                supportGrantRepository.save(grant.revoked(Instant.now(), null))
            }
        }
        createdGrantId = null
    }

    private fun createFreshIssue(): String {
        val body =
            objectMapper.writeValueAsString(
                CreateIssueRequest(
                    type = "pothole",
                    sectorId = "550e8400-e29b-41d4-a716-446655440001",
                    latitude = -26.1350,
                    longitude = 27.9800,
                    description = "Test issue for admin endpoint access",
                ),
            )
        val result =
            mockMvc
                .post("/api/v1/issues") {
                    header("Authorization", "Bearer $memberToken")
                    contentType = MediaType.APPLICATION_JSON
                    content = body
                }.andExpect { status { isCreated() } }
                .andReturn()
        val id = objectMapper.readTree(result.response.contentAsString).get("id").asString()
        createdIssues.add(id)
        return id
    }

    private fun adminToken(id: String) = jwtService.generateAccessToken(MemberId(UUID.fromString(id)), "admin")

    private fun grantToken(): String {
        val grant =
            supportGrantRepository.save(
                SupportGrant.create(
                    id = SupportGrantId.generate(),
                    podId = testPodId,
                    grantedRole = AdminRole.SECTOR_ADMIN,
                    purpose = "Investigate duplicate issue reports in sector 3",
                    grantedBy = podChiefId,
                    grantedAt = Instant.now(),
                ),
            )
        createdGrantId = grant.id
        return jwtService.generateAccessToken(
            MemberId(grant.id.value),
            grant.grantedRole.toDbValue(),
            JwtService.SCOPE_SUPPORT_GRANT,
        )
    }

    private fun patchState(
        issueId: String,
        token: String?,
    ): ResultActionsDsl =
        mockMvc.patch("/api/v1/issues/$issueId/state") {
            token?.let { header("Authorization", "Bearer $it") }
            contentType = MediaType.APPLICATION_JSON
            content = """{"state":"confirmed"}"""
        }

    private fun requestVerification(
        issueId: String,
        token: String?,
    ): ResultActionsDsl =
        mockMvc.post("/api/v1/issues/$issueId/request-verification") {
            token?.let { header("Authorization", "Bearer $it") }
            contentType = MediaType.APPLICATION_JSON
            content = """{"type":"existence"}"""
        }

    private fun overrideState(
        issueId: String,
        token: String?,
    ): ResultActionsDsl =
        mockMvc.post("/api/v1/issues/$issueId/override-state") {
            token?.let { header("Authorization", "Bearer $it") }
            contentType = MediaType.APPLICATION_JSON
            content = """{"state":"fixed"}"""
        }

    private fun stateOf(issueId: String): String? =
        jdbc.queryForObject("SELECT state::text FROM issues WHERE id = ?", String::class.java, UUID.fromString(issueId))

    private fun historyRows(issueId: String): List<Map<String, Any?>> =
        jdbc.queryForList(
            "SELECT id, state::text AS state, changed_by FROM issue_state_history WHERE issue_id = ? ORDER BY id",
            UUID.fromString(issueId),
        )

    private fun verificationRows(issueId: String): List<Map<String, Any?>> =
        jdbc.queryForList(
            "SELECT id, status::text AS status FROM issue_verifications WHERE issue_id = ? ORDER BY id",
            UUID.fromString(issueId),
        )

    private fun confirmedChangedBy(issueId: String): UUID? =
        jdbc.queryForObject(
            "SELECT changed_by FROM issue_state_history WHERE issue_id = ? AND state = 'confirmed'::issue_state",
            UUID::class.java,
            UUID.fromString(issueId),
        )

    /**
     * Puts a pending verification on a fresh issue, calls the endpoint with the given token and checks the answer is 403
     * and that the issue state, the history rows and the verification rows are exactly as before the call.
     */
    private fun assertRefusedAndNothingChanged(
        token: String,
        call: (issueId: String, token: String?) -> ResultActionsDsl,
    ) {
        val issueId = createFreshIssue()
        requestVerification(issueId, adminToken(podChiefId.value.toString())).andExpect { status { isOk() } }
        val state = stateOf(issueId)
        val history = historyRows(issueId)
        val verifications = verificationRows(issueId)
        verifications.single()["status"] shouldBe "pending"

        call(issueId, token).andExpect {
            status { isForbidden() }
            jsonPath("$.error.code") { value("FORBIDDEN") }
        }

        stateOf(issueId) shouldBe state
        historyRows(issueId) shouldBe history
        verificationRows(issueId) shouldBe verifications
    }

    @Test
    fun `should answer 403 and change nothing when a member calls PATCH state`() {
        assertRefusedAndNothingChanged(memberToken, ::patchState)
    }

    @Test
    fun `should answer 403 and change nothing when a member calls request-verification`() {
        assertRefusedAndNothingChanged(memberToken, ::requestVerification)
    }

    @Test
    fun `should answer 403 and change nothing when a member calls override-state`() {
        assertRefusedAndNothingChanged(memberToken, ::overrideState)
    }

    @Test
    fun `should answer 403 and change nothing on all three when an active ground admin calls`() {
        makeGroundAdmin()

        assertRefusedAndNothingChanged(memberToken, ::patchState)
        assertRefusedAndNothingChanged(memberToken, ::requestVerification)
        assertRefusedAndNothingChanged(memberToken, ::overrideState)
    }

    @ParameterizedTest
    @ValueSource(
        strings = [
            "550e8400-e29b-41d4-a716-446655440020",
            "550e8400-e29b-41d4-a716-446655440021",
            "550e8400-e29b-41d4-a716-446655440034",
            "550e8400-e29b-41d4-a716-446655440033",
            "550e8400-e29b-41d4-a716-446655440032",
            "550e8400-e29b-41d4-a716-446655440031",
        ],
    )
    fun `should answer 200 on all three when the token is an admin`(adminId: String) {
        val token = adminToken(adminId)

        val patched = createFreshIssue()
        patchState(patched, token).andExpect { status { isOk() } }
        confirmedChangedBy(patched) shouldBe UUID.fromString(adminId)

        requestVerification(createFreshIssue(), token).andExpect { status { isOk() } }

        val overridden = createFreshIssue()
        overrideState(overridden, token).andExpect { status { isOk() } }
        stateOf(overridden) shouldBe "fixed"
    }

    @Test
    fun `should answer 200 with no changed_by when a support grant calls PATCH state`() {
        val token = grantToken()
        val issueId = createFreshIssue()

        patchState(issueId, token).andExpect { status { isOk() } }

        stateOf(issueId) shouldBe "confirmed"
        confirmedChangedBy(issueId) shouldBe null
    }

    @Test
    fun `should answer 200 when a support grant calls request-verification or override-state`() {
        val token = grantToken()

        requestVerification(createFreshIssue(), token).andExpect { status { isOk() } }
        overrideState(createFreshIssue(), token).andExpect { status { isOk() } }
    }

    @Test
    fun `should answer 401 on all three when no token is sent`() {
        val issueId = createFreshIssue()

        listOf(patchState(issueId, null), requestVerification(issueId, null), overrideState(issueId, null)).forEach {
            it.andExpect {
                status { isUnauthorized() }
                jsonPath("$.error.code") { value("UNAUTHENTICATED") }
            }
        }

        stateOf(issueId) shouldBe "reported"
    }
}
