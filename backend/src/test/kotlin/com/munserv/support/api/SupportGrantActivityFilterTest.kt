package com.munserv.support.api

import com.munserv.admin.domain.AdminRole
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.PodId
import com.munserv.support.domain.SupportGrant
import com.munserv.support.domain.SupportGrantId
import com.munserv.support.service.SupportAccessResult
import com.munserv.support.service.SupportAccessService
import com.munserv.support.service.SupportGrantView
import io.kotest.matchers.shouldBe
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import jakarta.servlet.FilterChain
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.security.core.context.SecurityContextHolder
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset
import java.util.UUID

class SupportGrantActivityFilterTest {
    private val supportAccessService: SupportAccessService = mockk(relaxed = true)
    private val fixedInstant = Instant.parse("2026-09-05T10:00:00Z")
    private val clock = Clock.fixed(fixedInstant, ZoneOffset.UTC)
    private val filter = SupportGrantActivityFilter(supportAccessService, clock)

    private val request: HttpServletRequest = mockk(relaxed = true)
    private val response: HttpServletResponse = mockk(relaxed = true)
    private val chain: FilterChain = mockk(relaxed = true)

    @BeforeEach
    fun setUp() {
        // OncePerRequestFilter treats a non-null "already filtered" attribute as a signal to
        // skip doFilterInternal; MockK's relaxed request would otherwise return a mock here.
        every { request.getAttribute(any()) } returns null
    }

    @AfterEach
    fun tearDown() {
        SecurityContextHolder.clearContext()
    }

    private fun activeGrant(id: SupportGrantId): SupportGrant =
        SupportGrant.create(
            id = id,
            podId = PodId.generate(),
            grantedRole = AdminRole.POD_ADMIN,
            purpose = "Investigate duplicate issue reports",
            grantedBy = AdminId.generate(),
            grantedAt = fixedInstant,
        )

    @Test
    fun `should record activity when the grant is still active`() {
        val grantId = SupportGrantId.generate()
        SecurityContextHolder.getContext().authentication =
            UsernamePasswordAuthenticationToken(
                grantId.value.toString(),
                null,
                listOf(SimpleGrantedAuthority("ROLE_SUPPORT_GRANT")),
            )
        every { supportAccessService.currentGrant(grantId) } returns
            SupportAccessResult.Granted(SupportGrantView(activeGrant(grantId), "Thandi Mokoena"))
        every { supportAccessService.recordActivity(grantId, fixedInstant) } returns true

        filter.doFilter(request, response, chain)

        verify { supportAccessService.recordActivity(grantId, fixedInstant) }
        verify { chain.doFilter(request, response) }
    }

    @Test
    fun `should clear the security context when the grant is no longer active`() {
        val grantId = SupportGrantId.generate()
        SecurityContextHolder.getContext().authentication =
            UsernamePasswordAuthenticationToken(
                grantId.value.toString(),
                null,
                listOf(SimpleGrantedAuthority("ROLE_SUPPORT_GRANT")),
            )
        every { supportAccessService.currentGrant(grantId) } returns SupportAccessResult.GrantNotActive

        filter.doFilter(request, response, chain)

        SecurityContextHolder.getContext().authentication shouldBe null
        verify(exactly = 0) { supportAccessService.recordActivity(any(), any()) }
        verify { chain.doFilter(request, response) }
    }

    @Test
    fun `should clear the security context when the grant no longer exists`() {
        val grantId = SupportGrantId.generate()
        SecurityContextHolder.getContext().authentication =
            UsernamePasswordAuthenticationToken(
                grantId.value.toString(),
                null,
                listOf(SimpleGrantedAuthority("ROLE_SUPPORT_GRANT")),
            )
        every { supportAccessService.currentGrant(grantId) } returns SupportAccessResult.NotFound

        filter.doFilter(request, response, chain)

        SecurityContextHolder.getContext().authentication shouldBe null
        verify { chain.doFilter(request, response) }
    }

    @Test
    fun `should do nothing when the principal is an ordinary admin`() {
        val adminId = UUID.randomUUID()
        SecurityContextHolder.getContext().authentication =
            UsernamePasswordAuthenticationToken(
                adminId.toString(),
                null,
                listOf(SimpleGrantedAuthority("ROLE_ADMIN")),
            )

        filter.doFilter(request, response, chain)

        verify(exactly = 0) { supportAccessService.recordActivity(any(), any()) }
        verify { chain.doFilter(request, response) }
    }

    @Test
    fun `should do nothing when there is no authentication`() {
        filter.doFilter(request, response, chain)

        verify(exactly = 0) { supportAccessService.recordActivity(any(), any()) }
        verify { chain.doFilter(request, response) }
    }
}
