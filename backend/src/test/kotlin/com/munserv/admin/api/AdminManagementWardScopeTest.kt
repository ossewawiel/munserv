package com.munserv.admin.api

import com.munserv.TestContainersConfig
import com.munserv.auth.service.JwtService
import com.munserv.sectors.repository.SectorRepository
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import com.munserv.shared.types.WardId
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc
import org.springframework.context.annotation.Import
import org.springframework.jdbc.core.JdbcTemplate
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.delete
import org.springframework.test.web.servlet.get
import org.springframework.transaction.annotation.Transactional
import java.sql.Timestamp
import java.util.UUID

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import(TestContainersConfig::class)
class AdminManagementWardScopeTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var jdbc: JdbcTemplate

    @Autowired
    private lateinit var jwtService: JwtService

    @Autowired
    private lateinit var sectorRepository: SectorRepository

    private val wardAdminId = "550e8400-e29b-41d4-a716-446655440034"
    private val sectorAdminId = "550e8400-e29b-41d4-a716-446655440020"
    private val northcliffSectorId = SectorId.fromString("550e8400-e29b-41d4-a716-446655440001")
    private val wardId = WardId.fromString("550e8400-e29b-41d4-a716-446655440030")

    private val wardAdminToken
        get() = jwtService.generateAccessToken(MemberId(UUID.fromString(wardAdminId)), "admin")

    @Test
    fun `should refuse list when sector has no ward`() {
        mockMvc
            .get("/api/v1/admins?sectorId={id}", northcliffSectorId.value) {
                header("Authorization", "Bearer $wardAdminToken")
            }.andExpect {
                status { isForbidden() }
                jsonPath("$.code") { value("cross_ward") }
            }
    }

    @Test
    fun `should refuse delete and keep admin when sector is outside ward`() {
        mockMvc
            .delete("/api/v1/admins/{id}", sectorAdminId) {
                header("Authorization", "Bearer $wardAdminToken")
            }.andExpect {
                status { isForbidden() }
                jsonPath("$.code") { value("cross_ward") }
            }

        val deletedAt =
            jdbc.queryForObject(
                "SELECT deleted_at FROM admins WHERE id = ?",
                Timestamp::class.java,
                UUID.fromString(sectorAdminId),
            )
        deletedAt shouldBe null
    }

    @Test
    @Transactional
    fun `should list admins when sector is in actor's ward`() {
        val sector = requireNotNull(sectorRepository.findById(northcliffSectorId))
        sectorRepository.save(sector.copy(wardId = wardId))

        mockMvc
            .get("/api/v1/admins?sectorId={id}", northcliffSectorId.value) {
                header("Authorization", "Bearer $wardAdminToken")
            }.andExpect {
                status { isOk() }
                content { string(org.hamcrest.Matchers.containsString("admin@ward42.example.com")) }
            }
    }
}
