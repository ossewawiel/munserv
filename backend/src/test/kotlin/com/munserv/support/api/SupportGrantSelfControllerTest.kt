package com.munserv.support.api

import com.munserv.TestContainersConfig
import com.munserv.admin.domain.AdminRole
import com.munserv.auth.service.JwtService
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.PodId
import com.munserv.support.domain.SupportGrant
import com.munserv.support.domain.SupportGrantId
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

@SpringBootTest
@Import(TestContainersConfig::class)
@AutoConfigureMockMvc
@ActiveProfiles("test")
class SupportGrantSelfControllerTest {
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
                supportGrantRepository.save(grant.revoked(Instant.now(), null))
            }
        }
        createdGrantId = null
    }

    @Test
    fun `should return the caller's own grant for a grant-scoped token`() {
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

        mockMvc
            .get("/api/v1/support-access/grants/current") {
                header("Authorization", "Bearer $grantToken")
            }.andExpect {
                status { isOk() }
                jsonPath("$.id") { value(grant.id.value.toString()) }
            }
    }

    @Test
    fun `should return 403 for a pod chief token`() {
        val podChiefToken = jwtService.generateAccessToken(MemberId(podChiefId.value), "admin")

        mockMvc
            .get("/api/v1/support-access/grants/current") {
                header("Authorization", "Bearer $podChiefToken")
            }.andExpect { status { isForbidden() } }
    }
}
