package com.munserv.pod.api

import com.munserv.admin.domain.AdminRole
import com.munserv.pod.service.PodResult
import com.munserv.pod.service.PodService
import com.munserv.shared.security.RequireRole
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.PodId
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.media.Content
import io.swagger.v3.oas.annotations.media.Schema
import io.swagger.v3.oas.annotations.responses.ApiResponse
import io.swagger.v3.oas.annotations.responses.ApiResponses
import io.swagger.v3.oas.annotations.security.SecurityRequirement
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PatchMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

/**
 * REST controller for pod settings and setup status.
 * Provides endpoints for Pod Chiefs to view and manage pod configuration.
 *
 * All endpoints require POD_CHIEF role.
 */
@RestController
@RequestMapping("/api/v1/pod")
@Tag(name = "Pod Settings", description = "Pod configuration and setup status endpoints. Requires pod_chief role.")
@SecurityRequirement(name = "bearerAuth")
@RequireRole(AdminRole.POD_CHIEF)
class PodController(
    private val podService: PodService,
    private val podIdResolver: PodIdResolver,
) {
    @Operation(
        summary = "Get pod setup status",
        description = "Returns the setup completion status for the current pod, including any missing steps.",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Setup status retrieved successfully",
                content = [Content(schema = Schema(implementation = PodSetupStatusResponse::class))],
            ),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "403", description = "Insufficient permissions"),
            ApiResponse(responseCode = "404", description = "Pod not found"),
        ],
    )
    @GetMapping("/status")
    fun getSetupStatus(): ResponseEntity<*> {
        val podId =
            getCurrentPodId()
                ?: return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorResponse("unauthorized", "Could not determine pod for current user"),
                )

        return when (val result = podService.getSetupStatus(podId)) {
            is PodResult.Success -> {
                ResponseEntity.ok(PodSetupStatusResponse.from(result.data))
            }

            is PodResult.NotFound -> {
                ResponseEntity.notFound().build<Any>()
            }

            is PodResult.ValidationError -> {
                ResponseEntity.badRequest().body(ErrorResponse("validation_error", result.errors.joinToString("; ")))
            }

            is PodResult.Unauthorized -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(ErrorResponse("forbidden", result.reason))
            }
        }
    }

    @Operation(
        summary = "Get pod settings",
        description = "Returns the settings (name, logo) for the current pod.",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Settings retrieved successfully",
                content = [Content(schema = Schema(implementation = PodSettingsResponse::class))],
            ),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "403", description = "Insufficient permissions"),
            ApiResponse(responseCode = "404", description = "Pod not found"),
        ],
    )
    @GetMapping("/settings")
    fun getSettings(): ResponseEntity<*> {
        val podId =
            getCurrentPodId()
                ?: return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorResponse("unauthorized", "Could not determine pod for current user"),
                )

        return when (val result = podService.getSettings(podId)) {
            is PodResult.Success -> {
                ResponseEntity.ok(PodSettingsResponse.from(result.data))
            }

            is PodResult.NotFound -> {
                ResponseEntity.notFound().build<Any>()
            }

            is PodResult.ValidationError -> {
                ResponseEntity.badRequest().body(ErrorResponse("validation_error", result.errors.joinToString("; ")))
            }

            is PodResult.Unauthorized -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(ErrorResponse("forbidden", result.reason))
            }
        }
    }

    @Operation(
        summary = "Update pod settings",
        description = "Partially update the pod settings. Only provided fields will be updated.",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Settings updated successfully",
                content = [Content(schema = Schema(implementation = PodSettingsResponse::class))],
            ),
            ApiResponse(responseCode = "400", description = "Validation error"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "403", description = "Insufficient permissions"),
            ApiResponse(responseCode = "404", description = "Pod not found"),
        ],
    )
    @PatchMapping("/settings")
    fun updateSettings(
        @Valid @RequestBody request: UpdatePodSettingsRequest,
    ): ResponseEntity<*> {
        val podId =
            getCurrentPodId()
                ?: return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorResponse("unauthorized", "Could not determine pod for current user"),
                )

        return when (val result = podService.updateSettings(podId, request.toCommand())) {
            is PodResult.Success -> {
                ResponseEntity.ok(PodSettingsResponse.from(result.data))
            }

            is PodResult.NotFound -> {
                ResponseEntity.notFound().build<Any>()
            }

            is PodResult.ValidationError -> {
                ResponseEntity.badRequest().body(ErrorResponse("validation_error", result.errors.joinToString("; ")))
            }

            is PodResult.Unauthorized -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(ErrorResponse("forbidden", result.reason))
            }
        }
    }

    private fun getCurrentPodId(): PodId? {
        val adminId = getCurrentAdminId() ?: return null
        return podIdResolver.resolvePodId(adminId)
    }

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

/**
 * Simple error response body.
 */
@Schema(description = "Error response")
data class ErrorResponse(
    @field:Schema(description = "Error code", example = "validation_error")
    val code: String,
    @field:Schema(description = "Error message", example = "Pod name is required")
    val message: String,
)
