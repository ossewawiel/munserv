package com.munserv.photos.api

import com.munserv.TestContainersConfig
import com.munserv.auth.service.JwtService
import com.munserv.issues.domain.Issue
import com.munserv.issues.domain.IssueId
import com.munserv.issues.domain.IssueState
import com.munserv.issues.domain.IssueType
import com.munserv.issues.service.IssueResult
import com.munserv.issues.service.IssueService
import com.munserv.photos.domain.IssuePhoto
import com.munserv.photos.domain.PhotoId
import com.munserv.photos.repository.IssuePhotoRepository
import com.munserv.photos.service.PhotoStorageService
import com.munserv.photos.service.PhotoValidationService
import com.munserv.photos.service.UploadResult
import com.munserv.photos.service.ValidationResult
import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import com.munserv.verification.service.VerificationService
import com.ninjasquad.springmockk.MockkBean
import io.mockk.every
import io.mockk.verify
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc
import org.springframework.context.annotation.Import
import org.springframework.http.MediaType
import org.springframework.mock.web.MockMultipartFile
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.delete
import org.springframework.test.web.servlet.multipart
import java.time.Instant

/**
 * End-to-end proof (real security chain, real IssuePhotoService) of who may add and delete photos.
 */
@SpringBootTest
@Import(TestContainersConfig::class)
@AutoConfigureMockMvc
@ActiveProfiles("test")
class PhotoAuthorizationTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var jwtService: JwtService

    @MockkBean
    private lateinit var issueService: IssueService

    @MockkBean
    private lateinit var verificationService: VerificationService

    @MockkBean
    private lateinit var photoRepository: IssuePhotoRepository

    @MockkBean
    private lateinit var storageService: PhotoStorageService

    @MockkBean
    private lateinit var validationService: PhotoValidationService

    private val reporterId = MemberId.generate()
    private val otherId = MemberId.generate()
    private val assignedGaId = MemberId.generate()
    private val otherGaId = MemberId.generate()
    private val adminId = MemberId.generate()
    private val issueId = IssueId.generate()
    private val photoId = PhotoId.generate()

    private fun token(
        id: MemberId,
        role: String = "member",
    ) = "Bearer " + jwtService.generateAccessToken(id, role)

    @BeforeEach
    fun setup() {
        val issue =
            Issue(
                id = issueId,
                sectorId = SectorId.generate(),
                reporterId = reporterId,
                type = IssueType.POTHOLE,
                state = IssueState.Reported,
                location = GeoPoint(-26.0, 28.0),
                address = null,
                description = null,
                heat = 10,
                reportCount = 1,
                createdAt = Instant.now(),
                updatedAt = Instant.now(),
            )
        val photo =
            IssuePhoto(
                id = photoId,
                issueId = issueId,
                url = "u",
                thumbnailUrl = "t",
                sortOrder = 0,
                createdAt = Instant.now(),
            )
        every { issueService.findById(issueId) } returns IssueResult.Success(issue)
        every { verificationService.mayVerify(issueId, assignedGaId) } returns true
        every { verificationService.mayVerify(issueId, otherGaId) } returns false
        every { verificationService.mayVerify(issueId, otherId) } returns false
        every { photoRepository.findById(photoId) } returns photo
        every { photoRepository.getNextSortOrder(issueId) } returns 0
        every { photoRepository.save(any()) } answers { firstArg() }
        every { photoRepository.deleteById(any()) } returns Unit
        every { storageService.delete(any()) } returns true
        every { storageService.store(any(), any()) } returns UploadResult.Success("u", "t")
        every { validationService.validate(any()) } returns ValidationResult.Valid
    }

    private fun upload(authorization: String?) =
        mockMvc.multipart("/api/v1/issues/${issueId.value}/photos") {
            file(MockMultipartFile("file", "t.jpg", MediaType.IMAGE_JPEG_VALUE, "x".toByteArray()))
            authorization?.let { header("Authorization", it) }
        }

    private fun delete(authorization: String?) =
        mockMvc.delete("/api/v1/photos/${photoId.value}") {
            authorization?.let { header("Authorization", it) }
        }

    @Test
    fun `anonymous DELETE should return 401`() {
        delete(null).andExpect { status { isUnauthorized() } }
    }

    @Test
    fun `another member DELETE should return 403`() {
        delete(token(otherId)).andExpect { status { isForbidden() } }
        verify(exactly = 0) { photoRepository.deleteById(any()) }
    }

    @Test
    fun `the reporter DELETE should return 204`() {
        delete(token(reporterId)).andExpect { status { isNoContent() } }
    }

    @Test
    fun `an admin DELETE should return 204`() {
        delete(token(adminId, "admin")).andExpect { status { isNoContent() } }
    }

    @Test
    fun `the assigned ground admin DELETE should return 403`() {
        delete(token(assignedGaId)).andExpect { status { isForbidden() } }
        verify(exactly = 0) { photoRepository.deleteById(any()) }
    }

    @Test
    fun `anonymous upload should return 401`() {
        upload(null).andExpect { status { isUnauthorized() } }
    }

    @Test
    fun `another member upload should return 403 and store nothing`() {
        upload(token(otherId)).andExpect { status { isForbidden() } }
        verify(exactly = 0) { storageService.store(any(), any()) }
    }

    @Test
    fun `the reporter upload should return 201`() {
        upload(token(reporterId)).andExpect { status { isCreated() } }
    }

    @Test
    fun `an admin upload should return 201`() {
        upload(token(adminId, "admin")).andExpect { status { isCreated() } }
    }

    @Test
    fun `the assigned ground admin upload should return 201`() {
        upload(token(assignedGaId)).andExpect { status { isCreated() } }
    }

    @Test
    fun `a ground admin not assigned to the issue upload should return 403 and store nothing`() {
        upload(token(otherGaId)).andExpect { status { isForbidden() } }
        verify(exactly = 0) { storageService.store(any(), any()) }
    }
}
