package com.munserv.sectors.api

import com.munserv.TestContainersConfig
import com.munserv.admin.domain.Admin
import com.munserv.admin.domain.AdminRole
import com.munserv.admin.repository.AdminRepository
import com.munserv.auth.service.JwtService
import com.munserv.sectors.domain.SectorSettings
import com.munserv.sectors.service.SectorSettingsResult
import com.munserv.sectors.service.SectorSettingsService
import com.munserv.sectors.service.UpdateSectorSettingsCommand
import com.munserv.shared.enums.VerificationMode
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import com.munserv.shared.types.SectorSettingsId
import com.ninjasquad.springmockk.MockkBean
import io.mockk.every
import io.mockk.slot
import io.mockk.verify
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc
import org.springframework.context.annotation.Import
import org.springframework.http.MediaType
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.patch
import java.time.Instant
import java.util.UUID

@SpringBootTest
@Import(TestContainersConfig::class)
@AutoConfigureMockMvc
@ActiveProfiles("test")
class SectorSettingsControllerTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var jwtService: JwtService

    @MockkBean
    private lateinit var settingsService: SectorSettingsService

    @MockkBean
    private lateinit var adminRepository: AdminRepository

    private val testSectorId = UUID.fromString("550e8400-e29b-41d4-a716-446655440001")
    private val testSettingsId = SectorSettingsId(UUID.fromString("550e8400-e29b-41d4-a716-446655440010"))
    private val testAdminId = AdminId.fromString("550e8400-e29b-41d4-a716-446655440020")
    private val fixedInstant = Instant.parse("2025-01-15T10:00:00Z")
    private lateinit var sectorChiefToken: String

    @BeforeEach
    fun setup() {
        // Generate a JWT token for the sector chief
        sectorChiefToken =
            jwtService.generateAccessToken(
                MemberId(testAdminId.value),
                "admin",
            )

        // Mock the admin repository to return a sector chief
        val sectorChief =
            Admin(
                id = testAdminId,
                sectorId = SectorId(testSectorId),
                email = "chief@example.com",
                displayName = "Test Sector Chief",
                role = AdminRole.SECTOR_CHIEF,
                createdAt = fixedInstant,
                updatedAt = fixedInstant,
            )
        every { adminRepository.findById(testAdminId) } returns sectorChief
    }

    private fun createTestSettings(
        sectorId: SectorId = SectorId(testSectorId),
        newIssueVerificationMode: VerificationMode = VerificationMode.ALL_NOTIFIED,
        fixVerificationMode: VerificationMode = VerificationMode.ALL_NOTIFIED,
        daysFixedBeforeClosed: Int = 7,
        minimumGroundAdmins: Int = 2,
    ) = SectorSettings(
        id = testSettingsId,
        sectorId = sectorId,
        newIssueVerificationMode = newIssueVerificationMode,
        fixVerificationMode = fixVerificationMode,
        daysFixedBeforeClosed = daysFixedBeforeClosed,
        minimumGroundAdmins = minimumGroundAdmins,
        createdAt = fixedInstant,
        updatedAt = fixedInstant,
    )

    @Nested
    inner class GetSettings {
        @Test
        fun `should return 200 with settings when sector exists`() {
            val settings = createTestSettings()
            every { settingsService.getSettings(any()) } returns SectorSettingsResult.Success(settings)

            mockMvc
                .get("/api/v1/sectors/$testSectorId/settings") {
                    header("Authorization", "Bearer $sectorChiefToken")
                    accept = MediaType.APPLICATION_JSON
                }.andExpect {
                    status { isOk() }
                    content { contentType(MediaType.APPLICATION_JSON) }
                    jsonPath("$.id") { value(testSettingsId.toString()) }
                    jsonPath("$.sectorId") { value(testSectorId.toString()) }
                    jsonPath("$.newIssueVerificationMode") { value("all_notified") }
                    jsonPath("$.fixVerificationMode") { value("all_notified") }
                    jsonPath("$.daysFixedBeforeClosed") { value(7) }
                    jsonPath("$.minimumGroundAdmins") { value(2) }
                }

            verify { settingsService.getSettings(SectorId(testSectorId)) }
        }

        @Test
        fun `should return 404 when sector not found`() {
            every { settingsService.getSettings(any()) } returns
                SectorSettingsResult.SectorNotFound(SectorId(testSectorId))

            mockMvc
                .get("/api/v1/sectors/$testSectorId/settings") {
                    header("Authorization", "Bearer $sectorChiefToken")
                    accept = MediaType.APPLICATION_JSON
                }.andExpect {
                    status { isNotFound() }
                }
        }
    }

    @Nested
    inner class UpdateSettings {
        @Test
        fun `should return 200 with updated settings`() {
            val updatedSettings =
                createTestSettings(
                    newIssueVerificationMode = VerificationMode.ADMIN_ASSIGNS,
                    daysFixedBeforeClosed = 14,
                )
            val commandSlot = slot<UpdateSectorSettingsCommand>()

            every {
                settingsService.updateSettings(
                    any(),
                    capture(commandSlot),
                )
            } returns SectorSettingsResult.Success(updatedSettings)

            mockMvc
                .patch("/api/v1/sectors/$testSectorId/settings") {
                    header("Authorization", "Bearer $sectorChiefToken")
                    contentType = MediaType.APPLICATION_JSON
                    content =
                        """
                        {
                            "newIssueVerificationMode": "ADMIN_ASSIGNS",
                            "daysFixedBeforeClosed": 14
                        }
                        """.trimIndent()
                }.andExpect {
                    status { isOk() }
                    content { contentType(MediaType.APPLICATION_JSON) }
                    jsonPath("$.newIssueVerificationMode") { value("admin_assigns") }
                    jsonPath("$.daysFixedBeforeClosed") { value(14) }
                }

            verify { settingsService.updateSettings(SectorId(testSectorId), any()) }
        }

        @Test
        fun `should return 400 when validation fails`() {
            every { settingsService.updateSettings(any(), any()) } returns
                SectorSettingsResult.ValidationError(
                    listOf(
                        "daysFixedBeforeClosed must be at least 1",
                    ),
                )

            mockMvc
                .patch("/api/v1/sectors/$testSectorId/settings") {
                    header("Authorization", "Bearer $sectorChiefToken")
                    contentType = MediaType.APPLICATION_JSON
                    content =
                        """
                        {
                            "daysFixedBeforeClosed": 0
                        }
                        """.trimIndent()
                }.andExpect {
                    status { isBadRequest() }
                    jsonPath("$.errors") { isArray() }
                    jsonPath("$.errors[0]") { value("daysFixedBeforeClosed must be at least 1") }
                }
        }

        @Test
        fun `should return 404 when sector not found on update`() {
            every { settingsService.updateSettings(any(), any()) } returns
                SectorSettingsResult.SectorNotFound(SectorId(testSectorId))

            mockMvc
                .patch("/api/v1/sectors/$testSectorId/settings") {
                    header("Authorization", "Bearer $sectorChiefToken")
                    contentType = MediaType.APPLICATION_JSON
                    content =
                        """
                        {
                            "daysFixedBeforeClosed": 14
                        }
                        """.trimIndent()
                }.andExpect {
                    status { isNotFound() }
                }
        }

        @Test
        fun `should accept partial update with single field`() {
            val updatedSettings = createTestSettings(minimumGroundAdmins = 5)
            val commandSlot = slot<UpdateSectorSettingsCommand>()

            every {
                settingsService.updateSettings(
                    any(),
                    capture(commandSlot),
                )
            } returns SectorSettingsResult.Success(updatedSettings)

            mockMvc
                .patch("/api/v1/sectors/$testSectorId/settings") {
                    header("Authorization", "Bearer $sectorChiefToken")
                    contentType = MediaType.APPLICATION_JSON
                    content =
                        """
                        {
                            "minimumGroundAdmins": 5
                        }
                        """.trimIndent()
                }.andExpect {
                    status { isOk() }
                    jsonPath("$.minimumGroundAdmins") { value(5) }
                }
        }

        @Test
        fun `should accept all verification modes`() {
            for (mode in VerificationMode.entries) {
                val updatedSettings = createTestSettings(newIssueVerificationMode = mode)
                every { settingsService.updateSettings(any(), any()) } returns
                    SectorSettingsResult.Success(updatedSettings)

                mockMvc
                    .patch("/api/v1/sectors/$testSectorId/settings") {
                        header("Authorization", "Bearer $sectorChiefToken")
                        contentType = MediaType.APPLICATION_JSON
                        content =
                            """
                            {
                                "newIssueVerificationMode": "${mode.toApiString()}"
                            }
                            """.trimIndent()
                    }.andExpect {
                        status { isOk() }
                        jsonPath("$.newIssueVerificationMode") { value(mode.toApiString()) }
                    }
            }
        }
    }
}
