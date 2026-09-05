package com.munserv.auth.service

import com.munserv.shared.types.MemberId
import io.jsonwebtoken.ExpiredJwtException
import io.jsonwebtoken.JwtException
import io.jsonwebtoken.Jwts
import io.jsonwebtoken.security.Keys
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import java.time.Clock
import java.time.Duration
import java.util.Date
import java.util.UUID
import javax.crypto.SecretKey

/**
 * Types of tokens issued by the JWT service.
 */
enum class TokenType {
    ACCESS,
    REFRESH,
}

/**
 * Token validation errors.
 */
enum class TokenError {
    EXPIRED,
    INVALID,
}

/**
 * Result of token validation.
 */
data class TokenValidationResult(
    val isValid: Boolean,
    val subject: String? = null,
    val role: String? = null,
    val tokenType: TokenType? = null,
    val error: TokenError? = null,
    val scope: String? = null,
)

/**
 * Access and refresh token pair.
 */
data class TokenPair(
    val accessToken: String,
    val refreshToken: String,
    val expiresIn: Long,
)

/**
 * Service for generating and validating JWT tokens.
 */
@Service
class JwtService(
    @Value("\${munserv.jwt.secret:default-secret-key-that-is-at-least-256-bits-long-for-hs256}")
    private val secret: String,
    @Value("\${munserv.jwt.access-token-ttl:PT15M}")
    private val accessTokenTtl: Duration = Duration.ofMinutes(15),
    @Value("\${munserv.jwt.refresh-token-ttl:P7D}")
    private val refreshTokenTtl: Duration = Duration.ofDays(7),
    private val clock: Clock = Clock.systemUTC(),
) {
    private val key: SecretKey = Keys.hmacShaKeyFor(secret.toByteArray())

    companion object {
        private const val CLAIM_ROLE = "role"
        private const val CLAIM_TOKEN_TYPE = "type"
        const val CLAIM_SCOPE = "scope"
        const val SCOPE_SUPPORT_GRANT = "support_grant"
    }

    /**
     * Generate an access token for a member.
     *
     * [scope] is written as the `scope` claim only when non-null; it carries
     * [SCOPE_SUPPORT_GRANT] for a login minted under a support grant.
     */
    fun generateAccessToken(
        memberId: MemberId,
        role: String,
        scope: String? = null,
    ): String {
        val now = Date.from(clock.instant())
        val expiry = Date.from(clock.instant().plus(accessTokenTtl))

        val builder =
            Jwts
                .builder()
                .subject(memberId.value.toString())
                .claim(CLAIM_ROLE, role)
                .claim(CLAIM_TOKEN_TYPE, TokenType.ACCESS.name)
                .issuedAt(now)
                .expiration(expiry)

        if (scope != null) {
            builder.claim(CLAIM_SCOPE, scope)
        }

        return builder.signWith(key).compact()
    }

    /**
     * Generate a refresh token for a member.
     */
    fun generateRefreshToken(memberId: MemberId): String {
        val now = Date.from(clock.instant())
        val expiry = Date.from(clock.instant().plus(refreshTokenTtl))

        return Jwts
            .builder()
            .subject(memberId.value.toString())
            .claim(CLAIM_TOKEN_TYPE, TokenType.REFRESH.name)
            .issuedAt(now)
            .expiration(expiry)
            .signWith(key)
            .compact()
    }

    /**
     * Generate both access and refresh tokens.
     */
    fun generateTokenPair(
        memberId: MemberId,
        role: String,
        scope: String? = null,
    ): TokenPair =
        TokenPair(
            accessToken = generateAccessToken(memberId, role, scope),
            refreshToken = generateRefreshToken(memberId),
            expiresIn = accessTokenTtl.toSeconds(),
        )

    /**
     * Validate a token and return its claims.
     */
    fun validateToken(token: String): TokenValidationResult {
        if (token.isBlank()) {
            return TokenValidationResult(isValid = false, error = TokenError.INVALID)
        }

        return try {
            val claims =
                Jwts
                    .parser()
                    .verifyWith(key)
                    .clock { Date.from(clock.instant()) }
                    .build()
                    .parseSignedClaims(token)
                    .payload

            val tokenTypeStr = claims[CLAIM_TOKEN_TYPE] as? String
            val tokenType =
                tokenTypeStr?.let {
                    try {
                        TokenType.valueOf(it)
                    } catch (e: IllegalArgumentException) {
                        null
                    }
                }

            TokenValidationResult(
                isValid = true,
                subject = claims.subject,
                role = claims[CLAIM_ROLE] as? String,
                tokenType = tokenType,
                scope = claims[CLAIM_SCOPE] as? String,
            )
        } catch (e: ExpiredJwtException) {
            TokenValidationResult(isValid = false, error = TokenError.EXPIRED)
        } catch (e: JwtException) {
            TokenValidationResult(isValid = false, error = TokenError.INVALID)
        } catch (e: Exception) {
            TokenValidationResult(isValid = false, error = TokenError.INVALID)
        }
    }

    /**
     * Extract member ID from a valid token.
     * Returns null if token is invalid.
     */
    fun extractMemberId(token: String): MemberId? {
        val result = validateToken(token)
        if (!result.isValid || result.subject == null) return null

        return try {
            MemberId(UUID.fromString(result.subject))
        } catch (e: IllegalArgumentException) {
            null
        }
    }
}
