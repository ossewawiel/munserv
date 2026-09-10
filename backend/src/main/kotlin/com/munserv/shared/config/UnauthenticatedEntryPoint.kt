package com.munserv.shared.config

import com.munserv.shared.api.ErrorBody
import com.munserv.shared.api.ErrorCodes
import com.munserv.shared.api.ErrorResponse
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.http.MediaType
import org.springframework.security.core.AuthenticationException
import org.springframework.security.web.AuthenticationEntryPoint
import org.springframework.stereotype.Component
import tools.jackson.databind.ObjectMapper

/**
 * Writes the standard [ErrorResponse] body for a request that reaches a protected
 * endpoint with no, expired or otherwise invalid authentication, so a client can
 * distinguish "not signed in" (401) from "signed in but not allowed" (403).
 */
@Component
class UnauthenticatedEntryPoint(
    private val objectMapper: ObjectMapper,
) : AuthenticationEntryPoint {
    override fun commence(
        request: HttpServletRequest,
        response: HttpServletResponse,
        authException: AuthenticationException,
    ) {
        response.status = HttpServletResponse.SC_UNAUTHORIZED
        response.contentType = MediaType.APPLICATION_JSON_VALUE
        response.characterEncoding = Charsets.UTF_8.name()

        val body = ErrorResponse(ErrorBody(ErrorCodes.UNAUTHENTICATED, "Authentication required"))
        objectMapper.writeValue(response.writer, body)
    }
}
