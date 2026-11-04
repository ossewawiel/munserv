package com.munserv.groundadmin.api

import com.munserv.TestContainersConfig
import com.munserv.admin.domain.AdminRole
import com.munserv.auth.domain.Member
import com.munserv.auth.repository.MemberRepository
import com.munserv.auth.service.JwtService
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.PodId
import com.munserv.shared.types.SectorId
import com.munserv.support.domain.SupportGrant
import com.munserv.support.domain.SupportGrantId
import com.munserv.support.repository.SupportGrantRepository
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach
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
import org.springframework.test.web.servlet.delete
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.patch
import org.springframework.test.web.servlet.post
import tools.jackson.databind.ObjectMapper
import java.time.Instant
import java.util.UUID

/**
 * Not @Transactional on purpose: the service transaction must commit so PostgreSQL runs the foreign keys and
 * ck_members_ground_admin_status.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import(TestContainersConfig::class)
class GroundAdminEndpointsAccessTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var jdbc: JdbcTemplate

    @Autowired
    private lateinit var jwtService: JwtService

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    @Autowired
    private lateinit var memberRepository: MemberRepository

    @Autowired
    private lateinit var supportGrantRepository: SupportGrantRepository

    private val sectorUuid = UUID.fromString("550e8400-e29b-41d4-a716-446655440001")
    private val plainMemberId = UUID.fromString("550e8400-e29b-41d4-a716-446655440010")
    private val sectorAdminId = "550e8400-e29b-41d4-a716-446655440020"
    private val podChiefId = AdminId.fromString("550e8400-e29b-41d4-a716-446655440031")
    private val testPodId = PodId.fromString("550e8400-e29b-41d4-a716-446655440000")

    private val targets = mutableListOf<UUID>()
    private val createdIssues = mutableListOf<UUID>()
    private var createdGrantId: SupportGrantId? = null
    private lateinit var startedAt: Instant

    private data class Prepared(
        val memberId: UUID,
        val applicationId: UUID?,
    )

    private enum class Call { INVITE, REVOKE_INVITATION, APPROVE, DECLINE, REVOKE, STATUS, LIST }

    @BeforeEach
    fun markStart() {
        startedAt = Instant.now()
    }

    @AfterEach
    fun cleanUp() {
        jdbc.update("DELETE FROM messages WHERE created_at >= ?", java.sql.Timestamp.from(startedAt))
        createdIssues.forEach {
            jdbc.update("DELETE FROM issue_verifications WHERE issue_id = ?", it)
            jdbc.update("DELETE FROM issue_state_history WHERE issue_id = ?", it)
            jdbc.update("DELETE FROM issue_photos WHERE issue_id = ?", it)
            jdbc.update("DELETE FROM issues WHERE id = ?", it)
        }
        createdIssues.clear()
        targets.forEach { id ->
            jdbc.update("DELETE FROM messages WHERE recipient_id = ?", id)
            jdbc.update("DELETE FROM ground_admin_applications WHERE member_id = ?", id)
            memberRepository.delete(MemberId(id))
        }
        targets.clear()
        createdGrantId?.let { id ->
            supportGrantRepository.findById(id)?.let { grant ->
                supportGrantRepository.save(grant.revoked(Instant.now(), null))
            }
        }
        createdGrantId = null
    }

    // ---------- tokens ----------

    private fun memberToken(id: UUID) = jwtService.generateAccessToken(MemberId(id), "member")

    private fun adminToken(id: String) = jwtService.generateAccessToken(MemberId(UUID.fromString(id)), "admin")

    private fun grantToken(): String {
        val grant =
            supportGrantRepository.save(
                SupportGrant.create(
                    id = SupportGrantId.generate(),
                    podId = testPodId,
                    grantedRole = AdminRole.SECTOR_ADMIN,
                    purpose = "Investigate ground admin management in sector 1",
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

    // ---------- set-up ----------

    private fun newTarget(): UUID {
        val id = UUID.randomUUID()
        memberRepository.save(
            Member(
                id = MemberId(id),
                sectorId = SectorId(sectorUuid),
                email = "ga-access-$id@test.example.com",
                emailHash = "hash-$id",
                passwordHash = null,
                phoneHash = null,
                pinHash = null,
                phone = "+27821234567",
                firstName = "Target",
                surname = "Member",
                address = "1 Test Street",
                registrationLocation = GeoPoint(27.9833, -26.1367),
            ),
        )
        targets.add(id)
        return id
    }

    private fun makeActiveGroundAdmin(id: UUID) {
        jdbc.update(
            "UPDATE members SET is_ground_admin = true, ground_admin_status = 'active'::ground_admin_status, " +
                "ground_admin_since = now() WHERE id = ?",
            id,
        )
    }

    private fun applicationIdOf(response: String): UUID = UUID.fromString(objectMapper.readTree(response).get("applicationId").asString())

    private fun applyFor(id: UUID): UUID {
        val result =
            mockMvc
                .post("/api/v1/members/me/ground-admin/apply") {
                    header("Authorization", "Bearer ${memberToken(id)}")
                }.andExpect { status { isOk() } }
                .andReturn()
        return applicationIdOf(result.response.contentAsString)
    }

    private fun inviteFor(id: UUID): UUID {
        val result =
            mockMvc
                .post("/api/v1/members/$id/ground-admin/invite") {
                    header("Authorization", "Bearer ${adminToken(sectorAdminId)}")
                    contentType = MediaType.APPLICATION_JSON
                    content = "{}"
                }.andExpect { status { isOk() } }
                .andReturn()
        return applicationIdOf(result.response.contentAsString)
    }

    private fun prepare(call: Call): Prepared {
        val id = newTarget()
        return when (call) {
            Call.INVITE -> {
                Prepared(id, null)
            }

            Call.REVOKE_INVITATION -> {
                Prepared(id, inviteFor(id))
            }

            Call.APPROVE, Call.DECLINE -> {
                Prepared(id, applyFor(id))
            }

            Call.REVOKE, Call.STATUS, Call.LIST -> {
                makeActiveGroundAdmin(id)
                Prepared(id, null)
            }
        }
    }

    // ---------- calls ----------

    private fun invoke(
        call: Call,
        p: Prepared,
        token: String?,
    ): ResultActionsDsl {
        val m = p.memberId
        return when (call) {
            Call.INVITE -> {
                post("/api/v1/members/$m/ground-admin/invite", token, "{}")
            }

            Call.REVOKE_INVITATION -> {
                mockMvc.delete("/api/v1/members/$m/ground-admin/invite/${p.applicationId}") {
                    token?.let { header("Authorization", "Bearer $it") }
                }
            }

            Call.APPROVE -> {
                post("/api/v1/members/$m/ground-admin/approve", token, """{"applicationId":"${p.applicationId}"}""")
            }

            Call.DECLINE -> {
                post("/api/v1/members/$m/ground-admin/decline", token, """{"applicationId":"${p.applicationId}","reason":"not now"}""")
            }

            Call.REVOKE -> {
                post("/api/v1/members/$m/ground-admin/revoke", token, """{"reason":"checking"}""")
            }

            Call.STATUS -> {
                mockMvc.patch("/api/v1/members/$m/ground-admin/status") {
                    token?.let { header("Authorization", "Bearer $it") }
                    contentType = MediaType.APPLICATION_JSON
                    content = """{"status":"on_hold"}"""
                }
            }

            Call.LIST -> {
                mockMvc.get("/api/v1/sectors/$sectorUuid/ground-admins") {
                    token?.let { header("Authorization", "Bearer $it") }
                }
            }
        }
    }

    private fun post(
        path: String,
        token: String?,
        body: String,
    ): ResultActionsDsl =
        mockMvc.post(path) {
            token?.let { header("Authorization", "Bearer $it") }
            contentType = MediaType.APPLICATION_JSON
            content = body
        }

    // ---------- snapshots ----------

    private fun snapshot(memberId: UUID): List<Any?> =
        listOf(
            jdbc.queryForList(
                "SELECT is_ground_admin, ground_admin_status::text AS s, ground_admin_since, ground_admin_response_rate, updated_at " +
                    "FROM members WHERE id = ?",
                memberId,
            ),
            jdbc.queryForList(
                "SELECT id, status, processed_by, invited_by, processed_at FROM ground_admin_applications WHERE member_id = ? ORDER BY id",
                memberId,
            ),
            jdbc.queryForObject("SELECT count(*) FROM messages", Long::class.java),
        )

    private fun memberRow(id: UUID): Map<String, Any?> =
        jdbc.queryForMap(
            "SELECT is_ground_admin, ground_admin_status::text AS s, ground_admin_since FROM members WHERE id = ?",
            id,
        )

    private fun applicationRow(id: UUID): Map<String, Any?> =
        jdbc.queryForMap("SELECT status, processed_by, invited_by FROM ground_admin_applications WHERE id = ?", id)

    private fun latestMessage(recipient: UUID): Map<String, Any?> =
        jdbc.queryForMap(
            "SELECT type::text AS type, sender_id, sender_type FROM messages WHERE recipient_id = ? ORDER BY created_at DESC LIMIT 1",
            recipient,
        )

    private fun assertRefused(
        call: Call,
        token: (Prepared) -> String,
    ) {
        val p = prepare(call)
        val before = snapshot(p.memberId)
        invoke(call, p, token(p)).andExpect {
            status { isForbidden() }
            jsonPath("$.error.code") { value("FORBIDDEN") }
        }
        snapshot(p.memberId) shouldBe before
    }

    // ---------- AC1 ----------

    @Test
    fun `should answer 403 and change nothing when a plain member calls`() {
        memberRow(plainMemberId)["is_ground_admin"] shouldBe false
        Call.entries.forEach { call -> assertRefused(call) { memberToken(plainMemberId) } }
    }

    @Test
    fun `should answer 403 and change nothing when an active ground admin calls`() {
        val gaId = newTarget()
        makeActiveGroundAdmin(gaId)
        Call.entries.forEach { call -> assertRefused(call) { memberToken(gaId) } }
    }

    @Test
    fun `should answer 403 when a member approves their own application`() {
        assertRefused(Call.APPROVE) { memberToken(it.memberId) }
    }

    @Test
    fun `should not send a phone number in the list`() {
        val p = prepare(Call.LIST)

        val body =
            invoke(Call.LIST, p, adminToken(sectorAdminId))
                .andExpect { status { isOk() } }
                .andReturn()
                .response.contentAsString

        val items = objectMapper.readTree(body).get("items")
        items.any { it.get("memberId").asString() == p.memberId.toString() } shouldBe true
        items.none { it.has("phone") } shouldBe true
    }

    // ---------- AC2 ----------

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
    fun `should answer 200 and record the admin when the token is an admin`(adminId: String) {
        val token = adminToken(adminId)
        val admin = UUID.fromString(adminId)

        val revokeInv = prepare(Call.REVOKE_INVITATION)
        invoke(Call.REVOKE_INVITATION, revokeInv, token).andExpect { status { isOk() } }
        applicationRow(requireNotNull(revokeInv.applicationId))["processed_by"] shouldBe admin

        val approve = prepare(Call.APPROVE)
        invoke(Call.APPROVE, approve, token).andExpect { status { isOk() } }
        applicationRow(requireNotNull(approve.applicationId))["processed_by"] shouldBe admin
        latestMessage(approve.memberId).let {
            it["sender_id"] shouldBe admin
            it["sender_type"] shouldBe "admin"
        }

        val decline = prepare(Call.DECLINE)
        invoke(Call.DECLINE, decline, token).andExpect { status { isOk() } }
        applicationRow(requireNotNull(decline.applicationId))["processed_by"] shouldBe admin
        latestMessage(decline.memberId).let {
            it["sender_id"] shouldBe admin
            it["sender_type"] shouldBe "admin"
        }

        val revoke = prepare(Call.REVOKE)
        invoke(Call.REVOKE, revoke, token).andExpect { status { isOk() } }
        latestMessage(revoke.memberId).let {
            it["sender_id"] shouldBe admin
            it["sender_type"] shouldBe "admin"
        }

        invoke(Call.STATUS, prepare(Call.STATUS), token).andExpect { status { isOk() } }
        invoke(Call.LIST, prepare(Call.LIST), token).andExpect { status { isOk() } }
    }

    @ParameterizedTest
    @ValueSource(
        strings = [
            "550e8400-e29b-41d4-a716-446655440020",
            "550e8400-e29b-41d4-a716-446655440021",
        ],
    )
    fun `should answer 200 and set invited_by when a sector admin or chief invites`(adminId: String) {
        val p = prepare(Call.INVITE)

        invoke(Call.INVITE, p, adminToken(adminId)).andExpect { status { isOk() } }

        jdbc.queryForObject(
            "SELECT invited_by FROM ground_admin_applications WHERE member_id = ?",
            UUID::class.java,
            p.memberId,
        ) shouldBe UUID.fromString(adminId)
        latestMessage(p.memberId).let {
            it["sender_id"] shouldBe UUID.fromString(adminId)
            it["sender_type"] shouldBe "admin"
        }
    }

    @ParameterizedTest
    @ValueSource(
        strings = [
            "550e8400-e29b-41d4-a716-446655440034",
            "550e8400-e29b-41d4-a716-446655440033",
            "550e8400-e29b-41d4-a716-446655440032",
            "550e8400-e29b-41d4-a716-446655440031",
        ],
    )
    fun `should keep answering 403 on invite when the admin is not in the sector`(adminId: String) {
        invoke(Call.INVITE, prepare(Call.INVITE), adminToken(adminId)).andExpect {
            status { isForbidden() }
            jsonPath("$.error.message") { value("Member not in your sector") }
        }
    }

    // ---------- AC3 ----------

    @Test
    fun `should answer 200 and record no admin when a support grant calls`() {
        val token = grantToken()

        val invite = prepare(Call.INVITE)
        invoke(Call.INVITE, invite, token).andExpect { status { isOk() } }
        jdbc.queryForObject(
            "SELECT invited_by FROM ground_admin_applications WHERE member_id = ?",
            UUID::class.java,
            invite.memberId,
        ) shouldBe null
        latestMessage(invite.memberId).let {
            it["sender_id"] shouldBe null
            it["sender_type"] shouldBe "system"
        }

        val revokeInv = prepare(Call.REVOKE_INVITATION)
        invoke(Call.REVOKE_INVITATION, revokeInv, token).andExpect { status { isOk() } }
        applicationRow(requireNotNull(revokeInv.applicationId))["processed_by"] shouldBe null

        listOf(Call.APPROVE, Call.DECLINE, Call.REVOKE).forEach { call ->
            val p = prepare(call)
            invoke(call, p, token).andExpect { status { isOk() } }
            p.applicationId?.let { applicationRow(it)["processed_by"] shouldBe null }
            latestMessage(p.memberId).let {
                it["sender_id"] shouldBe null
                it["sender_type"] shouldBe "system"
            }
        }

        invoke(Call.STATUS, prepare(Call.STATUS), token).andExpect { status { isOk() } }
        invoke(Call.LIST, prepare(Call.LIST), token).andExpect { status { isOk() } }
    }

    // ---------- AC4 ----------

    @Test
    fun `should answer 401 and change nothing when no token is sent`() {
        Call.entries.forEach { call ->
            val p = prepare(call)
            val before = snapshot(p.memberId)
            invoke(call, p, null).andExpect {
                status { isUnauthorized() }
                jsonPath("$.error.code") { value("UNAUTHENTICATED") }
            }
            snapshot(p.memberId) shouldBe before
        }
    }

    // ---------- AC5 ----------

    private fun listedStatus(
        memberId: UUID,
        token: String,
    ): String? {
        val body =
            mockMvc
                .get("/api/v1/sectors/$sectorUuid/ground-admins") {
                    header("Authorization", "Bearer $token")
                }.andExpect { status { isOk() } }
                .andReturn()
                .response.contentAsString
        return objectMapper
            .readTree(body)
            .get("items")
            .firstOrNull { it.get("memberId").asString() == memberId.toString() }
            ?.get("status")
            ?.asString()
    }

    private fun adminListedAsGroundAdmin(memberId: UUID): Boolean {
        val body =
            mockMvc
                .get("/api/v1/admin/members?sectorId=$sectorUuid&limit=100") {
                    header("Authorization", "Bearer ${adminToken(sectorAdminId)}")
                }.andExpect { status { isOk() } }
                .andReturn()
                .response.contentAsString
        return objectMapper
            .readTree(body)
            .get("items")
            .first { it.get("id").asString() == memberId.toString() }
            .get("isGroundAdmin")
            .asBoolean()
    }

    private fun memberCall(
        method: String,
        path: String,
        id: UUID,
        body: String = "{}",
    ): ResultActionsDsl =
        if (method == "GET") {
            mockMvc.get(path) { header("Authorization", "Bearer ${memberToken(id)}") }
        } else {
            post(path, memberToken(id), body)
        }

    @Test
    fun `should end the role with status inactive and let the member return when revoked`() {
        val admin = adminToken(sectorAdminId)
        val id = newTarget()
        makeActiveGroundAdmin(id)
        val since = memberRow(id)["ground_admin_since"]

        invoke(Call.REVOKE, Prepared(id, null), admin).andExpect { status { isOk() } }

        memberRow(id).let {
            it["is_ground_admin"] shouldBe true
            it["s"] shouldBe "inactive"
            it["ground_admin_since"] shouldBe since
        }
        latestMessage(id)["type"] shouldBe "ground_admin_revocation"
        listedStatus(id, admin) shouldBe "inactive"
        memberCall("GET", "/api/v1/members/me/ground-admin", id)
            .andExpect { status { isOk() } }
            .andReturn()
            .response.contentAsString shouldBe ""
        memberCall("POST", "/api/v1/members/me/ground-admin/stepdown", id, """{"reason":"x"}""")
            .andExpect { status { isConflict() } }
        invoke(Call.REVOKE, Prepared(id, null), admin).andExpect { status { isConflict() } }
        invoke(Call.STATUS, Prepared(id, null), admin).andExpect { status { isConflict() } }
        adminListedAsGroundAdmin(id) shouldBe false

        val applicationId = applyFor(id)
        invoke(Call.APPROVE, Prepared(id, applicationId), admin).andExpect { status { isOk() } }
        memberRow(id)["s"] shouldBe "active"

        invoke(Call.REVOKE, Prepared(id, null), admin).andExpect { status { isOk() } }
        val invitationId = inviteFor(id)
        memberCall("POST", "/api/v1/members/me/ground-admin/accept", id, """{"applicationId":"$invitationId"}""")
            .andExpect { status { isOk() } }
        memberRow(id)["s"] shouldBe "active"
    }

    @Test
    fun `should show no pending verifications to a revoked ground admin`() {
        val admin = adminToken(sectorAdminId)
        val id = newTarget()
        makeActiveGroundAdmin(id)
        val created =
            mockMvc
                .post("/api/v1/issues") {
                    header("Authorization", "Bearer ${memberToken(plainMemberId)}")
                    contentType = MediaType.APPLICATION_JSON
                    content =
                        """{"type":"pothole","sectorId":"$sectorUuid","latitude":-26.1350,"longitude":27.9800,"description":"verify me"}"""
                }.andExpect { status { isCreated() } }
                .andReturn()
        val issueId = UUID.fromString(objectMapper.readTree(created.response.contentAsString).get("id").asString())
        createdIssues.add(issueId)
        post("/api/v1/issues/$issueId/request-verification", adminToken(podChiefId.value.toString()), """{"type":"existence"}""")
            .andExpect { status { isOk() } }
        pendingCount(id) shouldBe 1

        invoke(Call.REVOKE, Prepared(id, null), admin).andExpect { status { isOk() } }

        pendingCount(id) shouldBe 0
    }

    private fun pendingCount(id: UUID): Int {
        val body =
            memberCall("GET", "/api/v1/members/me/pending-verifications", id)
                .andExpect { status { isOk() } }
                .andReturn()
                .response.contentAsString
        return objectMapper.readTree(body).get("items").size()
    }

    // ---------- AC6 ----------

    @Test
    fun `should answer 400 and change nothing when the status is inactive`() {
        val p = prepare(Call.STATUS)
        val before = snapshot(p.memberId)

        mockMvc
            .patch("/api/v1/members/${p.memberId}/ground-admin/status") {
                header("Authorization", "Bearer ${adminToken(sectorAdminId)}")
                contentType = MediaType.APPLICATION_JSON
                content = """{"status":"inactive"}"""
            }.andExpect {
                status { isBadRequest() }
                jsonPath("$.error.code") { value("VALIDATION_ERROR") }
            }

        snapshot(p.memberId) shouldBe before
    }

    // ---------- AC7 ----------

    @Test
    fun `should still let a plain member use the four own routes`() {
        val id = newTarget()
        memberCall("GET", "/api/v1/members/me/ground-admin", id).andExpect { status { isOk() } }
        val applicationId = applyFor(id)
        jdbc.update("DELETE FROM ground_admin_applications WHERE id = ?", applicationId)
        val fake = UUID.randomUUID()
        memberCall("POST", "/api/v1/members/me/ground-admin/accept", id, """{"applicationId":"$fake"}""")
            .andExpect { status { isNotFound() } }
        val invitationId = inviteFor(id)
        memberCall("POST", "/api/v1/members/me/ground-admin/decline", id, """{"applicationId":"$invitationId"}""")
            .andExpect { status { isOk() } }
        makeActiveGroundAdmin(id)
        memberCall("POST", "/api/v1/members/me/ground-admin/stepdown", id, """{"reason":"x"}""")
            .andExpect { status { isOk() } }
    }
}
