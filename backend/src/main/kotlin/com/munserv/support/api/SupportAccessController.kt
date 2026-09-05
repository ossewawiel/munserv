package com.munserv.support.api

import com.munserv.admin.domain.AdminRole
import com.munserv.shared.security.RequireRole
import com.munserv.shared.types.AdminId
import com.munserv.support.domain.SupportGrantId
import com.munserv.support.domain.SupportGrantStatus
import com.munserv.support.service.SupportAccessResult
import com.munserv.support.service.SupportAccessService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.media.Content
import io.swagger.v3.oas.annotations.media.Schema
import io.swagger.v3.oas.annotations.responses.ApiResponse
import io.swagger.v3.oas.annotations.responses.ApiResponses
import io.swagger.v3.oas.annotations.security.SecurityRequirement
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

/**
 * REST controller for temporary super user support access.
 *
 * All endpoints are restricted to pod chiefs managing their own pod.
 */
@RestController
@RequestMapping("/api/v1/support-access")
@Tag(name = "Support Access", description = "Endpoints for pod chiefs to grant, list and revoke support access.")
@SecurityRequirement(name = "bearerAuth")
@RequireRole(AdminRole.POD_CHIEF)
class SupportAccessController(
    private val supportAccessService: SupportAccessService,
) {
    @Operation(
        summary = "List support grants",
        description = "List support grants for the caller's pod, newest first.",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "List retrieved successfully",
                content = [Content(schema = Schema(implementation = SupportGrantListResponse::class))],
            ),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "403", description = "Not pod chief"),
        ],
    )
    @GetMapping("/grants")
    fun listGrants(
        @Parameter(description = "Filter by status")
        @RequestParam(required = false) status: String?,
    ): ResponseEntity<*> {
        val actorId = getCurrentAdminId() ?: return unauthorized()

        val parsedStatus =
            try {
                status?.let { SupportGrantStatus.fromDbValue(it) }
            } catch (e: IllegalArgumentException) {
                return ResponseEntity.badRequest().body(
                    SupportAccessValidationErrorResponse(messages = listOf("Unknown status: $status")),
                )
            }

        return when (val result = supportAccessService.list(actorId, parsedStatus)) {
            is SupportAccessResult.Grants -> {
                val items = result.views.map { it.toResponse() }
                ResponseEntity.ok(SupportGrantListResponse(items = items, total = items.size))
            }

            is SupportAccessResult.NotAuthorized -> {
                forbidden()
            }

            else -> {
                ResponseEntity.internalServerError().build<Any>()
            }
        }
    }

    @Operation(
        summary = "Grant support access",
        description = "Grant the super user temporary access to the caller's pod.",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "201",
                description = "Grant created successfully",
                content = [Content(schema = Schema(implementation = SupportGrantResponse::class))],
            ),
            ApiResponse(responseCode = "400", description = "Validation error"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "403", description = "Not pod chief"),
            ApiResponse(responseCode = "409", description = "Active grant already exists"),
        ],
    )
    @PostMapping("/grants")
    fun createGrant(
        @RequestBody request: GrantSupportAccessRequest,
    ): ResponseEntity<*> {
        val actorId = getCurrentAdminId() ?: return unauthorized()

        val grantedRole =
            try {
                AdminRole.fromDbValue(request.grantedRole)
            } catch (e: IllegalArgumentException) {
                return ResponseEntity.badRequest().body(
                    SupportAccessValidationErrorResponse(messages = listOf("Unknown role: ${request.grantedRole}")),
                )
            }

        return when (val result = supportAccessService.grant(actorId, grantedRole, request.purpose)) {
            is SupportAccessResult.Granted -> {
                ResponseEntity.status(HttpStatus.CREATED).body(result.view.toResponse())
            }

            is SupportAccessResult.ValidationError -> {
                ResponseEntity.badRequest().body(SupportAccessValidationErrorResponse(messages = result.errors))
            }

            is SupportAccessResult.NotAuthorized -> {
                forbidden()
            }

            is SupportAccessResult.ActiveGrantExists -> {
                ResponseEntity.status(HttpStatus.CONFLICT).body(
                    SupportAccessErrorResponse("active_grant_exists", "The pod already has an active support grant"),
                )
            }

            else -> {
                ResponseEntity.internalServerError().build<Any>()
            }
        }
    }

    @Operation(
        summary = "Revoke support access",
        description = "Revoke an active support grant immediately.",
    )
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "204", description = "Grant revoked successfully"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "403", description = "Not pod chief or grant belongs to another pod"),
            ApiResponse(responseCode = "404", description = "Grant not found"),
            ApiResponse(responseCode = "409", description = "Grant is not active"),
        ],
    )
    @DeleteMapping("/grants/{id}")
    fun revokeGrant(
        @Parameter(description = "Support grant UUID")
        @PathVariable id: String,
    ): ResponseEntity<*> {
        val actorId = getCurrentAdminId() ?: return unauthorized()
        val grantId = SupportGrantId(UUID.fromString(id))

        return when (val result = supportAccessService.revoke(actorId, grantId)) {
            is SupportAccessResult.Revoked -> {
                ResponseEntity.noContent().build<Any>()
            }

            is SupportAccessResult.NotFound -> {
                ResponseEntity.notFound().build<Any>()
            }

            is SupportAccessResult.NotAuthorized -> {
                forbidden()
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

    private fun forbidden(): ResponseEntity<*> =
        ResponseEntity.status(HttpStatus.FORBIDDEN).body(
            SupportAccessErrorResponse("not_pod_chief", "Not authorized as pod chief for this pod"),
        )

    private fun getCurrentAdminId(): AdminId? {
        val authentication =
            SecurityContextHolder.getContext().authentication
                ?: return null

        val subject =
            authentication.principal as? String
                ?: return null

        return try {
            AdminId(UUID.fromString(subject))
        } catch (e: IllegalArgumentException) {
            null
        }
    }
}
