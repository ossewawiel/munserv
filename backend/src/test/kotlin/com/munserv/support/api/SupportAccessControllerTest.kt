package com.munserv.support.api

import com.munserv.admin.domain.AdminRole
import com.munserv.auth.service.JwtService
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.PodId
import com.munserv.support.domain.SupportGrant
import com.munserv.support.domain.SupportGrantId
import com.munserv.support.service.SupportAccessResult
import com.munserv.support.service.SupportAccessService
import com.munserv.support.service.SupportGrantView
import com.ninjasquad.springmockk.MockkBean
import io.mockk.every
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.delete
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.post
import java.time.Instant
import java.util.UUID

@WebMvcTest(SupportAccessController::class)
@AutoConfigureMockMvc(addFilters = false)
@ActiveProfiles("test")
class SupportAccessControllerTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @MockkBean
    private lateinit var supportAccessService: SupportAccessService

    @MockkBean
    private lateinit var jwtService: JwtService

    private val testPodId = PodId(UUID.fromString("550e8400-e29b-41d4-a716-446655440000"))
    private val podChiefId = AdminId(UUID.fromString("550e8400-e29b-41d4-a716-446655440031"))
    private val grantId = SupportGrantId(UUID.fromString("550e8400-e29b-41d4-a716-446655440040"))

    private fun authenticateAsPodChief() {
        SecurityContextHolder.getContext().authentication =
            UsernamePasswordAuthenticationToken(
                podChiefId.value.toString(),
                null,
                listOf(SimpleGrantedAuthority("ROLE_POD_CHIEF")),
            )
    }

    @AfterEach
    fun tearDown() {
        SecurityContextHolder.clearContext()
    }

    private fun testGrant(): SupportGrant =
        SupportGrant.create(
            id = grantId,
            podId = testPodId,
            grantedRole = AdminRole.POD_ADMIN,
            purpose = "Investigate duplicate issue reports in sector 3",
            grantedBy = podChiefId,
            grantedAt = Instant.parse("2026-09-05T10:00:00Z"),
        )

    @Test
    fun `GET api-v1-support-access-grants should return 401 when not authenticated`() {
        mockMvc
            .get("/api/v1/support-access/grants")
            .andExpect { status { isUnauthorized() } }
    }

    @Test
    fun `GET api-v1-support-access-grants should return 200 with the grant list`() {
        authenticateAsPodChief()
        every { supportAccessService.list(podChiefId, null) } returns
            SupportAccessResult.Grants(listOf(SupportGrantView(testGrant(), "Thandi Mokoena")))

        mockMvc
            .get("/api/v1/support-access/grants")
            .andExpect {
                status { isOk() }
                jsonPath("$.total") { value(1) }
                jsonPath("$.items[0].grantedByName") { value("Thandi Mokoena") }
            }
    }

    @Test
    fun `GET api-v1-support-access-grants should return 403 when not authorized`() {
        authenticateAsPodChief()
        every { supportAccessService.list(podChiefId, null) } returns SupportAccessResult.NotAuthorized

        mockMvc
            .get("/api/v1/support-access/grants")
            .andExpect { status { isForbidden() } }
    }

    @Test
    fun `POST api-v1-support-access-grants should return 201 when created`() {
        authenticateAsPodChief()
        every { supportAccessService.grant(podChiefId, AdminRole.POD_ADMIN, "Investigate duplicate issue reports in sector 3") } returns
            SupportAccessResult.Granted(SupportGrantView(testGrant(), "Thandi Mokoena"))

        mockMvc
            .post("/api/v1/support-access/grants") {
                contentType = org.springframework.http.MediaType.APPLICATION_JSON
                content =
                    """{"grantedRole":"pod_admin","purpose":"Investigate duplicate issue reports in sector 3"}"""
            }.andExpect {
                status { isCreated() }
                jsonPath("$.status") { value("active") }
            }
    }

    @Test
    fun `POST api-v1-support-access-grants should return 400 on validation error`() {
        authenticateAsPodChief()
        every { supportAccessService.grant(podChiefId, AdminRole.POD_ADMIN, "short") } returns
            SupportAccessResult.ValidationError(listOf("Purpose must be between 10 and 500 characters"))

        mockMvc
            .post("/api/v1/support-access/grants") {
                contentType = org.springframework.http.MediaType.APPLICATION_JSON
                content = """{"grantedRole":"pod_admin","purpose":"short"}"""
            }.andExpect { status { isBadRequest() } }
    }

    @Test
    fun `POST api-v1-support-access-grants should return 409 when an active grant already exists`() {
        authenticateAsPodChief()
        every { supportAccessService.grant(podChiefId, AdminRole.POD_ADMIN, "Investigate duplicate issue reports in sector 3") } returns
            SupportAccessResult.ActiveGrantExists

        mockMvc
            .post("/api/v1/support-access/grants") {
                contentType = org.springframework.http.MediaType.APPLICATION_JSON
                content =
                    """{"grantedRole":"pod_admin","purpose":"Investigate duplicate issue reports in sector 3"}"""
            }.andExpect {
                status { isConflict() }
                jsonPath("$.code") { value("active_grant_exists") }
            }
    }

    @Test
    fun `DELETE api-v1-support-access-grants-id should return 204 when revoked`() {
        authenticateAsPodChief()
        every { supportAccessService.revoke(podChiefId, grantId) } returns SupportAccessResult.Revoked

        mockMvc
            .delete("/api/v1/support-access/grants/{id}", grantId.value)
            .andExpect { status { isNoContent() } }
    }

    @Test
    fun `DELETE api-v1-support-access-grants-id should return 404 when not found`() {
        authenticateAsPodChief()
        every { supportAccessService.revoke(podChiefId, grantId) } returns SupportAccessResult.NotFound

        mockMvc
            .delete("/api/v1/support-access/grants/{id}", grantId.value)
            .andExpect { status { isNotFound() } }
    }

    @Test
    fun `DELETE api-v1-support-access-grants-id should return 409 when grant is not active`() {
        authenticateAsPodChief()
        every { supportAccessService.revoke(podChiefId, grantId) } returns SupportAccessResult.GrantNotActive

        mockMvc
            .delete("/api/v1/support-access/grants/{id}", grantId.value)
            .andExpect {
                status { isConflict() }
                jsonPath("$.code") { value("grant_not_active") }
            }
    }
}
