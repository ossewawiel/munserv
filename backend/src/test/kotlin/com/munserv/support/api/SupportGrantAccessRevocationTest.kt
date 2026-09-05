package com.munserv.support.api

import com.munserv.TestContainersConfig
import com.munserv.admin.domain.AdminRole
import com.munserv.auth.service.JwtService
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.PodId
import com.munserv.support.domain.SupportGrant
import com.munserv.support.domain.SupportGrantId
import com.munserv.support.domain.SupportGrantStatus
import com.munserv.support.repository.SupportGrantRepository
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc
import org.springframework.context.annotation.Import
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import java.time.Instant

/**
 * Proves that [SupportGrantActivityFilter] enforces grant status on endpoints gated only by
 * `.authenticated()`, not just on `@RequireRole` controllers. Without this, a revoked or expired
 * grant would keep serving those endpoints for the remaining life of the access token.
 */
@SpringBootTest
@Import(TestContainersConfig::class)
@AutoConfigureMockMvc
@ActiveProfiles("test")
class SupportGrantAccessRevocationTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var jwtService: JwtService

    @Autowired
    private lateinit var supportGrantRepository: SupportGrantRepository

    // Pod Chief test account from V030 migration
    private val podChiefId = AdminId.fromString("550e8400-e29b-41d4-a716-446655440031")

    // Pod from V030 migration
    private val testPodId = PodId.fromString("550e8400-e29b-41d4-a716-446655440000")

    private var createdGrantId: SupportGrantId? = null

    @AfterEach
    fun tearDown() {
        // The pod allows only one active grant at a time; revoke ours so other test classes
        // sharing this Testcontainers database can create their own.
        createdGrantId?.let { id ->
            supportGrantRepository.findById(id)?.let { grant ->
                if (grant.status.canTransitionTo(SupportGrantStatus.REVOKED)) {
                    supportGrantRepository.save(grant.revoked(Instant.now(), null))
                }
            }
        }
        createdGrantId = null
    }

    @Test
    fun `a still-valid token for a revoked grant is refused on an authenticated-only endpoint`() {
        val grant =
            supportGrantRepository.save(
                SupportGrant.create(
                    id = SupportGrantId.generate(),
                    podId = testPodId,
                    grantedRole = AdminRole.POD_ADMIN,
                    purpose = "Investigate duplicate issue reports in sector 3",
                    grantedBy = podChiefId,
                    grantedAt = Instant.now(),
                ),
            )
        createdGrantId = grant.id
        val grantToken =
            jwtService.generateAccessToken(
                MemberId(grant.id.value),
                grant.grantedRole.toDbValue(),
                JwtService.SCOPE_SUPPORT_GRANT,
            )

        // Sanity: the token works before revocation.
        mockMvc
            .get("/api/v1/issues") {
                header("Authorization", "Bearer $grantToken")
            }.andExpect { status { isOk() } }

        // Revoke the grant directly, as the pod chief's DELETE endpoint would.
        supportGrantRepository.save(grant.revoked(Instant.now(), podChiefId))

        // The same bearer token must no longer reach an `.authenticated()`-only endpoint.
        // Spring Security returns 403 Forbidden for a request with no authentication set,
        // same as a request with no token at all (see MemberControllerTest).
        mockMvc
            .get("/api/v1/issues") {
                header("Authorization", "Bearer $grantToken")
            }.andExpect { status { isForbidden() } }
    }
}
