package com.munserv.auth.service

import com.munserv.auth.domain.PhoneNumber
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldHaveLength
import io.kotest.matchers.string.shouldMatch
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import java.time.Clock
import java.time.Duration
import java.time.Instant
import java.time.ZoneOffset

class OtpServiceTest {
    private lateinit var otpService: OtpService
    private lateinit var clock: Clock

    @BeforeEach
    fun setup() {
        clock = Clock.fixed(Instant.parse("2026-01-05T10:00:00Z"), ZoneOffset.UTC)
        otpService = OtpService(clock = clock, otpTtl = Duration.ofMinutes(5))
    }

    @Test
    fun `should generate 6-digit OTP`() {
        val phone = PhoneNumber.fromString("+27821234567")

        val otp = otpService.generate(phone)

        otp shouldHaveLength 6
        otp shouldMatch Regex("^[0-9]{6}$")
    }

    @Test
    fun `should generate different OTPs for same phone on different calls`() {
        val phone = PhoneNumber.fromString("+27821234567")

        val otp1 = otpService.generate(phone)
        val otp2 = otpService.generate(phone)

        // OTPs may occasionally be the same due to randomness, but check storage was updated
        otpService.verify(phone, otp2) shouldBe true
        // Old OTP should no longer work (replaced)
        if (otp1 != otp2) {
            otpService.verify(phone, otp1) shouldBe false
        }
    }

    @Test
    fun `should verify correct OTP`() {
        val phone = PhoneNumber.fromString("+27821234567")
        val otp = otpService.generate(phone)

        val result = otpService.verify(phone, otp)

        result shouldBe true
    }

    @Test
    fun `should reject incorrect OTP`() {
        val phone = PhoneNumber.fromString("+27821234567")
        otpService.generate(phone)

        val result = otpService.verify(phone, "000000")

        result shouldBe false
    }

    @Test
    fun `should reject OTP for unknown phone`() {
        val phone = PhoneNumber.fromString("+27821234567")

        val result = otpService.verify(phone, "123456")

        result shouldBe false
    }

    @Test
    fun `should reject expired OTP`() {
        val phone = PhoneNumber.fromString("+27821234567")
        val otp = otpService.generate(phone)

        // Move clock forward past expiry
        val expiredClock = Clock.fixed(Instant.parse("2026-01-05T10:06:00Z"), ZoneOffset.UTC)
        val expiredOtpService = OtpService(clock = expiredClock, otpTtl = Duration.ofMinutes(5))

        // Transfer the storage (simulating same storage reference)
        otpService.transferStorageTo(expiredOtpService)

        val result = expiredOtpService.verify(phone, otp)

        result shouldBe false
    }

    @Test
    fun `should invalidate OTP after successful verification`() {
        val phone = PhoneNumber.fromString("+27821234567")
        val otp = otpService.generate(phone)

        otpService.verify(phone, otp) shouldBe true
        otpService.verify(phone, otp) shouldBe false
    }

    @Test
    fun `should isolate OTPs between different phones`() {
        val phone1 = PhoneNumber.fromString("+27821234567")
        val phone2 = PhoneNumber.fromString("+27829999999")

        val otp1 = otpService.generate(phone1)
        val otp2 = otpService.generate(phone2)

        otpService.verify(phone1, otp1) shouldBe true
        otpService.verify(phone2, otp2) shouldBe true

        // Ensure OTPs don't work for other phones
        otpService.verify(phone1, otp2) shouldBe false
        otpService.verify(phone2, otp1) shouldBe false
    }

    @Test
    fun `should track failed attempts`() {
        val phone = PhoneNumber.fromString("+27821234567")
        otpService.generate(phone)

        // Make failed attempts
        otpService.verify(phone, "000001") shouldBe false
        otpService.verify(phone, "000002") shouldBe false
        otpService.verify(phone, "000003") shouldBe false

        otpService.getFailedAttempts(phone) shouldBe 3
    }

    @Test
    fun `should clear failed attempts on successful verification`() {
        val phone = PhoneNumber.fromString("+27821234567")
        val otp = otpService.generate(phone)

        // Make failed attempts
        otpService.verify(phone, "000001")
        otpService.verify(phone, "000002")

        // Successful verification
        otpService.verify(phone, otp) shouldBe true

        otpService.getFailedAttempts(phone) shouldBe 0
    }
}
