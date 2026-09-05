package com.munserv.verification.domain

import com.munserv.issues.domain.IssueId
import com.munserv.shared.enums.VerificationReason
import com.munserv.shared.types.MemberId
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import java.util.UUID

class IssueVerificationTest {
    private val issueId = IssueId.generate()
    private val memberId = MemberId.generate()

    @Nested
    inner class CreateExistenceVerification {
        @Test
        fun `should create with correct type and pending status`() {
            val verification = IssueVerification.createExistenceVerification(issueId)

            verification.issueId shouldBe issueId
            verification.verificationType shouldBe VerificationType.EXISTENCE
            verification.status shouldBe VerificationStatus.PENDING
            verification.assignedTo shouldBe null
            verification.verifiedBy shouldBe null
            verification.outcome shouldBe null
        }

        @Test
        fun `should set assignedTo when provided`() {
            val verification = IssueVerification.createExistenceVerification(issueId, memberId)

            verification.assignedTo shouldBe memberId
        }
    }

    @Nested
    inner class CreateFixVerification {
        @Test
        fun `should create with correct type and pending status`() {
            val verification = IssueVerification.createFixVerification(issueId)

            verification.issueId shouldBe issueId
            verification.verificationType shouldBe VerificationType.FIX
            verification.status shouldBe VerificationStatus.PENDING
        }
    }

    @Nested
    inner class Complete {
        @Test
        fun `should update status and set verifier details`() {
            val verification = IssueVerification.createExistenceVerification(issueId)
            val verifierId = MemberId.generate()
            val photoId = UUID.randomUUID()

            val completed =
                verification.complete(
                    verifiedBy = verifierId,
                    outcome = VerificationOutcome.CONFIRMED,
                    note = "Issue exists",
                    photoId = photoId,
                )

            completed.status shouldBe VerificationStatus.COMPLETED
            completed.verifiedBy shouldBe verifierId
            completed.outcome shouldBe VerificationOutcome.CONFIRMED
            completed.note shouldBe "Issue exists"
            completed.photoId shouldBe photoId
            completed.respondedAt shouldNotBe null
        }

        @Test
        fun `should set reason when cannot verify`() {
            val verification = IssueVerification.createExistenceVerification(issueId)

            val completed =
                verification.complete(
                    verifiedBy = memberId,
                    outcome = VerificationOutcome.CANNOT_VERIFY,
                    reason = VerificationReason.BUSY,
                )

            completed.outcome shouldBe VerificationOutcome.CANNOT_VERIFY
            completed.reason shouldBe VerificationReason.BUSY
        }
    }

    @Nested
    inner class Expire {
        @Test
        fun `should update status to expired`() {
            val verification = IssueVerification.createExistenceVerification(issueId)

            val expired = verification.expire()

            expired.status shouldBe VerificationStatus.EXPIRED
        }
    }

    @Nested
    inner class StatusChecks {
        @Test
        fun `isPending should be true when status is pending`() {
            val verification = IssueVerification.createExistenceVerification(issueId)

            verification.isPending shouldBe true
        }

        @Test
        fun `isPending should be false when completed`() {
            val verification =
                IssueVerification
                    .createExistenceVerification(issueId)
                    .complete(memberId, VerificationOutcome.CONFIRMED)

            verification.isPending shouldBe false
        }

        @Test
        fun `isExistenceVerification should be true for existence type`() {
            val verification = IssueVerification.createExistenceVerification(issueId)

            verification.isExistenceVerification shouldBe true
            verification.isFixVerification shouldBe false
        }

        @Test
        fun `isFixVerification should be true for fix type`() {
            val verification = IssueVerification.createFixVerification(issueId)

            verification.isFixVerification shouldBe true
            verification.isExistenceVerification shouldBe false
        }
    }
}
