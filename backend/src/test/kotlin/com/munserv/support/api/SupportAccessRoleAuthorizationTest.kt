package com.munserv.support.api

import com.munserv.TestContainersConfig
import com.munserv.auth.service.JwtService
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.MemberId
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc
import org.springframework.context.annotation.Import
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get

/**
 * Verifies that `@RequireRole(AdminRole.POD_CHIEF)` denials on [SupportAccessController]
 * surface as 403, not 500. Uses the real Spring Security filter chain and
 * [com.munserv.shared.security.RoleAuthorizationAspect], which `@WebMvcTest` does not load.
 */
@SpringBootTest
@Import(TestContainersConfig::class)
@AutoConfigureMockMvc
@ActiveProfiles("test")
class SupportAccessRoleAuthorizationTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var jwtService: JwtService

    // Pod Chief test account from V030 migration
    private val podChiefId = AdminId.fromString("550e8400-e29b-41d4-a716-446655440031")

    // Pod Admin test account from V030 migration
    private val podAdminId = AdminId.fromString("550e8400-e29b-41d4-a716-446655440032")

    @Test
    fun `GET api-v1-support-access-grants should return 403 for a non pod chief admin`() {
        val podAdminToken = jwtService.generateAccessToken(MemberId(podAdminId.value), "admin")

        mockMvc
            .get("/api/v1/support-access/grants") {
                header("Authorization", "Bearer $podAdminToken")
            }.andExpect { status { isForbidden() } }
    }

    @Test
    fun `GET api-v1-support-access-grants should return 200 for the pod chief`() {
        val podChiefToken = jwtService.generateAccessToken(MemberId(podChiefId.value), "admin")

        mockMvc
            .get("/api/v1/support-access/grants") {
                header("Authorization", "Bearer $podChiefToken")
            }.andExpect { status { isOk() } }
    }
}
