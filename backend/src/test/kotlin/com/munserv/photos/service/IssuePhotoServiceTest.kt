package com.munserv.photos.service

import com.munserv.issues.domain.Issue
import com.munserv.issues.domain.IssueId
import com.munserv.issues.domain.IssueState
import com.munserv.issues.domain.IssueType
import com.munserv.issues.service.IssueResult
import com.munserv.issues.service.IssueService
import com.munserv.photos.domain.IssuePhoto
import com.munserv.photos.domain.PhotoId
import com.munserv.photos.repository.IssuePhotoRepository
import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import com.munserv.verification.service.VerificationService
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.springframework.web.multipart.MultipartFile
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset

class IssuePhotoServiceTest {
    private val repository: IssuePhotoRepository = mockk(relaxed = true)
    private val storageService: PhotoStorageService = mockk(relaxed = true)
    private val validationService: PhotoValidationService = mockk(relaxed = true)
    private val issueService: IssueService = mockk()
    private val verificationService: VerificationService = mockk()
    private val file: MultipartFile = mockk(relaxed = true)
    private val clock: Clock = Clock.fixed(Instant.parse("2026-01-15T10:30:00Z"), ZoneOffset.UTC)

    private val reporterId = MemberId.generate()
    private val otherId = MemberId.generate()
    private val gaId = MemberId.generate()
    private val issueId = IssueId.generate()
    private val photoId = PhotoId.generate()

    private val issue =
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
    private val photo =
        IssuePhoto(
            id = photoId,
            issueId = issueId,
            url = "u",
            thumbnailUrl = "t",
            sortOrder = 0,
            createdAt = Instant.now(),
        )

    private lateinit var service: IssuePhotoService

    @BeforeEach
    fun setUp() {
        service = IssuePhotoService(repository, storageService, validationService, issueService, verificationService, clock)
        every { issueService.findById(issueId) } returns IssueResult.Success(issue)
        every { validationService.validate(any()) } returns ValidationResult.Valid
        every { storageService.store(any(), any()) } returns UploadResult.Success("u", "t")
        every { repository.getNextSortOrder(issueId) } returns 0
        every { repository.save(any()) } answers { firstArg() }
        every { repository.findById(photoId) } returns photo
    }

    @Nested
    inner class Upload {
        @Test
        fun `should return Success when the reporter uploads`() {
            val result = service.uploadPhoto(issueId, file, PhotoActor.Member(reporterId))

            result.shouldBeInstanceOf<PhotoResult.Success>()
            verify(exactly = 0) { verificationService.mayVerify(any(), any()) }
        }

        @Test
        fun `should return Success when an admin uploads`() {
            service.uploadPhoto(issueId, file, PhotoActor.Admin).shouldBeInstanceOf<PhotoResult.Success>()
        }

        @Test
        fun `should return Success when the assigned ground admin uploads`() {
            every { verificationService.mayVerify(issueId, gaId) } returns true

            service.uploadPhoto(issueId, file, PhotoActor.Member(gaId)).shouldBeInstanceOf<PhotoResult.Success>()
        }

        @Test
        fun `should return Forbidden when a ground admin not assigned to the issue uploads`() {
            every { verificationService.mayVerify(issueId, gaId) } returns false

            service.uploadPhoto(issueId, file, PhotoActor.Member(gaId)).shouldBeInstanceOf<PhotoResult.Forbidden>()
            verify(exactly = 0) { validationService.validate(any()) }
            verify(exactly = 0) { storageService.store(any(), any()) }
            verify(exactly = 0) { repository.save(any()) }
        }

        @Test
        fun `should return Forbidden when another member uploads`() {
            every { verificationService.mayVerify(issueId, otherId) } returns false

            service.uploadPhoto(issueId, file, PhotoActor.Member(otherId)).shouldBeInstanceOf<PhotoResult.Forbidden>()
            verify(exactly = 0) { storageService.store(any(), any()) }
            verify(exactly = 0) { repository.save(any()) }
        }

        @Test
        fun `should return IssueNotFound when the issue does not exist`() {
            every { issueService.findById(issueId) } returns IssueResult.NotFound(issueId)

            service.uploadPhoto(issueId, file, PhotoActor.Admin) shouldBe PhotoResult.IssueNotFound(issueId)
        }
    }

    @Nested
    inner class Delete {
        @Test
        fun `should return Success when the reporter deletes`() {
            service.deletePhoto(photoId, PhotoActor.Member(reporterId)).shouldBeInstanceOf<PhotoResult.Success>()
            verify { storageService.delete(photoId) }
            verify { repository.deleteById(photoId) }
        }

        @Test
        fun `should return Success when an admin deletes`() {
            service.deletePhoto(photoId, PhotoActor.Admin).shouldBeInstanceOf<PhotoResult.Success>()
        }

        @Test
        fun `should return Forbidden when the assigned ground admin deletes`() {
            service.deletePhoto(photoId, PhotoActor.Member(gaId)).shouldBeInstanceOf<PhotoResult.Forbidden>()
            verify(exactly = 0) { verificationService.mayVerify(any(), any()) }
            verify(exactly = 0) { storageService.delete(any()) }
            verify(exactly = 0) { repository.deleteById(any()) }
        }

        @Test
        fun `should return Forbidden when another member deletes`() {
            service.deletePhoto(photoId, PhotoActor.Member(otherId)).shouldBeInstanceOf<PhotoResult.Forbidden>()
        }

        @Test
        fun `should return NotFound when the photo does not exist`() {
            every { repository.findById(photoId) } returns null

            service.deletePhoto(photoId, PhotoActor.Admin) shouldBe PhotoResult.NotFound(photoId)
        }
    }
}
