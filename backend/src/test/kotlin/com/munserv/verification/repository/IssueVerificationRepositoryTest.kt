package com.munserv.verification.repository

import com.munserv.TestContainersConfig
import com.munserv.issues.domain.IssueId
import com.munserv.shared.enums.VerificationReason
import com.munserv.shared.types.MemberId
import com.munserv.verification.domain.IssueVerification
import com.munserv.verification.domain.VerificationOutcome
import com.munserv.verification.domain.VerificationStatus
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.Test
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.EnumSource
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest
import org.springframework.boot.jdbc.test.autoconfigure.AutoConfigureTestDatabase
import org.springframework.boot.jpa.test.autoconfigure.TestEntityManager
import org.springframework.context.annotation.Import
import org.springframework.test.context.ActiveProfiles
import java.util.UUID

@DataJpaTest
@ActiveProfiles("test")
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Import(TestContainersConfig::class, DefaultIssueVerificationRepository::class)
class IssueVerificationRepositoryTest {
    @Autowired
    private lateinit var repository: IssueVerificationRepository

    @Autowired
    private lateinit var entityManager: TestEntityManager

    private val issueId = IssueId(UUID.fromString("550e8400-e29b-41d4-a716-446655440103"))
    private val john = MemberId(UUID.fromString("550e8400-e29b-41d4-a716-446655440010"))

    private fun saveAndReload(verification: IssueVerification): IssueVerification {
        repository.save(verification)
        entityManager.flush()
        entityManager.clear()
        return requireNotNull(repository.findById(verification.id))
    }

    @Test
    fun `should persist a pending verification when reason is null`() {
        val loaded = saveAndReload(IssueVerification.createExistenceVerification(issueId))

        loaded.reason.shouldBeNull()
        loaded.status shouldBe VerificationStatus.PENDING
    }

    @Test
    fun `should persist a completed verification when reason is set`() {
        val pending = saveAndReload(IssueVerification.createExistenceVerification(issueId))

        val loaded =
            saveAndReload(
                pending.complete(verifiedBy = john, outcome = VerificationOutcome.CANNOT_VERIFY, reason = VerificationReason.BUSY),
            )

        loaded.reason shouldBe VerificationReason.BUSY
        loaded.status shouldBe VerificationStatus.COMPLETED
    }

    @ParameterizedTest
    @EnumSource(VerificationReason::class)
    fun `should round-trip every reason when completed`(reason: VerificationReason) {
        val pending = saveAndReload(IssueVerification.createExistenceVerification(issueId))

        val loaded =
            saveAndReload(
                pending.complete(verifiedBy = john, outcome = VerificationOutcome.CANNOT_VERIFY, reason = reason),
            )

        loaded.reason.shouldNotBeNull() shouldBe reason
    }
}
