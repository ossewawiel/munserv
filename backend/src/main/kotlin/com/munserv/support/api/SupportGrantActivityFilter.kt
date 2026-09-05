package com.munserv.support.api

import com.munserv.shared.security.JwtAuthenticationFilter
import com.munserv.support.domain.SupportGrantId
import com.munserv.support.service.SupportAccessResult
import com.munserv.support.service.SupportAccessService
import jakarta.servlet.FilterChain
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.stereotype.Component
import org.springframework.web.filter.OncePerRequestFilter
import java.time.Clock
import java.time.Instant
import java.util.UUID

/**
 * Records support grant activity for requests authenticated with a grant-scoped token, and
 * clears the security context the moment the underlying grant is no longer active.
 *
 * The grant id arrives as the JWT subject when the super user logs in under a support grant
 * (B9); such a token carries the `ROLE_SUPPORT_GRANT` authority alongside the granted role.
 * Without this check, a revoked or expired grant would keep serving `.authenticated()`-only
 * endpoints for the remaining life of the access token, since neither
 * [com.munserv.shared.security.JwtAuthenticationFilter] nor Spring Security itself re-checks
 * grant status once the token validates.
 */
@Component
class SupportGrantActivityFilter(
    private val supportAccessService: SupportAccessService,
    private val clock: Clock = Clock.systemUTC(),
) : OncePerRequestFilter() {
    override fun doFilterInternal(
        request: HttpServletRequest,
        response: HttpServletResponse,
        filterChain: FilterChain,
    ) {
        val authentication = SecurityContextHolder.getContext().authentication

        if (authentication != null &&
            authentication.authorities.any { it.authority == JwtAuthenticationFilter.SUPPORT_GRANT_AUTHORITY }
        ) {
            val subject = authentication.principal as? String
            val grantId =
                subject?.let {
                    try {
                        SupportGrantId(UUID.fromString(it))
                    } catch (e: IllegalArgumentException) {
                        null
                    }
                }

            when (grantId?.let { supportAccessService.currentGrant(it) }) {
                is SupportAccessResult.Granted -> supportAccessService.recordActivity(grantId, Instant.now(clock))
                else -> SecurityContextHolder.clearContext()
            }
        }

        filterChain.doFilter(request, response)
    }
}
