package com.munserv.shared.config

import com.munserv.TestContainersConfig
import com.munserv.auth.service.JwtService
import com.munserv.shared.types.MemberId
import io.jsonwebtoken.Jwts
import io.jsonwebtoken.security.Keys
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc
import org.springframework.context.annotation.Import
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import java.time.Instant
import java.time.temporal.ChronoUnit
import java.util.Date

/**
 * A client must be able to tell "not signed in" (401) from "not allowed" (403).
 * [UnauthenticatedEntryPoint] is what makes that true across every endpoint
 * guarded by `.authenticated()` or `.hasRole()` in [SecurityConfig].
 */
@SpringBootTest
@Import(TestContainersConfig::class)
@AutoConfigureMockMvc
@ActiveProfiles("test")
class SecurityConfigTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var jwtService: JwtService

    // JwtService falls back to this secret (see JwtService's @Value default) because no
    // `munserv.jwt.secret` property is set in any profile; used here only to hand-craft a
    // token whose expiry is already in the past.
    private val fallbackSecret = "default-secret-key-that-is-at-least-256-bits-long-for-hs256"

    @Test
    fun `should answer 401 with the standard body when no token is sent`() {
        mockMvc
            .get("/api/v1/members/me")
            .andExpect {
                status { isUnauthorized() }
                jsonPath("$.error.code") { value("UNAUTHENTICATED") }
                jsonPath("$.error.message") { value("Authentication required") }
            }
    }

    @Test
    fun `should answer 401 when the token is expired`() {
        val key = Keys.hmacShaKeyFor(fallbackSecret.toByteArray())
        val expiredToken =
            Jwts
                .builder()
                .subject("550e8400-e29b-41d4-a716-446655440010")
                .claim("role", "member")
                .claim("type", "ACCESS")
                .issuedAt(Date.from(Instant.now().minus(1, ChronoUnit.HOURS)))
                .expiration(Date.from(Instant.now().minus(30, ChronoUnit.MINUTES)))
                .signWith(key)
                .compact()

        mockMvc
            .get("/api/v1/members/me") {
                header("Authorization", "Bearer $expiredToken")
            }.andExpect {
                status { isUnauthorized() }
                jsonPath("$.error.code") { value("UNAUTHENTICATED") }
                jsonPath("$.error.message") { value("Authentication required") }
            }
    }

    @Test
    fun `should answer 403 when the role is not allowed`() {
        val memberId = MemberId.fromString("550e8400-e29b-41d4-a716-446655440010")
        val memberToken = jwtService.generateAccessToken(memberId, "member")

        mockMvc
            .get("/api/v1/admin/dashboard") {
                header("Authorization", "Bearer $memberToken")
            }.andExpect {
                status { isForbidden() }
            }
    }

    @Test
    fun `expired token result should not be valid`() {
        // Sanity check documenting the contract JwtAuthenticationFilter relies on:
        // an expired token must not produce an authentication, so the entry point fires.
        val key = Keys.hmacShaKeyFor(fallbackSecret.toByteArray())
        val expiredToken =
            Jwts
                .builder()
                .subject("550e8400-e29b-41d4-a716-446655440010")
                .claim("role", "member")
                .claim("type", "ACCESS")
                .issuedAt(Date.from(Instant.now().minus(1, ChronoUnit.HOURS)))
                .expiration(Date.from(Instant.now().minus(30, ChronoUnit.MINUTES)))
                .signWith(key)
                .compact()

        jwtService.validateToken(expiredToken).isValid shouldBe false
    }
}
