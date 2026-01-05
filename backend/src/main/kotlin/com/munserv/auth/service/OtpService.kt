package com.munserv.auth.service

import com.munserv.auth.domain.PhoneNumber
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import java.security.SecureRandom
import java.time.Clock
import java.time.Duration
import java.time.Instant
import java.util.concurrent.ConcurrentHashMap

/**
 * OTP data stored in memory.
 */
private data class OtpEntry(
    val code: String,
    val createdAt: Instant,
    val failedAttempts: Int = 0,
)

/**
 * Service for generating and verifying OTPs.
 * For development, OTPs are logged to console instead of being sent via SMS.
 */
@Service
class OtpService(
    private val clock: Clock = Clock.systemUTC(),
    @Value("\${munserv.otp.ttl:PT5M}")
    private val otpTtl: Duration = Duration.ofMinutes(5),
) {
    private val logger = LoggerFactory.getLogger(OtpService::class.java)
    private val random = SecureRandom()
    private val storage = ConcurrentHashMap<String, OtpEntry>()

    /**
     * Generate a 6-digit OTP for the given phone number.
     * In dev mode, logs the OTP to console.
     */
    fun generate(phone: PhoneNumber): String {
        val code = String.format("%06d", random.nextInt(1_000_000))
        val phoneHash = phone.hash()

        storage[phoneHash] = OtpEntry(code = code, createdAt = clock.instant())

        // Log OTP to console for development
        logger.info("OTP for ${phone.masked()}: $code")

        return code
    }

    /**
     * Verify an OTP for the given phone number.
     * Returns true if OTP is valid and not expired.
     * Invalidates the OTP after successful verification.
     */
    fun verify(
        phone: PhoneNumber,
        code: String,
    ): Boolean {
        val phoneHash = phone.hash()
        val entry = storage[phoneHash] ?: return false

        // Check expiry
        val expiresAt = entry.createdAt.plus(otpTtl)
        if (clock.instant().isAfter(expiresAt)) {
            storage.remove(phoneHash)
            return false
        }

        // Check code
        if (entry.code != code) {
            // Increment failed attempts
            storage[phoneHash] = entry.copy(failedAttempts = entry.failedAttempts + 1)
            return false
        }

        // Success - invalidate OTP and clear failed attempts
        storage.remove(phoneHash)
        return true
    }

    /**
     * Get the number of failed verification attempts for a phone number.
     */
    fun getFailedAttempts(phone: PhoneNumber): Int {
        val phoneHash = phone.hash()
        return storage[phoneHash]?.failedAttempts ?: 0
    }

    /**
     * Transfer storage to another OtpService instance (for testing).
     */
    fun transferStorageTo(other: OtpService) {
        other.storage.putAll(storage)
    }
}
