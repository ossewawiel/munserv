package com.munserv.shared.security

import com.munserv.auth.service.JwtService
import com.munserv.auth.service.TokenType
import jakarta.servlet.FilterChain
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.stereotype.Component
import org.springframework.web.filter.OncePerRequestFilter

/**
 * Filter that validates JWT tokens and sets up Spring Security context.
 */
@Component
class JwtAuthenticationFilter(
    private val jwtService: JwtService,
) : OncePerRequestFilter() {
    companion object {
        private const val AUTHORIZATION_HEADER = "Authorization"
        private const val BEARER_PREFIX = "Bearer "
        const val SUPPORT_GRANT_AUTHORITY = "ROLE_SUPPORT_GRANT"
    }

    override fun doFilterInternal(
        request: HttpServletRequest,
        response: HttpServletResponse,
        filterChain: FilterChain,
    ) {
        val authHeader = request.getHeader(AUTHORIZATION_HEADER)

        if (authHeader != null && authHeader.startsWith(BEARER_PREFIX)) {
            val token = authHeader.substring(BEARER_PREFIX.length)
            val validation = jwtService.validateToken(token)
            val subject = validation.subject

            if (validation.isValid && validation.tokenType == TokenType.ACCESS && subject != null) {
                val authorities =
                    buildList {
                        validation.role?.let { add(SimpleGrantedAuthority("ROLE_${it.uppercase()}")) }
                        if (validation.scope == JwtService.SCOPE_SUPPORT_GRANT) {
                            add(SimpleGrantedAuthority(SUPPORT_GRANT_AUTHORITY))
                        }
                    }

                val authentication =
                    UsernamePasswordAuthenticationToken(
                        subject,
                        null,
                        authorities,
                    )

                SecurityContextHolder.getContext().authentication = authentication
            }
        }

        filterChain.doFilter(request, response)
    }
}
