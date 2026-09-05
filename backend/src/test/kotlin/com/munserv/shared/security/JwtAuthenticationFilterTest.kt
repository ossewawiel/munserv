package com.munserv.shared.security

import com.munserv.auth.service.JwtService
import com.munserv.shared.types.MemberId
import io.kotest.matchers.shouldBe
import io.mockk.every
import io.mockk.mockk
import jakarta.servlet.FilterChain
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Test
import org.springframework.security.core.context.SecurityContextHolder
import java.time.Clock
import java.time.Duration
import java.time.Instant
import java.time.ZoneOffset
import java.util.UUID

class JwtAuthenticationFilterTest {
    private val clock = Clock.fixed(Instant.parse("2026-09-05T10:00:00Z"), ZoneOffset.UTC)
    private val jwtService =
        JwtService(
            secret = "test-secret-key-that-is-at-least-256-bits-long-for-hs256-algorithm",
            accessTokenTtl = Duration.ofMinutes(15),
            refreshTokenTtl = Duration.ofDays(7),
            clock = clock,
        )
    private val filter = JwtAuthenticationFilter(jwtService)

    private val response: HttpServletResponse = mockk(relaxed = true)
    private val chain: FilterChain = mockk(relaxed = true)

    @AfterEach
    fun tearDown() {
        SecurityContextHolder.clearContext()
    }

    private fun requestWithHeader(token: String): HttpServletRequest {
        val request: HttpServletRequest = mockk(relaxed = true)
        every { request.getAttribute(any()) } returns null
        every { request.getHeader("Authorization") } returns "Bearer $token"
        return request
    }

    @Test
    fun `should add ROLE_SUPPORT_GRANT when the token carries the support grant scope`() {
        val grantId = MemberId(UUID.randomUUID())
        val token = jwtService.generateAccessToken(grantId, "pod_admin", JwtService.SCOPE_SUPPORT_GRANT)

        filter.doFilter(requestWithHeader(token), response, chain)

        val authorities =
            SecurityContextHolder
                .getContext()
                .authentication!!
                .authorities
                .map { it.authority }
        authorities shouldBe listOf("ROLE_POD_ADMIN", "ROLE_SUPPORT_GRANT")
    }

    @Test
    fun `should not add ROLE_SUPPORT_GRANT for an ordinary admin token`() {
        val adminId = MemberId(UUID.randomUUID())
        val token = jwtService.generateAccessToken(adminId, "admin")

        filter.doFilter(requestWithHeader(token), response, chain)

        val authorities =
            SecurityContextHolder
                .getContext()
                .authentication!!
                .authorities
                .map { it.authority }
        authorities shouldBe listOf("ROLE_ADMIN")
    }
}
