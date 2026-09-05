package com.munserv.support.api

import com.munserv.shared.security.JwtAuthenticationFilter
import com.munserv.support.domain.SupportGrantId
import com.munserv.support.service.SupportAccessResult
import com.munserv.support.service.SupportAccessService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.media.Content
import io.swagger.v3.oas.annotations.media.Schema
import io.swagger.v3.oas.annotations.responses.ApiResponse
import io.swagger.v3.oas.annotations.responses.ApiResponses
import io.swagger.v3.oas.annotations.security.SecurityRequirement
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

/**
 * Self-service endpoint for a grant-scoped token to fetch its own support grant.
 *
 * Unlike [SupportAccessController], this controller carries no class-level `@RequireRole`:
 * a grant-scoped token never holds `pod_chief`, so the pod chief `@RequireRole` gate would
 * always deny it.
 */
@RestController
@RequestMapping("/api/v1/support-access")
@Tag(name = "Support Access", description = "Self-service endpoint for a support grant holder.")
@SecurityRequirement(name = "bearerAuth")
class SupportGrantSelfController(
    private val supportAccessService: SupportAccessService,
) {
    @Operation(
        summary = "Get the caller's own support grant",
        description = "Return the grant carried by the caller's own grant-scoped token, so the client can refresh a slid expiry.",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Grant retrieved successfully",
                content = [Content(schema = Schema(implementation = SupportGrantResponse::class))],
            ),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "403", description = "Not a support grant token, or the grant is revoked or expired"),
        ],
    )
    @GetMapping("/grants/current")
    fun getCurrentGrant(): ResponseEntity<*> {
        val authentication =
            SecurityContextHolder.getContext().authentication
                ?: return unauthorized()

        val subject = authentication.principal as? String ?: return unauthorized()

        if (authentication.authorities.none { it.authority == JwtAuthenticationFilter.SUPPORT_GRANT_AUTHORITY }) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                SupportAccessErrorResponse("not_support_grant", "Not authenticated with a support grant token"),
            )
        }

        val grantId =
            try {
                SupportGrantId(UUID.fromString(subject))
            } catch (e: IllegalArgumentException) {
                return unauthorized()
            }

        return when (val result = supportAccessService.currentGrant(grantId)) {
            is SupportAccessResult.Granted -> {
                ResponseEntity.ok(result.view.toResponse())
            }

            is SupportAccessResult.NotFound -> {
                ResponseEntity.notFound().build<Any>()
            }

            is SupportAccessResult.GrantNotActive -> {
                ResponseEntity.status(HttpStatus.CONFLICT).body(
                    SupportAccessErrorResponse("grant_not_active", "The support grant is not active"),
                )
            }

            else -> {
                ResponseEntity.internalServerError().build<Any>()
            }
        }
    }

    private fun unauthorized(): ResponseEntity<*> =
        ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
            SupportAccessErrorResponse("unauthorized", "Not authenticated"),
        )
}
