package com.munserv.auth.service

import com.munserv.auth.domain.Member
import com.munserv.auth.domain.MemberStatus
import com.munserv.auth.domain.PhoneNumber
import com.munserv.auth.domain.Pin
import com.munserv.auth.repository.MemberRepository
import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import org.springframework.stereotype.Service
import java.util.UUID

/**
 * Service for handling authentication flows.
 * Coordinates OTP, JWT, and Member operations.
 */
@Service
class AuthService(
    private val memberRepository: MemberRepository,
    private val otpService: OtpService,
    private val jwtService: JwtService,
) {
    companion object {
        private const val MEMBER_ROLE = "member"
    }

    /**
     * Start registration flow by sending OTP.
     */
    fun register(phoneString: String): AuthResult {
        val phone =
            try {
                PhoneNumber.fromString(phoneString)
            } catch (e: IllegalArgumentException) {
                return AuthResult.InvalidPhoneNumber
            }

        if (memberRepository.existsByPhoneHash(phone.hash())) {
            return AuthResult.PhoneAlreadyRegistered
        }

        otpService.generate(phone)
        return AuthResult.OtpSent
    }

    /**
     * Verify OTP code.
     */
    fun verifyOtp(
        phoneString: String,
        code: String,
    ): AuthResult {
        val phone =
            try {
                PhoneNumber.fromString(phoneString)
            } catch (e: IllegalArgumentException) {
                return AuthResult.InvalidPhoneNumber
            }

        return if (otpService.verify(phone, code)) {
            AuthResult.OtpVerified
        } else {
            AuthResult.InvalidOtp
        }
    }

    /**
     * Complete registration by creating member account.
     */
    fun completeRegistration(
        phone: String,
        pin: String,
        firstName: String,
        surname: String,
        address: String,
        sectorId: String,
        latitude: Double,
        longitude: Double,
    ): AuthResult {
        val phoneNumber =
            try {
                PhoneNumber.fromString(phone)
            } catch (e: IllegalArgumentException) {
                return AuthResult.InvalidPhoneNumber
            }

        val pinValue =
            try {
                Pin.fromString(pin)
            } catch (e: IllegalArgumentException) {
                return AuthResult.InvalidPin
            }

        val sectorIdValue =
            try {
                SectorId(UUID.fromString(sectorId))
            } catch (e: IllegalArgumentException) {
                return AuthResult.InvalidPin // Could add specific error
            }

        val member =
            Member(
                id = MemberId.generate(),
                sectorId = sectorIdValue,
                phoneHash = phoneNumber.hash(),
                pinHash = pinValue.hash(),
                firstName = firstName,
                surname = surname,
                address = address,
                registrationLocation = GeoPoint(latitude, longitude),
            )

        val savedMember = memberRepository.save(member)
        val tokens = jwtService.generateTokenPair(savedMember.id, MEMBER_ROLE)

        return AuthResult.RegistrationComplete(
            memberId = savedMember.id,
            tokens = tokens,
        )
    }

    /**
     * Login with phone and PIN.
     */
    fun login(
        phoneString: String,
        pinString: String,
    ): AuthResult {
        val phone =
            try {
                PhoneNumber.fromString(phoneString)
            } catch (e: IllegalArgumentException) {
                return AuthResult.InvalidCredentials
            }

        val member =
            memberRepository.findByPhoneHash(phone.hash())
                ?: return AuthResult.InvalidCredentials

        // Check account status
        if (member.status != MemberStatus.Active) {
            return AuthResult.AccountSuspended
        }

        // Verify PIN
        if (!Pin.verify(pinString, member.pinHash)) {
            return AuthResult.InvalidCredentials
        }

        val tokens = jwtService.generateTokenPair(member.id, MEMBER_ROLE)

        return AuthResult.LoginSuccess(
            memberId = member.id,
            tokens = tokens,
        )
    }

    /**
     * Refresh tokens using a valid refresh token.
     */
    fun refreshToken(refreshToken: String): AuthResult {
        val validation = jwtService.validateToken(refreshToken)

        if (!validation.isValid || validation.tokenType != TokenType.REFRESH) {
            return AuthResult.InvalidToken
        }

        val memberId =
            jwtService.extractMemberId(refreshToken)
                ?: return AuthResult.InvalidToken

        val member =
            memberRepository.findById(memberId)
                ?: return AuthResult.InvalidToken

        val tokens = jwtService.generateTokenPair(member.id, MEMBER_ROLE)

        return AuthResult.TokenRefreshed(tokens)
    }
}
