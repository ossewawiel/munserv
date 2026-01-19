package com.munserv.verification.service

import com.munserv.auth.domain.Member
import com.munserv.auth.domain.MemberStatus
import com.munserv.auth.repository.MemberRepository
import com.munserv.issues.domain.Issue
import com.munserv.issues.domain.IssueId
import com.munserv.issues.domain.IssueState
import com.munserv.issues.domain.IssueType
import com.munserv.issues.repository.IssueRepository
import com.munserv.messages.service.MessageService
import com.munserv.sectors.domain.SectorSettings
import com.munserv.sectors.service.SectorSettingsResult
import com.munserv.sectors.service.SectorSettingsService
import com.munserv.shared.enums.GroundAdminStatus
import com.munserv.shared.enums.VerificationMode
import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import com.munserv.shared.types.SectorSettingsId
import com.munserv.verification.api.RequestVerificationRequest
import com.munserv.verification.api.SubmitVerificationRequest
import com.munserv.verification.domain.IssueVerification
import com.munserv.verification.domain.IssueVerificationId
import com.munserv.verification.domain.VerificationOutcome
import com.munserv.verification.domain.VerificationStatus
import com.munserv.verification.domain.VerificationType
import com.munserv.verification.repository.IssueVerificationRepository
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.clearAllMocks
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import java.time.Instant

class VerificationServiceTest {
    private lateinit var verificationRepository: IssueVerificationRepository
    private lateinit var issueRepository: IssueRepository
    private lateinit var memberRepository: MemberRepository
    private lateinit var sectorSettingsService: SectorSettingsService
    private lateinit var messageService: MessageService
    private lateinit var service: VerificationService

    private val sectorId = SectorId.generate()
    private val issueId = IssueId.generate()
    private val memberId = MemberId.generate()
    private val adminId = MemberId.generate()
    private val verificationId = IssueVerificationId.generate()

    @BeforeEach
    fun setup() {
        clearAllMocks()
        verificationRepository = mockk(relaxed = true)
        issueRepository = mockk(relaxed = true)
        memberRepository = mockk(relaxed = true)
        sectorSettingsService = mockk(relaxed = true)
        messageService = mockk(relaxed = true)
        service =
            VerificationService(
                verificationRepository = verificationRepository,
                issueRepository = issueRepository,
                memberRepository = memberRepository,
                sectorSettingsService = sectorSettingsService,
                messageService = messageService,
            )
    }

    private fun createTestIssue(
        id: IssueId = issueId,
        state: IssueState = IssueState.Reported,
    ): Issue =
        Issue(
            id = id,
            sectorId = sectorId,
            reporterId = memberId,
            type = IssueType.POTHOLE,
            state = state,
            location = GeoPoint(-26.0, 28.0),
            address = "123 Test Street",
            description = "Test issue",
            heat = 50,
            reportCount = 1,
            createdAt = Instant.now(),
            updatedAt = Instant.now(),
        )

    private fun createTestMember(
        id: MemberId = memberId,
        sectorId: SectorId = this.sectorId,
        isGroundAdmin: Boolean = false,
        groundAdminStatus: GroundAdminStatus? = null,
    ): Member =
        Member(
            id = id,
            sectorId = sectorId,
            email = "test@example.com",
            emailHash = "testhash",
            passwordHash = "pwhash",
            mustChangePassword = false,
            phoneHash = null,
            pinHash = null,
            phone = "+27821234567",
            firstName = "Test",
            surname = "Member",
            address = "123 Test Street",
            registrationLocation = GeoPoint(27.9833, -26.1367),
            status = MemberStatus.Active,
            createdAt = Instant.now(),
            updatedAt = Instant.now(),
            isGroundAdmin = isGroundAdmin,
            groundAdminStatus = groundAdminStatus,
            groundAdminSince = if (isGroundAdmin) Instant.now() else null,
            groundAdminResponseRate = if (isGroundAdmin) java.math.BigDecimal("100.00") else null,
        )

    private fun createTestVerification(
        id: IssueVerificationId = verificationId,
        issueId: IssueId = this.issueId,
        type: VerificationType = VerificationType.EXISTENCE,
        status: VerificationStatus = VerificationStatus.PENDING,
        assignedTo: MemberId? = null,
    ): IssueVerification =
        IssueVerification(
            id = id,
            issueId = issueId,
            verificationType = type,
            assignedTo = assignedTo,
            status = status,
        )

    private fun createTestSectorSettings(): SectorSettings =
        SectorSettings(
            id = SectorSettingsId.generate(),
            sectorId = sectorId,
            newIssueVerificationMode = VerificationMode.ALL_NOTIFIED,
            fixVerificationMode = VerificationMode.ALL_NOTIFIED,
            daysFixedBeforeClosed = 7,
            minimumGroundAdmins = 2,
            createdAt = Instant.now(),
            updatedAt = Instant.now(),
        )

    @Nested
    inner class RequestVerification {
        @Test
        fun `should create verification and send messages`() {
            val issue = createTestIssue(state = IssueState.Reported)
            val request = RequestVerificationRequest(type = "existence")
            val groundAdmin = createTestMember(isGroundAdmin = true, groundAdminStatus = GroundAdminStatus.ACTIVE)

            every { issueRepository.findById(issueId) } returns issue
            every {
                verificationRepository.existsByIssueIdAndVerificationTypeAndStatus(
                    issueId,
                    VerificationType.EXISTENCE,
                    VerificationStatus.PENDING,
                )
            } returns false
            every { verificationRepository.save(any()) } answers { firstArg() }
            every {
                memberRepository.findBySectorIdAndIsGroundAdminAndGroundAdminStatus(
                    sectorId,
                    true,
                    GroundAdminStatus.ACTIVE,
                )
            } returns listOf(groundAdmin)

            val result = service.requestVerification(issueId, request, adminId)

            result.shouldBeInstanceOf<VerificationResult.Success>()
            verify { verificationRepository.save(any()) }
            verify { messageService.createMessage(any()) }
        }

        @Test
        fun `should return NotFound when issue not found`() {
            val request = RequestVerificationRequest(type = "existence")

            every { issueRepository.findById(issueId) } returns null

            val result = service.requestVerification(issueId, request, adminId)

            result.shouldBeInstanceOf<VerificationResult.NotFound>()
        }

        @Test
        fun `should return ValidationError for wrong issue state`() {
            val issue = createTestIssue(state = IssueState.Confirmed)
            val request = RequestVerificationRequest(type = "existence")

            every { issueRepository.findById(issueId) } returns issue

            val result = service.requestVerification(issueId, request, adminId)

            result.shouldBeInstanceOf<VerificationResult.ValidationError>()
        }

        @Test
        fun `should return ValidationError for invalid type`() {
            val request = RequestVerificationRequest(type = "invalid")

            val result = service.requestVerification(issueId, request, adminId)

            result.shouldBeInstanceOf<VerificationResult.ValidationError>()
        }

        @Test
        fun `should return Conflict when pending verification exists`() {
            val issue = createTestIssue(state = IssueState.Reported)
            val request = RequestVerificationRequest(type = "existence")

            every { issueRepository.findById(issueId) } returns issue
            every {
                verificationRepository.existsByIssueIdAndVerificationTypeAndStatus(
                    issueId,
                    VerificationType.EXISTENCE,
                    VerificationStatus.PENDING,
                )
            } returns true

            val result = service.requestVerification(issueId, request, adminId)

            result.shouldBeInstanceOf<VerificationResult.Conflict>()
        }
    }

    @Nested
    inner class SubmitVerification {
        @Test
        fun `should complete verification and update issue state to Confirmed`() {
            val verification = createTestVerification()
            val issue = createTestIssue(state = IssueState.Reported)
            val member = createTestMember(isGroundAdmin = true, groundAdminStatus = GroundAdminStatus.ACTIVE)
            val request =
                SubmitVerificationRequest(
                    verificationId = verificationId.toString(),
                    result = "confirmed",
                )

            every { verificationRepository.findById(verificationId) } returns verification
            every { memberRepository.findById(memberId) } returns member
            every { verificationRepository.save(any()) } answers { firstArg() }
            every { issueRepository.findById(issueId) } returns issue
            every { issueRepository.save(any()) } answers { firstArg() }

            val result = service.submitVerification(issueId, request, memberId)

            result.shouldBeInstanceOf<VerificationResult.Success>()
            verify { verificationRepository.save(match { it.outcome == VerificationOutcome.CONFIRMED }) }
            verify { issueRepository.save(match { it.state == IssueState.Confirmed }) }
        }

        @Test
        fun `should update issue state to Rejected when not found`() {
            val verification = createTestVerification()
            val issue = createTestIssue(state = IssueState.Reported)
            val member = createTestMember(isGroundAdmin = true, groundAdminStatus = GroundAdminStatus.ACTIVE)
            val request =
                SubmitVerificationRequest(
                    verificationId = verificationId.toString(),
                    result = "not_found",
                )

            every { verificationRepository.findById(verificationId) } returns verification
            every { memberRepository.findById(memberId) } returns member
            every { verificationRepository.save(any()) } answers { firstArg() }
            every { issueRepository.findById(issueId) } returns issue
            every { issueRepository.save(any()) } answers { firstArg() }

            val result = service.submitVerification(issueId, request, memberId)

            result.shouldBeInstanceOf<VerificationResult.Success>()
            verify { issueRepository.save(match { it.state == IssueState.Rejected }) }
        }

        @Test
        fun `should update issue state to Reopened when fix not verified`() {
            val verification = createTestVerification(type = VerificationType.FIX)
            val issue = createTestIssue(state = IssueState.Fixed)
            val member = createTestMember(isGroundAdmin = true, groundAdminStatus = GroundAdminStatus.ACTIVE)
            val request =
                SubmitVerificationRequest(
                    verificationId = verificationId.toString(),
                    result = "not_fixed",
                )

            every { verificationRepository.findById(verificationId) } returns verification
            every { memberRepository.findById(memberId) } returns member
            every { verificationRepository.save(any()) } answers { firstArg() }
            every { issueRepository.findById(issueId) } returns issue
            every { issueRepository.save(any()) } answers { firstArg() }

            val result = service.submitVerification(issueId, request, memberId)

            result.shouldBeInstanceOf<VerificationResult.Success>()
            verify { issueRepository.save(match { it.state == IssueState.Reopened }) }
        }

        @Test
        fun `should return NotFound when verification not found`() {
            val request =
                SubmitVerificationRequest(
                    verificationId = verificationId.toString(),
                    result = "confirmed",
                )

            every { verificationRepository.findById(verificationId) } returns null

            val result = service.submitVerification(issueId, request, memberId)

            result.shouldBeInstanceOf<VerificationResult.NotFound>()
        }

        @Test
        fun `should return NotFound when verification belongs to different issue`() {
            val otherIssueId = IssueId.generate()
            val verification = createTestVerification(issueId = otherIssueId)
            val request =
                SubmitVerificationRequest(
                    verificationId = verificationId.toString(),
                    result = "confirmed",
                )

            every { verificationRepository.findById(verificationId) } returns verification

            val result = service.submitVerification(issueId, request, memberId)

            result.shouldBeInstanceOf<VerificationResult.NotFound>()
        }

        @Test
        fun `should return Conflict when verification already completed`() {
            val verification = createTestVerification(status = VerificationStatus.COMPLETED)
            val request =
                SubmitVerificationRequest(
                    verificationId = verificationId.toString(),
                    result = "confirmed",
                )

            every { verificationRepository.findById(verificationId) } returns verification

            val result = service.submitVerification(issueId, request, memberId)

            result.shouldBeInstanceOf<VerificationResult.Conflict>()
        }

        @Test
        fun `should return Forbidden when not a Ground Admin`() {
            val verification = createTestVerification()
            val member = createTestMember(isGroundAdmin = false)
            val request =
                SubmitVerificationRequest(
                    verificationId = verificationId.toString(),
                    result = "confirmed",
                )

            every { verificationRepository.findById(verificationId) } returns verification
            every { memberRepository.findById(memberId) } returns member

            val result = service.submitVerification(issueId, request, memberId)

            result.shouldBeInstanceOf<VerificationResult.Forbidden>()
        }

        @Test
        fun `should return Forbidden when Ground Admin not active`() {
            val verification = createTestVerification()
            val member = createTestMember(isGroundAdmin = true, groundAdminStatus = GroundAdminStatus.ON_HOLD)
            val request =
                SubmitVerificationRequest(
                    verificationId = verificationId.toString(),
                    result = "confirmed",
                )

            every { verificationRepository.findById(verificationId) } returns verification
            every { memberRepository.findById(memberId) } returns member

            val result = service.submitVerification(issueId, request, memberId)

            result.shouldBeInstanceOf<VerificationResult.Forbidden>()
        }

        @Test
        fun `should return Forbidden when verification assigned to another GA`() {
            val otherGaId = MemberId.generate()
            val verification = createTestVerification(assignedTo = otherGaId)
            val member = createTestMember(isGroundAdmin = true, groundAdminStatus = GroundAdminStatus.ACTIVE)
            val request =
                SubmitVerificationRequest(
                    verificationId = verificationId.toString(),
                    result = "confirmed",
                )

            every { verificationRepository.findById(verificationId) } returns verification
            every { memberRepository.findById(memberId) } returns member

            val result = service.submitVerification(issueId, request, memberId)

            result.shouldBeInstanceOf<VerificationResult.Forbidden>()
        }

        @Test
        fun `should return ValidationError when result is invalid`() {
            val request =
                SubmitVerificationRequest(
                    verificationId = verificationId.toString(),
                    result = "invalid_result",
                )

            val result = service.submitVerification(issueId, request, memberId)

            result.shouldBeInstanceOf<VerificationResult.ValidationError>()
        }

        @Test
        fun `should return ValidationError when cannot_verify without reason`() {
            val request =
                SubmitVerificationRequest(
                    verificationId = verificationId.toString(),
                    result = "cannot_verify",
                    reason = null,
                )

            val result = service.submitVerification(issueId, request, memberId)

            result.shouldBeInstanceOf<VerificationResult.ValidationError>()
        }
    }

    @Nested
    inner class TriggerAutoVerification {
        @Test
        fun `should create verification and notify all ground admins when mode is ALL_NOTIFIED`() {
            val issue = createTestIssue()
            val settings = createTestSectorSettings()
            val groundAdmin = createTestMember(isGroundAdmin = true, groundAdminStatus = GroundAdminStatus.ACTIVE)

            every { sectorSettingsService.getSettings(sectorId) } returns SectorSettingsResult.Success(settings)
            every { verificationRepository.save(any()) } answers { firstArg() }
            every {
                memberRepository.findBySectorIdAndIsGroundAdminAndGroundAdminStatus(
                    sectorId,
                    true,
                    GroundAdminStatus.ACTIVE,
                )
            } returns listOf(groundAdmin)

            service.triggerAutoVerification(issue, VerificationType.EXISTENCE)

            verify { verificationRepository.save(any()) }
            verify { messageService.createMessage(any()) }
        }

        @Test
        fun `should not send messages when mode is ADMIN_ASSIGNS`() {
            val issue = createTestIssue()
            val settings =
                createTestSectorSettings().copy(
                    newIssueVerificationMode = VerificationMode.ADMIN_ASSIGNS,
                )

            every { sectorSettingsService.getSettings(sectorId) } returns SectorSettingsResult.Success(settings)
            every { verificationRepository.save(any()) } answers { firstArg() }

            service.triggerAutoVerification(issue, VerificationType.EXISTENCE)

            verify { verificationRepository.save(any()) }
            verify(exactly = 0) { messageService.createMessage(any()) }
        }
    }

    @Nested
    inner class AdminOverrideState {
        @Test
        fun `should update issue state and expire pending verifications`() {
            val issue = createTestIssue(state = IssueState.Reported)
            val pendingVerification = createTestVerification()

            every { issueRepository.findById(issueId) } returns issue
            every {
                verificationRepository.findByIssueIdAndStatus(
                    issueId,
                    VerificationStatus.PENDING,
                )
            } returns listOf(pendingVerification)
            every { verificationRepository.saveAll(any<List<IssueVerification>>()) } answers { firstArg() }
            every { issueRepository.save(any()) } answers { firstArg() }

            val result = service.adminOverrideState(issueId, IssueState.Confirmed, adminId)

            result.shouldBeInstanceOf<VerificationResult.Success>()
            verify { verificationRepository.saveAll(match { it.all { v -> v.status == VerificationStatus.EXPIRED } }) }
            verify { issueRepository.save(match { it.state == IssueState.Confirmed }) }
        }

        @Test
        fun `should return NotFound when issue not found`() {
            every { issueRepository.findById(issueId) } returns null

            val result = service.adminOverrideState(issueId, IssueState.Confirmed, adminId)

            result.shouldBeInstanceOf<VerificationResult.NotFound>()
        }
    }

    @Nested
    inner class GetVerificationHistory {
        @Test
        fun `should return verification history`() {
            val verification1 = createTestVerification(id = IssueVerificationId.generate())
            val verification2 = createTestVerification(id = IssueVerificationId.generate())

            every { verificationRepository.findByIssueId(issueId) } returns listOf(verification1, verification2)

            val result = service.getVerificationHistory(issueId)

            result.items.size shouldBe 2
        }
    }

    @Nested
    inner class GetPendingVerifications {
        @Test
        fun `should return pending verifications for ground admin`() {
            val member = createTestMember(isGroundAdmin = true, groundAdminStatus = GroundAdminStatus.ACTIVE)
            val issue = createTestIssue()
            val verification = createTestVerification()

            every { memberRepository.findById(memberId) } returns member
            every { verificationRepository.findPendingForGroundAdmin(sectorId, memberId) } returns listOf(verification)
            every { issueRepository.findById(issueId) } returns issue

            val result = service.getPendingVerifications(memberId)

            result.shouldBeInstanceOf<VerificationResult.Success>()
        }

        @Test
        fun `should return empty list for non-ground-admin`() {
            val member = createTestMember(isGroundAdmin = false)

            every { memberRepository.findById(memberId) } returns member

            val result = service.getPendingVerifications(memberId)

            result.shouldBeInstanceOf<VerificationResult.Success>()
        }

        @Test
        fun `should return NotFound when member not found`() {
            every { memberRepository.findById(memberId) } returns null

            val result = service.getPendingVerifications(memberId)

            result.shouldBeInstanceOf<VerificationResult.NotFound>()
        }
    }
}
