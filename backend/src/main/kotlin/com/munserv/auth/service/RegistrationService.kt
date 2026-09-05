package com.munserv.auth.service

import com.munserv.auth.domain.Email
import com.munserv.auth.domain.Member
import com.munserv.auth.domain.MemberStatus
import com.munserv.auth.domain.Password
import com.munserv.auth.repository.MemberRepository
import com.munserv.sectors.service.SectorService
import com.munserv.shared.email.EmailService
import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock

/**
 * Handles web-based member registration and admin approval workflow.
 */
@Service
class RegistrationService(
    private val memberRepository: MemberRepository,
    private val sectorService: SectorService,
    private val emailService: EmailService,
    private val clock: Clock,
) {
    /**
     * Registers a new member from web form submission.
     * Creates member with PendingApproval status.
     */
    @Transactional
    fun registerMember(command: WebRegistrationCommand): RegistrationResult {
        // Validate email format
        val email =
            Email.fromStringOrNull(command.email)
                ?: return RegistrationResult.ValidationError(
                    listOf("Invalid email format"),
                )

        // Check if email already registered
        if (memberRepository.existsByEmailHash(email.hash())) {
            return RegistrationResult.EmailAlreadyRegistered
        }

        // Validate sector exists
        sectorService.findById(command.sectorId)
            ?: return RegistrationResult.InvalidSector

        // Create member with PendingApproval status
        val now = clock.instant()
        val member =
            Member(
                id = MemberId.generate(),
                sectorId = command.sectorId,
                email = email.value,
                emailHash = email.hash(),
                // Password is set when admin approves and generates a temporary password
                passwordHash = null,
                mustChangePassword = true,
                phoneHash = null,
                pinHash = null,
                phone = command.phone,
                firstName = command.firstName.trim(),
                surname = command.surname.trim(),
                address = command.address.trim(),
                registrationLocation = command.location,
                status = MemberStatus.PendingApproval,
                createdAt = now,
                updatedAt = now,
            )

        val saved = memberRepository.save(member)
        return RegistrationResult.Success(saved)
    }

    /**
     * Approves a pending member registration.
     * Generates temporary password and sends welcome email.
     */
    @Transactional
    fun approveMember(memberId: MemberId): RegistrationResult {
        val member =
            memberRepository.findById(memberId)
                ?: return RegistrationResult.MemberNotFound

        // Must be pending approval
        if (member.status != MemberStatus.PendingApproval) {
            return RegistrationResult.InvalidStatus(
                current = member.status.toString(),
                expected = "pending_approval",
            )
        }

        // Generate temporary password
        val tempPassword = Password.generate()
        val passwordHash = Password.hash(tempPassword)

        // Update member status and set password
        val approved =
            member
                .withStatus(MemberStatus.Active)
                .withPassword(passwordHash, mustChange = true)

        val saved = memberRepository.save(approved)

        // Send welcome email
        emailService.sendWelcomeEmail(
            toEmail = saved.email,
            memberName = saved.fullName,
            tempPassword = tempPassword,
        )

        return RegistrationResult.Approved(saved, tempPassword)
    }

    /**
     * Rejects a pending member registration.
     * Deletes the member record.
     */
    @Transactional
    fun rejectMember(memberId: MemberId): RegistrationResult {
        val member =
            memberRepository.findById(memberId)
                ?: return RegistrationResult.MemberNotFound

        // Must be pending approval
        if (member.status != MemberStatus.PendingApproval) {
            return RegistrationResult.InvalidStatus(
                current = member.status.toString(),
                expected = "pending_approval",
            )
        }

        // Delete the record
        memberRepository.delete(memberId)
        return RegistrationResult.Rejected(memberId)
    }
}

/**
 * Command object for web registration.
 */
data class WebRegistrationCommand(
    val email: String,
    val firstName: String,
    val surname: String,
    val phone: String,
    val address: String,
    val location: GeoPoint,
    val sectorId: SectorId,
)

/**
 * Sealed interface for registration operation results.
 */
sealed interface RegistrationResult {
    data class Success(
        val member: Member,
    ) : RegistrationResult

    data class Approved(
        val member: Member,
        val temporaryPassword: String,
    ) : RegistrationResult

    data class Rejected(
        val memberId: MemberId,
    ) : RegistrationResult

    data object EmailAlreadyRegistered : RegistrationResult

    data object MemberNotFound : RegistrationResult

    data object InvalidSector : RegistrationResult

    data class InvalidStatus(
        val current: String,
        val expected: String,
    ) : RegistrationResult

    data class ValidationError(
        val errors: List<String>,
    ) : RegistrationResult
}
