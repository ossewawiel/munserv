package com.munserv.photos.api

import com.munserv.auth.service.JwtService
import com.munserv.issues.domain.IssueId
import com.munserv.photos.domain.IssuePhoto
import com.munserv.photos.domain.PhotoId
import com.munserv.photos.service.IssuePhotoService
import com.munserv.photos.service.PhotoResult
import com.munserv.shared.types.MemberId
import com.ninjasquad.springmockk.MockkBean
import io.kotest.matchers.shouldBe
import io.mockk.every
import io.mockk.verify
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.http.MediaType
import org.springframework.mock.web.MockMultipartFile
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.delete
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.multipart
import java.time.Instant
import java.util.UUID

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class PhotoControllerTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var jwtService: JwtService

    @MockkBean
    private lateinit var photoService: IssuePhotoService

    private lateinit var memberToken: String
    private lateinit var adminToken: String

    private val testMemberId = MemberId.fromString("550e8400-e29b-41d4-a716-446655440010")
    private val testAdminId = MemberId.fromString("550e8400-e29b-41d4-a716-446655440020")
    private val testIssueId = IssueId(UUID.fromString("550e8400-e29b-41d4-a716-446655440100"))
    private val testPhotoId = PhotoId(UUID.fromString("550e8400-e29b-41d4-a716-446655440200"))

    private val testPhoto =
        IssuePhoto(
            id = testPhotoId,
            issueId = testIssueId,
            url = "http://localhost:8080/uploads/test-photo.jpg",
            thumbnailUrl = "http://localhost:8080/uploads/test-photo-thumb.jpg",
            sortOrder = 1,
            createdAt = Instant.parse("2026-01-15T10:30:00Z"),
        )

    @BeforeEach
    fun setup() {
        memberToken = jwtService.generateAccessToken(testMemberId, "member")
        adminToken = jwtService.generateAccessToken(testAdminId, "admin")
    }

    @Nested
    inner class UploadPhoto {
        @Test
        fun `POST issues-issueId-photos should return 201 on successful upload`() {
            val file =
                MockMultipartFile(
                    "file",
                    "test.jpg",
                    MediaType.IMAGE_JPEG_VALUE,
                    "test image content".toByteArray(),
                )

            every { photoService.uploadPhoto(any(), any()) } returns PhotoResult.Success(testPhoto)

            mockMvc.multipart("/api/v1/issues/${testIssueId.value}/photos") {
                file(file)
                header("Authorization", "Bearer $memberToken")
            }.andExpect {
                status { isCreated() }
                content { contentType(MediaType.APPLICATION_JSON) }
                jsonPath("$.id") { value(testPhotoId.value.toString()) }
                jsonPath("$.url") { value(testPhoto.url) }
                jsonPath("$.thumbnailUrl") { value(testPhoto.thumbnailUrl) }
                jsonPath("$.sortOrder") { value(1) }
            }

            verify { photoService.uploadPhoto(testIssueId, any()) }
        }

        @Test
        fun `POST issues-issueId-photos should return 400 on validation error`() {
            val file =
                MockMultipartFile(
                    "file",
                    "test.txt",
                    MediaType.TEXT_PLAIN_VALUE,
                    "not an image".toByteArray(),
                )

            every { photoService.uploadPhoto(any(), any()) } returns
                PhotoResult.ValidationError(listOf("Invalid file type", "File too large"))

            mockMvc.multipart("/api/v1/issues/${testIssueId.value}/photos") {
                file(file)
                header("Authorization", "Bearer $memberToken")
            }.andExpect {
                status { isBadRequest() }
                jsonPath("$.error.code") { value("VALIDATION_ERROR") }
                jsonPath("$.error.message") { value("Invalid file type, File too large") }
            }
        }

        @Test
        fun `POST issues-issueId-photos should return 500 on storage error`() {
            val file =
                MockMultipartFile(
                    "file",
                    "test.jpg",
                    MediaType.IMAGE_JPEG_VALUE,
                    "test image content".toByteArray(),
                )

            every { photoService.uploadPhoto(any(), any()) } returns
                PhotoResult.StorageError("Disk full")

            mockMvc.multipart("/api/v1/issues/${testIssueId.value}/photos") {
                file(file)
                header("Authorization", "Bearer $memberToken")
            }.andExpect {
                status { isInternalServerError() }
                jsonPath("$.error.code") { value("INTERNAL_ERROR") }
                jsonPath("$.error.message") { value("Disk full") }
            }
        }

        @Test
        fun `POST issues-issueId-photos should return 403 without token`() {
            val file =
                MockMultipartFile(
                    "file",
                    "test.jpg",
                    MediaType.IMAGE_JPEG_VALUE,
                    "test image content".toByteArray(),
                )

            mockMvc.multipart("/api/v1/issues/${testIssueId.value}/photos") {
                file(file)
            }.andExpect {
                status { isForbidden() }
            }
        }
    }

    @Nested
    inner class GetPhotosForIssue {
        @Test
        fun `GET issues-issueId-photos should return list of photos`() {
            val photos =
                listOf(
                    testPhoto,
                    testPhoto.copy(
                        id = PhotoId.generate(),
                        sortOrder = 2,
                        url = "http://localhost:8080/uploads/test-photo-2.jpg",
                    ),
                )

            every { photoService.getPhotosForIssue(testIssueId) } returns photos

            mockMvc.get("/api/v1/issues/${testIssueId.value}/photos") {
                header("Authorization", "Bearer $memberToken")
                accept = MediaType.APPLICATION_JSON
            }.andExpect {
                status { isOk() }
                content { contentType(MediaType.APPLICATION_JSON) }
                jsonPath("$") { isArray() }
                jsonPath("$.length()") { value(2) }
                jsonPath("$[0].id") { value(testPhotoId.value.toString()) }
                jsonPath("$[0].sortOrder") { value(1) }
                jsonPath("$[1].sortOrder") { value(2) }
            }

            verify { photoService.getPhotosForIssue(testIssueId) }
        }

        @Test
        fun `GET issues-issueId-photos should return empty array when no photos`() {
            every { photoService.getPhotosForIssue(testIssueId) } returns emptyList()

            mockMvc.get("/api/v1/issues/${testIssueId.value}/photos") {
                header("Authorization", "Bearer $memberToken")
                accept = MediaType.APPLICATION_JSON
            }.andExpect {
                status { isOk() }
                jsonPath("$") { isArray() }
                jsonPath("$.length()") { value(0) }
            }
        }

        @Test
        fun `GET issues-issueId-photos should return 403 without token`() {
            mockMvc.get("/api/v1/issues/${testIssueId.value}/photos") {
                accept = MediaType.APPLICATION_JSON
            }.andExpect {
                status { isForbidden() }
            }
        }
    }

    @Nested
    inner class DeletePhoto {
        @Test
        fun `DELETE photos-photoId should return 204 on successful delete`() {
            every { photoService.deletePhoto(testPhotoId) } returns true

            mockMvc.delete("/api/v1/photos/${testPhotoId.value}") {
                header("Authorization", "Bearer $memberToken")
            }.andExpect {
                status { isNoContent() }
            }

            verify { photoService.deletePhoto(testPhotoId) }
        }

        @Test
        fun `DELETE photos-photoId should return 404 when photo not found`() {
            every { photoService.deletePhoto(testPhotoId) } returns false

            mockMvc.delete("/api/v1/photos/${testPhotoId.value}") {
                header("Authorization", "Bearer $memberToken")
            }.andExpect {
                status { isNotFound() }
                jsonPath("$.error.code") { value("NOT_FOUND") }
                jsonPath("$.error.message") { value("Photo not found") }
            }
        }
    }

    @Nested
    inner class PhotoResponseMapping {
        @Test
        fun `toResponse should correctly map IssuePhoto to PhotoResponse`() {
            val response = testPhoto.toResponse()

            response.id shouldBe testPhotoId.value.toString()
            response.url shouldBe testPhoto.url
            response.thumbnailUrl shouldBe testPhoto.thumbnailUrl
            response.sortOrder shouldBe testPhoto.sortOrder
            response.createdAt shouldBe testPhoto.createdAt.toString()
        }
    }
}
