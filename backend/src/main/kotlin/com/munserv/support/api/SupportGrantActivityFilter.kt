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
 * Records support grant activity for requests authenticated as the super user.
 *
 * The grant id arrives as the JWT subject when the super user logs in under a support grant
 * (W29). Until then this filter is effectively a no-op, since no such token is ever minted.
 */
@Component
class SupportGrantActivityFilter(
    private val supportAccessService: SupportAccessService,
    private val clock: Clock = Clock.systemUTC(),
) : OncePerRequestFilter() {
    companion object {
        private const val SUPER_USER_AUTHORITY = "ROLE_SUPER_USER"
    }

    override fun doFilterInternal(
        request: HttpServletRequest,
        response: HttpServletResponse,
        filterChain: FilterChain,
    ) {
        val authentication = SecurityContextHolder.getContext().authentication

        if (authentication != null && authentication.authorities.any { it.authority == SUPER_USER_AUTHORITY }) {
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
