package com.munserv.pod.api

import com.munserv.TestContainersConfig
import com.munserv.admin.domain.Admin
import com.munserv.admin.domain.AdminRole
import com.munserv.admin.repository.AdminRepository
import com.munserv.admin.service.AdminManagementService
import com.munserv.admin.service.AdminResult
import com.munserv.auth.service.JwtService
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.PodId
import com.ninjasquad.springmockk.MockkBean
import io.mockk.every
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
import org.springframework.test.web.servlet.delete
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.patch
import org.springframework.test.web.servlet.post
import tools.jackson.databind.ObjectMapper
import java.time.Instant
import java.util.UUID

@SpringBootTest
@Import(TestContainersConfig::class)
@AutoConfigureMockMvc
@ActiveProfiles("test")
class PodAdministratorControllerTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    @Autowired
    private lateinit var jwtService: JwtService

    @MockkBean
    private lateinit var adminService: AdminManagementService

    @MockkBean
    private lateinit var podIdResolver: PodIdResolver

    @MockkBean
    private lateinit var adminRepository: AdminRepository

    private val testPodId = PodId(UUID.fromString("550e8400-e29b-41d4-a716-446655440000"))
    private val testAdminId = AdminId(UUID.fromString("550e8400-e29b-41d4-a716-446655440001"))
    private val otherAdminId = AdminId(UUID.fromString("550e8400-e29b-41d4-a716-446655440002"))
    private val now = Instant.parse("2026-01-22T10:00:00Z")
    private lateinit var podChiefToken: String

    private val testAdmin =
        Admin(
            id = otherAdminId,
            podId = testPodId,
            email = "wardadmin@example.com",
            displayName = "Ward Admin",
            role = AdminRole.WARD_ADMIN,
            createdAt = now,
            updatedAt = now,
        )

    private val podChief =
        Admin(
            id = testAdminId,
            podId = testPodId,
            email = "chief@example.com",
            displayName = "Pod Chief",
            role = AdminRole.POD_CHIEF,
            createdAt = now,
            updatedAt = now,
        )

    @BeforeEach
    fun setUp() {
        // Generate JWT token for pod chief
        podChiefToken =
            jwtService.generateAccessToken(
                MemberId(testAdminId.value),
                "admin",
            )

        // Mock pod ID resolver
        every { podIdResolver.resolvePodId(testAdminId) } returns testPodId

        // Mock admin repository for role authorization
        every { adminRepository.findById(testAdminId) } returns podChief
    }

    @Nested
    inner class ListAdministrators {
        @Test
        fun `should return 200 with list of administrators`() {
            val admins = listOf(testAdmin, podChief)
            every { adminService.listAdminsByPod(testPodId, testAdminId) } returns
                AdminResult.ListSuccess(admins, 2)

            mockMvc
                .get("/api/v1/pod/administrators") {
                    header("Authorization", "Bearer $podChiefToken")
                    accept = MediaType.APPLICATION_JSON
                }.andExpect {
                    status { isOk() }
                    jsonPath("$.total") { value(2) }
                    jsonPath("$.items[0].email") { value("wardadmin@example.com") }
                    jsonPath("$.items[0].role") { value("ward_admin") }
                }

            verify { adminService.listAdminsByPod(testPodId, testAdminId) }
        }

        @Test
        fun `should return 200 with empty list when no administrators`() {
            every { adminService.listAdminsByPod(testPodId, testAdminId) } returns
                AdminResult.ListSuccess(emptyList(), 0)

            mockMvc
                .get("/api/v1/pod/administrators") {
                    header("Authorization", "Bearer $podChiefToken")
                    accept = MediaType.APPLICATION_JSON
                }.andExpect {
                    status { isOk() }
                    jsonPath("$.total") { value(0) }
                    jsonPath("$.items") { isEmpty() }
                }
        }
    }

    @Nested
    inner class GetAdministrator {
        @Test
        fun `should return 200 when administrator found`() {
            every { adminService.getAdmin(otherAdminId, testAdminId) } returns
                AdminResult.Success(testAdmin)

            mockMvc
                .get("/api/v1/pod/administrators/${otherAdminId.value}") {
                    header("Authorization", "Bearer $podChiefToken")
                    accept = MediaType.APPLICATION_JSON
                }.andExpect {
                    status { isOk() }
                    jsonPath("$.email") { value("wardadmin@example.com") }
                    jsonPath("$.role") { value("ward_admin") }
                    jsonPath("$.displayName") { value("Ward Admin") }
                }
        }

        @Test
        fun `should return 404 when administrator not found`() {
            every { adminService.getAdmin(otherAdminId, testAdminId) } returns
                AdminResult.NotFound(otherAdminId)

            mockMvc
                .get("/api/v1/pod/administrators/${otherAdminId.value}") {
                    header("Authorization", "Bearer $podChiefToken")
                    accept = MediaType.APPLICATION_JSON
                }.andExpect {
                    status { isNotFound() }
                }
        }

        @Test
        fun `should return 403 when accessing admin in different pod`() {
            val otherPodId = PodId(UUID.fromString("550e8400-e29b-41d4-a716-446655440099"))
            every { adminService.getAdmin(otherAdminId, testAdminId) } returns
                AdminResult.CrossPodOperation(testPodId, otherPodId)

            mockMvc
                .get("/api/v1/pod/administrators/${otherAdminId.value}") {
                    header("Authorization", "Bearer $podChiefToken")
                    accept = MediaType.APPLICATION_JSON
                }.andExpect {
                    status { isForbidden() }
                    jsonPath("$.code") { value("cross_pod") }
                }
        }
    }

    @Nested
    inner class CreateAdministrator {
        @Test
        fun `should return 201 when administrator created`() {
            val createdAdmin =
                Admin(
                    id = AdminId.generate(),
                    podId = testPodId,
                    wardId =
                        com.munserv.shared.types
                            .WardId(UUID.fromString("550e8400-e29b-41d4-a716-446655440030")),
                    email = "newadmin@example.com",
                    displayName = "New Admin",
                    role = AdminRole.WARD_ADMIN,
                    createdAt = now,
                    updatedAt = now,
                )
            val tempPassword = "TempPass123"

            every { adminService.createAdmin(any(), testAdminId) } returns
                AdminResult.Created(createdAdmin, tempPassword)

            val request =
                mapOf(
                    "email" to "newadmin@example.com",
                    "displayName" to "New Admin",
                    "role" to "ward_admin",
                    "wardId" to "550e8400-e29b-41d4-a716-446655440030",
                )

            mockMvc
                .post("/api/v1/pod/administrators") {
                    header("Authorization", "Bearer $podChiefToken")
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isCreated() }
                    jsonPath("$.email") { value("newadmin@example.com") }
                    jsonPath("$.temporaryPassword") { value(tempPassword) }
                }
        }

        @Test
        fun `should return 409 when email already exists`() {
            every { adminService.createAdmin(any(), testAdminId) } returns
                AdminResult.EmailAlreadyExists("existing@example.com")

            val request =
                mapOf(
                    "email" to "existing@example.com",
                    "displayName" to "New Admin",
                    "role" to "ward_admin",
                    "wardId" to "550e8400-e29b-41d4-a716-446655440030",
                )

            mockMvc
                .post("/api/v1/pod/administrators") {
                    header("Authorization", "Bearer $podChiefToken")
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isConflict() }
                    jsonPath("$.code") { value("email_exists") }
                }
        }

        @Test
        fun `should return 400 when validation fails`() {
            every { adminService.createAdmin(any(), testAdminId) } returns
                AdminResult.ValidationError(listOf("Email is required"))

            val request =
                mapOf(
                    "email" to "",
                    "displayName" to "New Admin",
                    "role" to "ward_admin",
                )

            mockMvc
                .post("/api/v1/pod/administrators") {
                    header("Authorization", "Bearer $podChiefToken")
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isBadRequest() }
                    jsonPath("$.code") { value("validation_error") }
                }
        }

        @Test
        fun `should return 403 when insufficient permissions`() {
            every { adminService.createAdmin(any(), testAdminId) } returns
                AdminResult.InsufficientRoleToManage(AdminRole.POD_CHIEF, AdminRole.POD_CHIEF)

            val request =
                mapOf(
                    "email" to "newchief@example.com",
                    "displayName" to "Another Chief",
                    "role" to "pod_chief",
                    "podId" to testPodId.value.toString(),
                )

            mockMvc
                .post("/api/v1/pod/administrators") {
                    header("Authorization", "Bearer $podChiefToken")
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isForbidden() }
                    jsonPath("$.code") { value("insufficient_permissions") }
                }
        }
    }

    @Nested
    inner class UpdateAdministrator {
        @Test
        fun `should return 200 when administrator updated`() {
            val updatedAdmin = testAdmin.copy(displayName = "Updated Name")
            every { adminService.updateAdmin(otherAdminId, any(), testAdminId) } returns
                AdminResult.Success(updatedAdmin)

            val request = mapOf("displayName" to "Updated Name")

            mockMvc
                .patch("/api/v1/pod/administrators/${otherAdminId.value}") {
                    header("Authorization", "Bearer $podChiefToken")
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isOk() }
                    jsonPath("$.displayName") { value("Updated Name") }
                }
        }

        @Test
        fun `should return 404 when administrator not found`() {
            every { adminService.updateAdmin(otherAdminId, any(), testAdminId) } returns
                AdminResult.NotFound(otherAdminId)

            val request = mapOf("displayName" to "Updated Name")

            mockMvc
                .patch("/api/v1/pod/administrators/${otherAdminId.value}") {
                    header("Authorization", "Bearer $podChiefToken")
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isNotFound() }
                }
        }
    }

    @Nested
    inner class DeleteAdministrator {
        @Test
        fun `should return 204 when administrator deleted`() {
            every { adminService.deleteAdmin(otherAdminId, testAdminId) } returns
                AdminResult.Deleted

            mockMvc
                .delete("/api/v1/pod/administrators/${otherAdminId.value}") {
                    header("Authorization", "Bearer $podChiefToken")
                }.andExpect {
                    status { isNoContent() }
                }
        }

        @Test
        fun `should return 404 when administrator not found`() {
            every { adminService.deleteAdmin(otherAdminId, testAdminId) } returns
                AdminResult.NotFound(otherAdminId)

            mockMvc
                .delete("/api/v1/pod/administrators/${otherAdminId.value}") {
                    header("Authorization", "Bearer $podChiefToken")
                }.andExpect {
                    status { isNotFound() }
                }
        }

        @Test
        fun `should return 403 when deleting self`() {
            every { adminService.deleteAdmin(testAdminId, testAdminId) } returns
                AdminResult.CannotDeleteSelf

            mockMvc
                .delete("/api/v1/pod/administrators/${testAdminId.value}") {
                    header("Authorization", "Bearer $podChiefToken")
                }.andExpect {
                    status { isForbidden() }
                    jsonPath("$.code") { value("cannot_delete_self") }
                }
        }
    }
}
