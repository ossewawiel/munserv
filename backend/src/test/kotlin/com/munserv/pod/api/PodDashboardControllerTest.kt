package com.munserv.pod.api

import com.munserv.TestContainersConfig
import com.munserv.admin.domain.Admin
import com.munserv.admin.domain.AdminRole
import com.munserv.admin.repository.AdminRepository
import com.munserv.auth.service.JwtService
import com.munserv.pod.domain.PodDashboardStats
import com.munserv.pod.domain.SectorDashboardStats
import com.munserv.pod.domain.WardDashboardStats
import com.munserv.pod.service.DashboardResult
import com.munserv.pod.service.PodDashboardService
import com.munserv.pod.service.PodResult
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.PodId
import com.munserv.shared.types.SectorId
import com.munserv.shared.types.WardId
import com.ninjasquad.springmockk.MockkBean
import io.mockk.every
import io.mockk.verify
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.context.annotation.Import
import org.springframework.http.MediaType
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import java.time.Instant
import java.util.UUID

@SpringBootTest
@Import(TestContainersConfig::class)
@AutoConfigureMockMvc
@ActiveProfiles("test")
class PodDashboardControllerTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var jwtService: JwtService

    @MockkBean
    private lateinit var dashboardService: PodDashboardService

    @MockkBean
    private lateinit var podIdResolver: PodIdResolver

    @MockkBean
    private lateinit var adminRepository: AdminRepository

    private val testPodId = PodId(UUID.fromString("550e8400-e29b-41d4-a716-446655440000"))
    private val testWardId = WardId(UUID.fromString("550e8400-e29b-41d4-a716-446655440001"))
    private val testSectorId = SectorId(UUID.fromString("550e8400-e29b-41d4-a716-446655440002"))
    private val testAdminId = AdminId.fromString("550e8400-e29b-41d4-a716-446655440020")
    private val fixedInstant = Instant.parse("2026-01-23T10:00:00Z")
    private lateinit var podChiefToken: String

    @BeforeEach
    fun setup() {
        // Generate a JWT token for the pod chief
        podChiefToken =
            jwtService.generateAccessToken(
                MemberId(testAdminId.value),
                "admin",
            )

        // Mock the pod ID resolver to return the test pod ID
        every { podIdResolver.resolvePodId(testAdminId) } returns testPodId

        // Mock the admin repository to return a pod chief (for role authorization)
        val podChief =
            Admin(
                id = testAdminId,
                podId = testPodId,
                email = "chief@example.com",
                displayName = "Test Pod Chief",
                role = AdminRole.POD_CHIEF,
                createdAt = fixedInstant,
                updatedAt = fixedInstant,
            )
        every { adminRepository.findById(testAdminId) } returns podChief
    }

    @Nested
    inner class GetPodDashboard {
        @Test
        fun `should return 200 with dashboard statistics`() {
            val stats =
                PodDashboardStats(
                    totalIssues = 150,
                    openIssues = 45,
                    resolvedThisMonth = 23,
                    pendingIssues = 12,
                    activeAdministrators = 5,
                    totalMembers = 1250,
                    activeGroundAdmins = 8,
                    wardCount = 4,
                    sectorCount = 16,
                )
            every { dashboardService.getPodStats(testPodId) } returns PodResult.Success(stats)

            mockMvc.get("/api/v1/pod/dashboard") {
                header("Authorization", "Bearer $podChiefToken")
                accept = MediaType.APPLICATION_JSON
            }.andExpect {
                status { isOk() }
                content { contentType(MediaType.APPLICATION_JSON) }
                jsonPath("$.totalIssues") { value(150) }
                jsonPath("$.openIssues") { value(45) }
                jsonPath("$.resolvedThisMonth") { value(23) }
                jsonPath("$.pendingIssues") { value(12) }
                jsonPath("$.activeAdministrators") { value(5) }
                jsonPath("$.totalMembers") { value(1250) }
                jsonPath("$.activeGroundAdmins") { value(8) }
                jsonPath("$.wardCount") { value(4) }
                jsonPath("$.sectorCount") { value(16) }
            }

            verify { dashboardService.getPodStats(testPodId) }
        }

        @Test
        fun `should return 200 with zero counts for empty pod`() {
            val stats =
                PodDashboardStats(
                    totalIssues = 0,
                    openIssues = 0,
                    resolvedThisMonth = 0,
                    pendingIssues = 0,
                    activeAdministrators = 0,
                    totalMembers = 0,
                    activeGroundAdmins = 0,
                    wardCount = 0,
                    sectorCount = 0,
                )
            every { dashboardService.getPodStats(testPodId) } returns PodResult.Success(stats)

            mockMvc.get("/api/v1/pod/dashboard") {
                header("Authorization", "Bearer $podChiefToken")
                accept = MediaType.APPLICATION_JSON
            }.andExpect {
                status { isOk() }
                jsonPath("$.totalIssues") { value(0) }
                jsonPath("$.wardCount") { value(0) }
            }
        }

        @Test
        fun `should return 404 when pod not found`() {
            every { dashboardService.getPodStats(testPodId) } returns PodResult.NotFound(testPodId)

            mockMvc.get("/api/v1/pod/dashboard") {
                header("Authorization", "Bearer $podChiefToken")
                accept = MediaType.APPLICATION_JSON
            }.andExpect {
                status { isNotFound() }
            }
        }
    }

    @Nested
    inner class GetWardDashboard {
        @Test
        fun `should return 200 with ward statistics`() {
            val stats =
                WardDashboardStats(
                    wardId = testWardId,
                    wardName = "Ward 42",
                    totalIssues = 45,
                    openIssues = 15,
                    resolvedThisMonth = 8,
                    sectorCount = 4,
                    activeGroundAdmins = 3,
                )
            every { dashboardService.getWardStats(testWardId) } returns DashboardResult.Success(stats)

            mockMvc.get("/api/v1/pod/dashboard/wards/${testWardId.value}") {
                header("Authorization", "Bearer $podChiefToken")
                accept = MediaType.APPLICATION_JSON
            }.andExpect {
                status { isOk() }
                content { contentType(MediaType.APPLICATION_JSON) }
                jsonPath("$.wardId") { value(testWardId.value.toString()) }
                jsonPath("$.wardName") { value("Ward 42") }
                jsonPath("$.totalIssues") { value(45) }
                jsonPath("$.openIssues") { value(15) }
                jsonPath("$.resolvedThisMonth") { value(8) }
                jsonPath("$.sectorCount") { value(4) }
                jsonPath("$.activeGroundAdmins") { value(3) }
            }

            verify { dashboardService.getWardStats(testWardId) }
        }

        @Test
        fun `should return 404 when ward not found`() {
            every { dashboardService.getWardStats(testWardId) } returns DashboardResult.WardNotFound(testWardId)

            mockMvc.get("/api/v1/pod/dashboard/wards/${testWardId.value}") {
                header("Authorization", "Bearer $podChiefToken")
                accept = MediaType.APPLICATION_JSON
            }.andExpect {
                status { isNotFound() }
            }
        }

        @Test
        fun `should return 400 for invalid UUID format`() {
            mockMvc.get("/api/v1/pod/dashboard/wards/invalid-uuid") {
                header("Authorization", "Bearer $podChiefToken")
                accept = MediaType.APPLICATION_JSON
            }.andExpect {
                status { isBadRequest() }
            }
        }
    }

    @Nested
    inner class GetSectorDashboard {
        @Test
        fun `should return 200 with sector statistics`() {
            val stats =
                SectorDashboardStats(
                    sectorId = testSectorId,
                    sectorName = "Sector A",
                    totalIssues = 25,
                    openIssues = 8,
                    resolvedThisMonth = 5,
                    activeGroundAdmins = 2,
                    totalMembers = 320,
                )
            every { dashboardService.getSectorStats(testSectorId) } returns DashboardResult.Success(stats)

            mockMvc.get("/api/v1/pod/dashboard/sectors/${testSectorId.value}") {
                header("Authorization", "Bearer $podChiefToken")
                accept = MediaType.APPLICATION_JSON
            }.andExpect {
                status { isOk() }
                content { contentType(MediaType.APPLICATION_JSON) }
                jsonPath("$.sectorId") { value(testSectorId.value.toString()) }
                jsonPath("$.sectorName") { value("Sector A") }
                jsonPath("$.totalIssues") { value(25) }
                jsonPath("$.openIssues") { value(8) }
                jsonPath("$.resolvedThisMonth") { value(5) }
                jsonPath("$.activeGroundAdmins") { value(2) }
                jsonPath("$.totalMembers") { value(320) }
            }

            verify { dashboardService.getSectorStats(testSectorId) }
        }

        @Test
        fun `should return 404 when sector not found`() {
            every { dashboardService.getSectorStats(testSectorId) } returns DashboardResult.SectorNotFound(testSectorId)

            mockMvc.get("/api/v1/pod/dashboard/sectors/${testSectorId.value}") {
                header("Authorization", "Bearer $podChiefToken")
                accept = MediaType.APPLICATION_JSON
            }.andExpect {
                status { isNotFound() }
            }
        }

        @Test
        fun `should return 400 for invalid UUID format`() {
            mockMvc.get("/api/v1/pod/dashboard/sectors/invalid-uuid") {
                header("Authorization", "Bearer $podChiefToken")
                accept = MediaType.APPLICATION_JSON
            }.andExpect {
                status { isBadRequest() }
            }
        }
    }
}
