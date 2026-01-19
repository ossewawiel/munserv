package com.munserv.groundadmin.api

import com.fasterxml.jackson.databind.ObjectMapper
import com.munserv.auth.service.JwtService
import com.munserv.groundadmin.domain.GroundAdminApplicationId
import com.munserv.groundadmin.service.GroundAdminResult
import com.munserv.groundadmin.service.GroundAdminService
import com.munserv.shared.enums.GroundAdminStatus
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import com.ninjasquad.springmockk.MockkBean
import io.mockk.every
import io.mockk.verify
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.http.MediaType
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.patch
import org.springframework.test.web.servlet.post
import java.time.Instant
import java.util.UUID

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class GroundAdminControllerTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    @Autowired
    private lateinit var jwtService: JwtService

    @MockkBean
    private lateinit var groundAdminService: GroundAdminService

    private val testMemberIdStr = "550e8400-e29b-41d4-a716-446655440000"
    private lateinit var memberToken: String

    private val sectorId = UUID.randomUUID()
    private val applicationId = UUID.randomUUID()

    @BeforeEach
    fun setup() {
        val memberId = MemberId.fromString(testMemberIdStr)
        memberToken = jwtService.generateAccessToken(memberId, "member")
    }

    @Nested
    inner class Apply {
        @Test
        fun `POST apply returns 200 on success`() {
            val testMemberId = MemberId.fromString(testMemberIdStr)
            every { groundAdminService.apply(testMemberId) } returns
                GroundAdminResult.Success(mapOf("applicationId" to applicationId.toString(), "status" to "pending"))

            mockMvc.post("/api/v1/members/me/ground-admin/apply") {
                header("Authorization", "Bearer $memberToken")
            }.andExpect {
                status { isOk() }
                content { contentType(MediaType.APPLICATION_JSON) }
            }

            verify { groundAdminService.apply(testMemberId) }
        }

        @Test
        fun `POST apply returns 404 when member not found`() {
            val testMemberId = MemberId.fromString(testMemberIdStr)
            every { groundAdminService.apply(testMemberId) } returns
                GroundAdminResult.NotFound("Member not found")

            mockMvc.post("/api/v1/members/me/ground-admin/apply") {
                header("Authorization", "Bearer $memberToken")
            }.andExpect {
                status { isNotFound() }
            }
        }

        @Test
        fun `POST apply returns 409 when already a Ground Admin`() {
            val testMemberId = MemberId.fromString(testMemberIdStr)
            every { groundAdminService.apply(testMemberId) } returns
                GroundAdminResult.Conflict("Already a Ground Admin")

            mockMvc.post("/api/v1/members/me/ground-admin/apply") {
                header("Authorization", "Bearer $memberToken")
            }.andExpect {
                status { isConflict() }
            }
        }

        @Test
        fun `POST apply returns 403 when not authenticated`() {
            // Spring Security returns 403 for missing authentication token on POST
            mockMvc.post("/api/v1/members/me/ground-admin/apply")
                .andExpect {
                    status { isForbidden() }
                }
        }
    }

    @Nested
    inner class AcceptInvitation {
        @Test
        fun `POST accept returns 200 on success`() {
            val testMemberId = MemberId.fromString(testMemberIdStr)
            val testAppId = GroundAdminApplicationId.generate()

            every {
                groundAdminService.acceptInvitation(testMemberId, testAppId)
            } returns
                GroundAdminResult.Success(
                    mapOf(
                        "applicationId" to testAppId.toString(),
                        "status" to "accepted",
                    ),
                )

            val request = AcceptInvitationRequest(applicationId = testAppId.toString())

            mockMvc.post("/api/v1/members/me/ground-admin/accept") {
                header("Authorization", "Bearer $memberToken")
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(request)
            }.andExpect {
                status { isOk() }
            }
        }

        @Test
        fun `POST accept returns 404 when application not found`() {
            val testMemberId = MemberId.fromString(testMemberIdStr)
            val testAppId = GroundAdminApplicationId.generate()

            every {
                groundAdminService.acceptInvitation(testMemberId, testAppId)
            } returns GroundAdminResult.NotFound("Application not found")

            val request = AcceptInvitationRequest(applicationId = testAppId.toString())

            mockMvc.post("/api/v1/members/me/ground-admin/accept") {
                header("Authorization", "Bearer $memberToken")
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(request)
            }.andExpect {
                status { isNotFound() }
            }
        }
    }

    @Nested
    inner class GetMyGroundAdminInfo {
        @Test
        fun `GET my info returns 200 with data`() {
            val testMemberId = MemberId.fromString(testMemberIdStr)
            val info =
                GroundAdminInfoResponse(
                    status = GroundAdminStatus.ACTIVE,
                    since = Instant.now(),
                    responseRate = 95.5,
                    pendingVerifications = 3,
                    totalVerifications = 100,
                )

            every { groundAdminService.getMyGroundAdminInfo(testMemberId) } returns
                GroundAdminResult.Success(info)

            mockMvc.get("/api/v1/members/me/ground-admin") {
                header("Authorization", "Bearer $memberToken")
            }.andExpect {
                status { isOk() }
                content { contentType(MediaType.APPLICATION_JSON) }
            }
        }

        @Test
        fun `GET my info returns 200 with null when not a Ground Admin`() {
            val testMemberId = MemberId.fromString(testMemberIdStr)

            every { groundAdminService.getMyGroundAdminInfo(testMemberId) } returns
                GroundAdminResult.Success(null)

            mockMvc.get("/api/v1/members/me/ground-admin") {
                header("Authorization", "Bearer $memberToken")
            }.andExpect {
                status { isOk() }
            }
        }
    }

    @Nested
    inner class Invite {
        @Test
        fun `POST invite returns 200 on success`() {
            val adminId = MemberId.fromString(testMemberIdStr)
            val targetMemberId = MemberId.generate()

            every {
                groundAdminService.invite(adminId, targetMemberId, "Welcome to the team!")
            } returns
                GroundAdminResult.Success(
                    mapOf(
                        "applicationId" to applicationId.toString(),
                        "status" to "pending",
                    ),
                )

            val request = InviteGroundAdminRequest(message = "Welcome to the team!")

            mockMvc.post("/api/v1/members/${targetMemberId.value}/ground-admin/invite") {
                header("Authorization", "Bearer $memberToken")
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(request)
            }.andExpect {
                status { isOk() }
            }
        }

        @Test
        fun `POST invite returns 403 when member not in sector`() {
            val adminId = MemberId.fromString(testMemberIdStr)
            val targetMemberId = MemberId.generate()

            every {
                groundAdminService.invite(adminId, targetMemberId, null)
            } returns GroundAdminResult.Forbidden("Member not in your sector")

            val request = InviteGroundAdminRequest()

            mockMvc.post("/api/v1/members/${targetMemberId.value}/ground-admin/invite") {
                header("Authorization", "Bearer $memberToken")
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(request)
            }.andExpect {
                status { isForbidden() }
            }
        }
    }

    @Nested
    inner class Approve {
        @Test
        fun `POST approve returns 200 on success`() {
            val adminId = MemberId.fromString(testMemberIdStr)
            val targetMemberId = MemberId.generate()
            val appId = GroundAdminApplicationId.generate()

            every {
                groundAdminService.approveApplication(adminId, targetMemberId, appId)
            } returns
                GroundAdminResult.Success(
                    mapOf(
                        "applicationId" to appId.toString(),
                        "status" to "approved",
                    ),
                )

            val request = ApproveApplicationRequest(applicationId = appId.toString())

            mockMvc.post("/api/v1/members/${targetMemberId.value}/ground-admin/approve") {
                header("Authorization", "Bearer $memberToken")
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(request)
            }.andExpect {
                status { isOk() }
            }
        }
    }

    @Nested
    inner class Revoke {
        @Test
        fun `POST revoke returns 200 on success`() {
            val adminId = MemberId.fromString(testMemberIdStr)
            val targetMemberId = MemberId.generate()

            every {
                groundAdminService.revoke(adminId, targetMemberId, "Inactive for 6 months")
            } returns GroundAdminResult.Success(mapOf("status" to "revoked"))

            val request = RevokeGroundAdminRequest(reason = "Inactive for 6 months")

            mockMvc.post("/api/v1/members/${targetMemberId.value}/ground-admin/revoke") {
                header("Authorization", "Bearer $memberToken")
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(request)
            }.andExpect {
                status { isOk() }
            }
        }

        @Test
        fun `POST revoke returns 409 when member not a Ground Admin`() {
            val adminId = MemberId.fromString(testMemberIdStr)
            val targetMemberId = MemberId.generate()

            every {
                groundAdminService.revoke(adminId, targetMemberId, "Inactive")
            } returns GroundAdminResult.Conflict("Member is not a Ground Admin")

            val request = RevokeGroundAdminRequest(reason = "Inactive")

            mockMvc.post("/api/v1/members/${targetMemberId.value}/ground-admin/revoke") {
                header("Authorization", "Bearer $memberToken")
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(request)
            }.andExpect {
                status { isConflict() }
            }
        }
    }

    @Nested
    inner class UpdateStatus {
        @Test
        fun `PATCH status returns 200 on success`() {
            val adminId = MemberId.fromString(testMemberIdStr)
            val targetMemberId = MemberId.generate()

            every {
                groundAdminService.updateStatus(adminId, targetMemberId, GroundAdminStatus.ON_HOLD)
            } returns GroundAdminResult.Success(mapOf("status" to "on_hold"))

            val request = UpdateGroundAdminStatusRequest(status = GroundAdminStatus.ON_HOLD)

            mockMvc.patch("/api/v1/members/${targetMemberId.value}/ground-admin/status") {
                header("Authorization", "Bearer $memberToken")
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(request)
            }.andExpect {
                status { isOk() }
            }
        }
    }

    @Nested
    inner class ListGroundAdmins {
        @Test
        fun `GET ground-admins returns 200 with list`() {
            val testSectorId = SectorId(sectorId)
            val response =
                GroundAdminListResponse(
                    items =
                        listOf(
                            GroundAdminResponse(
                                id = UUID.randomUUID().toString(),
                                memberId = UUID.randomUUID().toString(),
                                name = "John Doe",
                                phone = "+27123456789",
                                status = GroundAdminStatus.ACTIVE,
                                since = Instant.now(),
                                responseRate = 98.5,
                                pendingVerifications = 2,
                            ),
                        ),
                    total = 1,
                )

            every { groundAdminService.listGroundAdmins(testSectorId, null) } returns response

            mockMvc.get("/api/v1/sectors/$sectorId/ground-admins") {
                header("Authorization", "Bearer $memberToken")
            }.andExpect {
                status { isOk() }
                content { contentType(MediaType.APPLICATION_JSON) }
            }
        }

        @Test
        fun `GET ground-admins with status filter returns 200`() {
            val testSectorId = SectorId(sectorId)
            val response = GroundAdminListResponse(items = emptyList(), total = 0)

            every {
                groundAdminService.listGroundAdmins(testSectorId, GroundAdminStatus.ACTIVE)
            } returns response

            mockMvc.get("/api/v1/sectors/$sectorId/ground-admins") {
                header("Authorization", "Bearer $memberToken")
                param("status", "ACTIVE")
            }.andExpect {
                status { isOk() }
            }
        }

        @Test
        fun `GET ground-admins returns 401 when not authenticated`() {
            mockMvc.get("/api/v1/sectors/$sectorId/ground-admins")
                .andExpect {
                    status { isUnauthorized() }
                }
        }
    }
}
