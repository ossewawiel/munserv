package com.munserv.pod.api

import com.munserv.TestContainersConfig
import com.munserv.admin.domain.Admin
import com.munserv.admin.domain.AdminRole
import com.munserv.admin.repository.AdminRepository
import com.munserv.auth.service.JwtService
import com.munserv.pod.domain.PodSettings
import com.munserv.pod.domain.PodSetupStatus
import com.munserv.pod.domain.SetupStep
import com.munserv.pod.service.PodLogoResult
import com.munserv.pod.service.PodLogoService
import com.munserv.pod.service.PodResult
import com.munserv.pod.service.PodService
import com.munserv.pod.service.UpdatePodSettingsCommand
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.PodId
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
import org.springframework.mock.web.MockMultipartFile
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.multipart
import org.springframework.test.web.servlet.patch
import java.time.Instant
import java.util.UUID

@SpringBootTest
@Import(TestContainersConfig::class)
@AutoConfigureMockMvc
@ActiveProfiles("test")
class PodControllerTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var jwtService: JwtService

    @MockkBean
    private lateinit var podService: PodService

    @MockkBean
    private lateinit var podIdResolver: PodIdResolver

    @MockkBean
    private lateinit var adminRepository: AdminRepository

    @MockkBean
    private lateinit var podLogoService: PodLogoService

    private val testPodId = PodId(UUID.fromString("550e8400-e29b-41d4-a716-446655440000"))
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

    private fun createTestSettings(
        podId: PodId = testPodId,
        name: String = "TestPod",
        displayName: String = "Munserv Pod TestPod",
        logoUrl: String? = null,
    ) = PodSettings(
        podId = podId,
        name = name,
        displayName = displayName,
        logoUrl = logoUrl,
        updatedAt = fixedInstant,
    )

    @Nested
    inner class GetSetupStatus {
        @Test
        fun `should return 200 with complete status when all steps done`() {
            every { podService.getSetupStatus(testPodId) } returns
                PodResult.Success(PodSetupStatus.Complete)

            mockMvc
                .get("/api/v1/pod/status") {
                    header("Authorization", "Bearer $podChiefToken")
                    accept = MediaType.APPLICATION_JSON
                }.andExpect {
                    status { isOk() }
                    content { contentType(MediaType.APPLICATION_JSON) }
                    jsonPath("$.isComplete") { value(true) }
                    jsonPath("$.missingSteps") { isArray() }
                    jsonPath("$.missingSteps.length()") { value(0) }
                }

            verify { podService.getSetupStatus(testPodId) }
        }

        @Test
        fun `should return 200 with incomplete status and missing steps`() {
            val missingSteps = listOf(SetupStep.POD_BOUNDARIES, SetupStep.FIRST_ADMIN)
            every { podService.getSetupStatus(testPodId) } returns
                PodResult.Success(PodSetupStatus.Incomplete(missingSteps))

            mockMvc
                .get("/api/v1/pod/status") {
                    header("Authorization", "Bearer $podChiefToken")
                    accept = MediaType.APPLICATION_JSON
                }.andExpect {
                    status { isOk() }
                    content { contentType(MediaType.APPLICATION_JSON) }
                    jsonPath("$.isComplete") { value(false) }
                    jsonPath("$.missingSteps") { isArray() }
                    jsonPath("$.missingSteps.length()") { value(2) }
                    jsonPath("$.missingSteps[0]") { value("pod_boundaries") }
                    jsonPath("$.missingSteps[1]") { value("first_admin") }
                }
        }

        @Test
        fun `should return 404 when pod not found`() {
            every { podService.getSetupStatus(testPodId) } returns
                PodResult.NotFound(testPodId)

            mockMvc
                .get("/api/v1/pod/status") {
                    header("Authorization", "Bearer $podChiefToken")
                    accept = MediaType.APPLICATION_JSON
                }.andExpect {
                    status { isNotFound() }
                }
        }
    }

    @Nested
    inner class GetSettings {
        @Test
        fun `should return 200 with settings`() {
            val settings = createTestSettings(logoUrl = "https://example.com/logo.png")
            every { podService.getSettings(testPodId) } returns PodResult.Success(settings)

            mockMvc
                .get("/api/v1/pod/settings") {
                    header("Authorization", "Bearer $podChiefToken")
                    accept = MediaType.APPLICATION_JSON
                }.andExpect {
                    status { isOk() }
                    content { contentType(MediaType.APPLICATION_JSON) }
                    jsonPath("$.name") { value("TestPod") }
                    jsonPath("$.displayName") { value("Munserv Pod TestPod") }
                    jsonPath("$.logoUrl") { value("https://example.com/logo.png") }
                }

            verify { podService.getSettings(testPodId) }
        }

        @Test
        fun `should return 200 with null logoUrl when not set`() {
            val settings = createTestSettings(logoUrl = null)
            every { podService.getSettings(testPodId) } returns PodResult.Success(settings)

            mockMvc
                .get("/api/v1/pod/settings") {
                    header("Authorization", "Bearer $podChiefToken")
                    accept = MediaType.APPLICATION_JSON
                }.andExpect {
                    status { isOk() }
                    jsonPath("$.logoUrl") { doesNotExist() }
                }
        }

        @Test
        fun `should return 404 when pod not found`() {
            every { podService.getSettings(testPodId) } returns PodResult.NotFound(testPodId)

            mockMvc
                .get("/api/v1/pod/settings") {
                    header("Authorization", "Bearer $podChiefToken")
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
                    name = "NewPodName",
                    displayName = "Munserv Pod NewPodName",
                )
            val commandSlot = slot<UpdatePodSettingsCommand>()

            every {
                podService.updateSettings(testPodId, capture(commandSlot))
            } returns PodResult.Success(updatedSettings)

            mockMvc
                .patch("/api/v1/pod/settings") {
                    header("Authorization", "Bearer $podChiefToken")
                    contentType = MediaType.APPLICATION_JSON
                    content =
                        """
                        {
                            "name": "NewPodName"
                        }
                        """.trimIndent()
                }.andExpect {
                    status { isOk() }
                    content { contentType(MediaType.APPLICATION_JSON) }
                    jsonPath("$.name") { value("NewPodName") }
                    jsonPath("$.displayName") { value("Munserv Pod NewPodName") }
                }

            verify { podService.updateSettings(testPodId, any()) }
            commandSlot.captured.name shouldBe "NewPodName"
        }

        @Test
        fun `should return 200 when updating logo`() {
            val updatedSettings =
                createTestSettings(
                    logoUrl = "https://example.com/new-logo.png",
                )

            every {
                podService.updateSettings(testPodId, any())
            } returns PodResult.Success(updatedSettings)

            mockMvc
                .patch("/api/v1/pod/settings") {
                    header("Authorization", "Bearer $podChiefToken")
                    contentType = MediaType.APPLICATION_JSON
                    content =
                        """
                        {
                            "logoUrl": "https://example.com/new-logo.png"
                        }
                        """.trimIndent()
                }.andExpect {
                    status { isOk() }
                    jsonPath("$.logoUrl") { value("https://example.com/new-logo.png") }
                }
        }

        @Test
        fun `should return 400 when validation fails from service`() {
            // Using a name that passes Spring @Valid (length 2-100) but fails domain validation
            every {
                podService.updateSettings(testPodId, any())
            } returns PodResult.ValidationError(listOf("Pod name is invalid"))

            mockMvc
                .patch("/api/v1/pod/settings") {
                    header("Authorization", "Bearer $podChiefToken")
                    contentType = MediaType.APPLICATION_JSON
                    content =
                        """
                        {
                            "name": "AA"
                        }
                        """.trimIndent()
                }.andExpect {
                    status { isBadRequest() }
                    jsonPath("$.code") { value("validation_error") }
                    jsonPath("$.message") { value("Pod name is invalid") }
                }
        }

        @Test
        fun `should return 400 when spring validation fails`() {
            // Empty name fails Spring @Size(min=2) validation
            mockMvc
                .patch("/api/v1/pod/settings") {
                    header("Authorization", "Bearer $podChiefToken")
                    contentType = MediaType.APPLICATION_JSON
                    content =
                        """
                        {
                            "name": ""
                        }
                        """.trimIndent()
                }.andExpect {
                    status { isBadRequest() }
                }
        }

        @Test
        fun `should return 404 when pod not found on update`() {
            every {
                podService.updateSettings(testPodId, any())
            } returns PodResult.NotFound(testPodId)

            mockMvc
                .patch("/api/v1/pod/settings") {
                    header("Authorization", "Bearer $podChiefToken")
                    contentType = MediaType.APPLICATION_JSON
                    content =
                        """
                        {
                            "name": "ValidName"
                        }
                        """.trimIndent()
                }.andExpect {
                    status { isNotFound() }
                }
        }

        @Test
        fun `should accept partial update with both fields`() {
            val updatedSettings =
                createTestSettings(
                    name = "UpdatedPod",
                    displayName = "Munserv Pod UpdatedPod",
                    logoUrl = "https://example.com/logo.png",
                )
            val commandSlot = slot<UpdatePodSettingsCommand>()

            every {
                podService.updateSettings(testPodId, capture(commandSlot))
            } returns PodResult.Success(updatedSettings)

            mockMvc
                .patch("/api/v1/pod/settings") {
                    header("Authorization", "Bearer $podChiefToken")
                    contentType = MediaType.APPLICATION_JSON
                    content =
                        """
                        {
                            "name": "UpdatedPod",
                            "logoUrl": "https://example.com/logo.png"
                        }
                        """.trimIndent()
                }.andExpect {
                    status { isOk() }
                    jsonPath("$.name") { value("UpdatedPod") }
                    jsonPath("$.logoUrl") { value("https://example.com/logo.png") }
                }

            commandSlot.captured.name shouldBe "UpdatedPod"
            commandSlot.captured.logoUrl shouldBe "https://example.com/logo.png"
        }
    }

    @Nested
    inner class UploadLogo {
        @Test
        fun `should return 200 with the logo url on a successful upload`() {
            val file =
                MockMultipartFile(
                    "file",
                    "logo.png",
                    MediaType.IMAGE_PNG_VALUE,
                    "logo content".toByteArray(),
                )

            every { podLogoService.uploadLogo(any()) } returns
                PodLogoResult.Success("http://localhost:8080/uploads/logo.png")

            mockMvc
                .multipart("/api/v1/pod/logo") {
                    file(file)
                    header("Authorization", "Bearer $podChiefToken")
                }.andExpect {
                    status { isOk() }
                    jsonPath("$.logoUrl") { value("http://localhost:8080/uploads/logo.png") }
                }

            verify { podLogoService.uploadLogo(any()) }
        }

        @Test
        fun `should return 400 when the file fails validation`() {
            val file =
                MockMultipartFile(
                    "file",
                    "logo.txt",
                    MediaType.TEXT_PLAIN_VALUE,
                    "not an image".toByteArray(),
                )

            every { podLogoService.uploadLogo(any()) } returns
                PodLogoResult.ValidationError(listOf("Invalid content type: text/plain"))

            mockMvc
                .multipart("/api/v1/pod/logo") {
                    file(file)
                    header("Authorization", "Bearer $podChiefToken")
                }.andExpect {
                    status { isBadRequest() }
                    jsonPath("$.code") { value("validation_error") }
                    jsonPath("$.message") { value("Invalid content type: text/plain") }
                }
        }

        @Test
        fun `should return 500 when storage fails`() {
            val file =
                MockMultipartFile(
                    "file",
                    "logo.png",
                    MediaType.IMAGE_PNG_VALUE,
                    "logo content".toByteArray(),
                )

            every { podLogoService.uploadLogo(any()) } returns
                PodLogoResult.StorageError("Disk full")

            mockMvc
                .multipart("/api/v1/pod/logo") {
                    file(file)
                    header("Authorization", "Bearer $podChiefToken")
                }.andExpect {
                    status { isInternalServerError() }
                    jsonPath("$.code") { value("internal_error") }
                    jsonPath("$.message") { value("Disk full") }
                }
        }

        @Test
        fun `should return 403 when the caller is not a pod chief`() {
            val podAdmin =
                Admin(
                    id = testAdminId,
                    podId = testPodId,
                    email = "admin@example.com",
                    displayName = "Test Pod Admin",
                    role = AdminRole.POD_ADMIN,
                    createdAt = fixedInstant,
                    updatedAt = fixedInstant,
                )
            every { adminRepository.findById(testAdminId) } returns podAdmin

            val file =
                MockMultipartFile(
                    "file",
                    "logo.png",
                    MediaType.IMAGE_PNG_VALUE,
                    "logo content".toByteArray(),
                )

            mockMvc
                .multipart("/api/v1/pod/logo") {
                    file(file)
                    header("Authorization", "Bearer $podChiefToken")
                }.andExpect {
                    status { isForbidden() }
                }
        }
    }

    private infix fun String?.shouldBe(expected: String?) {
        if (this != expected) {
            throw AssertionError("Expected '$expected' but got '$this'")
        }
    }
}
