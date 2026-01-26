package com.munserv.auth.service

import com.munserv.admin.repository.AdminRepository
import com.munserv.auth.config.AdminConfig
import com.munserv.auth.domain.Member
import com.munserv.auth.domain.MemberStatus
import com.munserv.auth.domain.PhoneNumber
import com.munserv.auth.domain.Pin
import com.munserv.auth.repository.MemberRepository
import com.munserv.bootstrap.config.BootstrapConfig
import com.munserv.bootstrap.service.BootstrapService
import com.munserv.pod.repository.PodRepository
import com.munserv.sectors.repository.SectorRepository
import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import java.time.Clock
import java.time.Duration
import java.time.Instant
import java.time.ZoneOffset

class AuthServiceTest {
    private lateinit var authService: AuthService
    private lateinit var memberRepository: MemberRepository
    private lateinit var otpService: OtpService
    private lateinit var jwtService: JwtService
    private lateinit var adminConfig: AdminConfig
    private lateinit var adminRepository: AdminRepository
    private lateinit var sectorRepository: SectorRepository
    private lateinit var bootstrapConfig: BootstrapConfig
    private lateinit var bootstrapService: BootstrapService
    private lateinit var podRepository: PodRepository
    private lateinit var clock: Clock

    private val testPhone = "+27821234567"
    private val testPin = "1234"
    private val testSectorId = SectorId.generate()
    private val testMemberId = MemberId.generate()

    @BeforeEach
    fun setup() {
        clock = Clock.fixed(Instant.parse("2026-01-05T10:00:00Z"), ZoneOffset.UTC)
        memberRepository = mockk()
        adminRepository = mockk()
        sectorRepository = mockk()
        bootstrapConfig = BootstrapConfig(enabled = false, email = null, password = null)
        bootstrapService = mockk()
        podRepository = mockk()
        otpService = OtpService(clock = clock, otpTtl = Duration.ofMinutes(5))
        jwtService =
            JwtService(
                secret = "test-secret-key-that-is-at-least-256-bits-long-for-hs256-algorithm",
                accessTokenTtl = Duration.ofMinutes(15),
                refreshTokenTtl = Duration.ofDays(7),
                clock = clock,
            )
        adminConfig =
            AdminConfig(
                email = "admin@test.example.com",
                password = "testpass123",
                id = "550e8400-e29b-41d4-a716-446655440020",
                displayName = "Test Admin",
                sectorId = "550e8400-e29b-41d4-a716-446655440001",
                role = "SECTOR_ADMIN",
                sectorName = "Test Sector",
                sectorCenterLat = -26.2041,
                sectorCenterLng = 28.0473,
            )
        // Default: no pod found (MVP single-pod not set up yet)
        every { podRepository.findFirst() } returns null
        authService =
            AuthService(
                memberRepository,
                otpService,
                jwtService,
                adminConfig,
                adminRepository,
                sectorRepository,
                bootstrapConfig,
                bootstrapService,
                podRepository,
            )
    }

    // Registration flow tests

    @Test
    fun `register should send OTP for new phone number`() {
        val phone = PhoneNumber.fromString(testPhone)
        every { memberRepository.existsByPhoneHash(phone.hash()) } returns false

        val result = authService.register(testPhone)

        result.shouldBeInstanceOf<AuthResult.OtpSent>()
    }

    @Test
    fun `register should fail for already registered phone`() {
        val phone = PhoneNumber.fromString(testPhone)
        every { memberRepository.existsByPhoneHash(phone.hash()) } returns true

        val result = authService.register(testPhone)

        result.shouldBeInstanceOf<AuthResult.PhoneAlreadyRegistered>()
    }

    @Test
    fun `register should fail for invalid phone number`() {
        val result = authService.register("invalid")

        result.shouldBeInstanceOf<AuthResult.InvalidPhoneNumber>()
    }

    @Test
    fun `verifyOtp should succeed for valid OTP`() {
        val phone = PhoneNumber.fromString(testPhone)
        every { memberRepository.existsByPhoneHash(phone.hash()) } returns false

        // Generate OTP
        authService.register(testPhone)

        // Get the generated OTP from the service
        val otp = otpService.generate(phone)

        val result = authService.verifyOtp(testPhone, otp)

        result.shouldBeInstanceOf<AuthResult.OtpVerified>()
    }

    @Test
    fun `verifyOtp should fail for invalid OTP`() {
        val phone = PhoneNumber.fromString(testPhone)
        every { memberRepository.existsByPhoneHash(phone.hash()) } returns false

        authService.register(testPhone)

        val result = authService.verifyOtp(testPhone, "000000")

        result.shouldBeInstanceOf<AuthResult.InvalidOtp>()
    }

    @Test
    fun `completeRegistration should create member and return tokens`() {
        val phone = PhoneNumber.fromString(testPhone)
        val pin = Pin.fromString(testPin)
        val location = GeoPoint(27.9833, -26.1367)

        val memberSlot = slot<Member>()
        every { memberRepository.save(capture(memberSlot)) } answers { memberSlot.captured }

        val result =
            authService.completeRegistration(
                CompleteRegistrationCommand(
                    phone = testPhone,
                    pin = testPin,
                    firstName = "John",
                    surname = "Doe",
                    address = "123 Main Street",
                    sectorId = testSectorId.value.toString(),
                    location = location,
                ),
            )

        result.shouldBeInstanceOf<AuthResult.RegistrationComplete>()
        val success = result as AuthResult.RegistrationComplete
        success.tokens.accessToken.isNotBlank() shouldBe true
        success.tokens.refreshToken.isNotBlank() shouldBe true

        verify { memberRepository.save(any()) }
        memberSlot.captured.firstName shouldBe "John"
        memberSlot.captured.surname shouldBe "Doe"
        memberSlot.captured.phoneHash shouldBe phone.hash()
        memberSlot.captured.pinHash shouldBe pin.hash()
    }

    @Test
    fun `completeRegistration should fail for invalid PIN`() {
        val result =
            authService.completeRegistration(
                CompleteRegistrationCommand(
                    phone = testPhone,
                    // Too short (3 digits instead of 4)
                    pin = "123",
                    firstName = "John",
                    surname = "Doe",
                    address = "123 Main Street",
                    sectorId = testSectorId.value.toString(),
                    location = GeoPoint(27.9833, -26.1367),
                ),
            )

        result.shouldBeInstanceOf<AuthResult.InvalidPin>()
    }

    // Login flow tests

    @Test
    fun `login should succeed for valid credentials`() {
        val phone = PhoneNumber.fromString(testPhone)
        val pin = Pin.fromString(testPin)
        val member = createTestMember(phone.hash(), pin.hash())

        every { memberRepository.findByPhoneHash(phone.hash()) } returns member

        val result = authService.login(testPhone, testPin)

        result.shouldBeInstanceOf<AuthResult.LoginSuccess>()
        val success = result as AuthResult.LoginSuccess
        success.tokens.accessToken.isNotBlank() shouldBe true
    }

    @Test
    fun `login should fail for unknown phone`() {
        val phone = PhoneNumber.fromString(testPhone)
        every { memberRepository.findByPhoneHash(phone.hash()) } returns null

        val result = authService.login(testPhone, testPin)

        result.shouldBeInstanceOf<AuthResult.InvalidCredentials>()
    }

    @Test
    fun `login should fail for wrong PIN`() {
        val phone = PhoneNumber.fromString(testPhone)
        val pin = Pin.fromString(testPin)
        val member = createTestMember(phone.hash(), pin.hash())

        every { memberRepository.findByPhoneHash(phone.hash()) } returns member

        val result = authService.login(testPhone, "9999") // Wrong PIN

        result.shouldBeInstanceOf<AuthResult.InvalidCredentials>()
    }

    @Test
    fun `login should fail for suspended member`() {
        val phone = PhoneNumber.fromString(testPhone)
        val pin = Pin.fromString(testPin)
        val member = createTestMember(phone.hash(), pin.hash(), MemberStatus.Suspended)

        every { memberRepository.findByPhoneHash(phone.hash()) } returns member

        val result = authService.login(testPhone, testPin)

        result.shouldBeInstanceOf<AuthResult.AccountSuspended>()
    }

    @Test
    fun `login should fail for deleted member`() {
        val phone = PhoneNumber.fromString(testPhone)
        val pin = Pin.fromString(testPin)
        val member = createTestMember(phone.hash(), pin.hash(), MemberStatus.Deleted)

        every { memberRepository.findByPhoneHash(phone.hash()) } returns member

        val result = authService.login(testPhone, testPin)

        result.shouldBeInstanceOf<AuthResult.AccountSuspended>()
    }

    // Token refresh tests

    @Test
    fun `refreshToken should return new tokens for valid refresh token`() {
        val member = createTestMember("phonehash", "pinhash")
        val refreshToken = jwtService.generateRefreshToken(member.id)

        every { memberRepository.findById(member.id) } returns member

        val result = authService.refreshToken(refreshToken)

        result.shouldBeInstanceOf<AuthResult.TokenRefreshed>()
        val success = result as AuthResult.TokenRefreshed
        success.tokens.accessToken.isNotBlank() shouldBe true
    }

    @Test
    fun `refreshToken should fail for invalid token`() {
        val result = authService.refreshToken("invalid.token")

        result.shouldBeInstanceOf<AuthResult.InvalidToken>()
    }

    @Test
    fun `refreshToken should fail if member not found`() {
        val refreshToken = jwtService.generateRefreshToken(testMemberId)

        every { memberRepository.findById(testMemberId) } returns null

        val result = authService.refreshToken(refreshToken)

        result.shouldBeInstanceOf<AuthResult.InvalidToken>()
    }

    private fun createTestMember(
        phoneHash: String,
        pinHash: String,
        status: MemberStatus = MemberStatus.Active,
    ): Member =
        Member(
            id = testMemberId,
            sectorId = testSectorId,
            email = "test@example.com",
            emailHash = "abc123def456",
            passwordHash = null,
            mustChangePassword = false,
            phoneHash = phoneHash,
            pinHash = pinHash,
            phone = "+27821234567",
            firstName = "John",
            surname = "Doe",
            address = "123 Main Street",
            registrationLocation = GeoPoint(27.9833, -26.1367),
            status = status,
            createdAt = clock.instant(),
            updatedAt = clock.instant(),
        )
}
