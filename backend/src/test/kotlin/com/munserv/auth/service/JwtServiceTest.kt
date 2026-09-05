package com.munserv.auth.service

import com.munserv.shared.types.MemberId
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.string.shouldNotBeBlank
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import java.time.Clock
import java.time.Duration
import java.time.Instant
import java.time.ZoneOffset
import java.util.UUID

class JwtServiceTest {
    private lateinit var jwtService: JwtService
    private lateinit var clock: Clock

    private val testSecret = "test-secret-key-that-is-at-least-256-bits-long-for-hs256-algorithm"
    private val memberId = MemberId(UUID.fromString("550e8400-e29b-41d4-a716-446655440010"))

    @BeforeEach
    fun setup() {
        clock = Clock.fixed(Instant.parse("2026-01-05T10:00:00Z"), ZoneOffset.UTC)
        jwtService =
            JwtService(
                secret = testSecret,
                accessTokenTtl = Duration.ofMinutes(15),
                refreshTokenTtl = Duration.ofDays(7),
                clock = clock,
            )
    }

    @Test
    fun `should generate access token`() {
        val token = jwtService.generateAccessToken(memberId, "member")

        token.shouldNotBeBlank()
    }

    @Test
    fun `should generate refresh token`() {
        val token = jwtService.generateRefreshToken(memberId)

        token.shouldNotBeBlank()
    }

    @Test
    fun `access and refresh tokens should be different`() {
        val accessToken = jwtService.generateAccessToken(memberId, "member")
        val refreshToken = jwtService.generateRefreshToken(memberId)

        accessToken shouldNotBe refreshToken
    }

    @Test
    fun `should validate valid access token`() {
        val token = jwtService.generateAccessToken(memberId, "member")

        val result = jwtService.validateToken(token)

        result.isValid shouldBe true
        result.subject shouldBe memberId.value.toString()
        result.role shouldBe "member"
        result.tokenType shouldBe TokenType.ACCESS
    }

    @Test
    fun `should validate valid refresh token`() {
        val token = jwtService.generateRefreshToken(memberId)

        val result = jwtService.validateToken(token)

        result.isValid shouldBe true
        result.subject shouldBe memberId.value.toString()
        result.tokenType shouldBe TokenType.REFRESH
    }

    @Test
    fun `should reject expired access token`() {
        val token = jwtService.generateAccessToken(memberId, "member")

        // Move clock past access token expiry (15 minutes)
        val expiredClock = Clock.fixed(Instant.parse("2026-01-05T10:20:00Z"), ZoneOffset.UTC)
        val expiredJwtService =
            JwtService(
                secret = testSecret,
                accessTokenTtl = Duration.ofMinutes(15),
                refreshTokenTtl = Duration.ofDays(7),
                clock = expiredClock,
            )

        val result = expiredJwtService.validateToken(token)

        result.isValid shouldBe false
        result.error shouldBe TokenError.EXPIRED
    }

    @Test
    fun `should reject malformed token`() {
        val result = jwtService.validateToken("not.a.valid.jwt")

        result.isValid shouldBe false
        result.error shouldBe TokenError.INVALID
    }

    @Test
    fun `should reject token with invalid signature`() {
        val token = jwtService.generateAccessToken(memberId, "member")

        // Create service with different secret
        val otherJwtService =
            JwtService(
                secret = "different-secret-key-that-is-at-least-256-bits-long-for-hs256",
                accessTokenTtl = Duration.ofMinutes(15),
                refreshTokenTtl = Duration.ofDays(7),
                clock = clock,
            )

        val result = otherJwtService.validateToken(token)

        result.isValid shouldBe false
        result.error shouldBe TokenError.INVALID
    }

    @Test
    fun `should reject empty token`() {
        val result = jwtService.validateToken("")

        result.isValid shouldBe false
        result.error shouldBe TokenError.INVALID
    }

    @Test
    fun `should generate token pair`() {
        val tokenPair = jwtService.generateTokenPair(memberId, "member")

        tokenPair.accessToken.shouldNotBeBlank()
        tokenPair.refreshToken.shouldNotBeBlank()
        tokenPair.expiresIn shouldBe 900 // 15 minutes in seconds
    }

    @Test
    fun `should extract member ID from valid token`() {
        val token = jwtService.generateAccessToken(memberId, "member")

        val extractedId = jwtService.extractMemberId(token)

        extractedId shouldBe memberId
    }

    @Test
    fun `should return null member ID for invalid token`() {
        val extractedId = jwtService.extractMemberId("invalid.token")

        extractedId shouldBe null
    }

    @Test
    fun `admin role should be included in token`() {
        val adminId = MemberId(UUID.fromString("550e8400-e29b-41d4-a716-446655440020"))
        val token = jwtService.generateAccessToken(adminId, "admin")

        val result = jwtService.validateToken(token)

        result.isValid shouldBe true
        result.role shouldBe "admin"
    }

    @Test
    fun `should round-trip the support grant scope claim when generating a scoped access token`() {
        val grantId = MemberId(UUID.fromString("550e8400-e29b-41d4-a716-446655440030"))
        val token = jwtService.generateAccessToken(grantId, "pod_admin", JwtService.SCOPE_SUPPORT_GRANT)

        val result = jwtService.validateToken(token)

        result.isValid shouldBe true
        result.subject shouldBe grantId.value.toString()
        result.role shouldBe "pod_admin"
        result.scope shouldBe JwtService.SCOPE_SUPPORT_GRANT
    }

    @Test
    fun `should not carry a scope claim for an ordinary access token`() {
        val token = jwtService.generateAccessToken(memberId, "member")

        val result = jwtService.validateToken(token)

        result.scope shouldBe null
    }
}
