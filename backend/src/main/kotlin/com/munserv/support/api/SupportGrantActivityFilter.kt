package com.munserv.support.api

import com.munserv.support.domain.SupportGrantId
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
 * Records support grant activity for requests authenticated with a grant-scoped token.
 *
 * The grant id arrives as the JWT subject when the super user logs in under a support grant
 * (B9); such a token carries the `ROLE_SUPPORT_GRANT` authority alongside the granted role.
 */
@Component
class SupportGrantActivityFilter(
    private val supportAccessService: SupportAccessService,
    private val clock: Clock = Clock.systemUTC(),
) : OncePerRequestFilter() {
    companion object {
        private const val SUPPORT_GRANT_AUTHORITY = "ROLE_SUPPORT_GRANT"
    }

    override fun doFilterInternal(
        request: HttpServletRequest,
        response: HttpServletResponse,
        filterChain: FilterChain,
    ) {
        val authentication = SecurityContextHolder.getContext().authentication

        if (authentication != null && authentication.authorities.any { it.authority == SUPPORT_GRANT_AUTHORITY }) {
            val subject = authentication.principal as? String
            val grantId =
                subject?.let {
                    try {
                        SupportGrantId(UUID.fromString(it))
                    } catch (e: IllegalArgumentException) {
                        null
                    }
                }

            grantId?.let { supportAccessService.recordActivity(it, Instant.now(clock)) }
        }

        filterChain.doFilter(request, response)
    }
}
