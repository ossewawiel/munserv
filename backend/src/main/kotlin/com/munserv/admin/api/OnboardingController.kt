package com.munserv.admin.api

import com.munserv.admin.service.OnboardingResult
import com.munserv.admin.service.OnboardingService
import com.munserv.shared.types.AdminId
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.media.Content
import io.swagger.v3.oas.annotations.media.Schema
import io.swagger.v3.oas.annotations.responses.ApiResponse
import io.swagger.v3.oas.annotations.responses.ApiResponses
import io.swagger.v3.oas.annotations.security.SecurityRequirement
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

/**
 * REST controller for administrator onboarding.
 * Handles password change and profile completion for new administrators.
 */
@RestController
@RequestMapping("/api/v1/admin/onboarding")
@Tag(name = "Admin Onboarding", description = "Onboarding endpoints for new administrators")
@SecurityRequirement(name = "bearerAuth")
class OnboardingController(
    private val onboardingService: OnboardingService,
) {
    @Operation(
        summary = "Get onboarding status",
        description = "Returns the current onboarding status and requirements for the authenticated admin.",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Status retrieved successfully",
                content = [Content(schema = Schema(implementation = OnboardingStatusResponse::class))],
            ),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
        ],
    )
    @GetMapping("/status")
    fun getStatus(): ResponseEntity<*> {
        val adminId =
            getCurrentAdminId()
                ?: return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorBody("unauthorized", "Not authenticated"),
                )

        return when (val result = onboardingService.getOnboardingStatus(adminId)) {
            is OnboardingResult.Success ->
                ResponseEntity.ok(OnboardingStatusResponse.from(result.admin))
            is OnboardingResult.Completed ->
                ResponseEntity.ok(OnboardingStatusResponse.from(result.admin))
            is OnboardingResult.AdminNotFound ->
                ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorBody("unauthorized", "Admin not found"),
                )
            else ->
                ResponseEntity.internalServerError().build<Any>()
        }
    }

    @Operation(
        summary = "Change password",
        description = "Change password during onboarding. Required when status is PENDING.",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Password changed successfully",
                content = [Content(schema = Schema(implementation = OnboardingStatusResponse::class))],
            ),
            ApiResponse(responseCode = "400", description = "Validation error or invalid step"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
        ],
    )
    @PostMapping("/change-password")
    fun changePassword(
        @Valid @RequestBody request: ChangePasswordRequest,
    ): ResponseEntity<*> {
        val adminId =
            getCurrentAdminId()
                ?: return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorBody("unauthorized", "Not authenticated"),
                )

        return when (val result = onboardingService.changePassword(adminId, request.newPassword)) {
            is OnboardingResult.Success ->
                ResponseEntity.ok(OnboardingStatusResponse.from(result.admin))
            is OnboardingResult.Completed ->
                ResponseEntity.ok(OnboardingStatusResponse.from(result.admin))
            is OnboardingResult.AdminNotFound ->
                ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorBody("unauthorized", "Admin not found"),
                )
            is OnboardingResult.ValidationError ->
                ResponseEntity.badRequest().body(
                    ErrorBody("validation_error", result.errors.joinToString("; ")),
                )
            is OnboardingResult.InvalidStep ->
                ResponseEntity.badRequest().body(
                    ErrorBody(
                        "invalid_step",
                        "Password change not required. Current status: ${result.current.toDbValue()}",
                    ),
                )
        }
    }

    @Operation(
        summary = "Complete profile",
        description = "Complete profile during onboarding. Required when status is PASSWORD_CHANGED.",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Profile completed successfully",
                content = [Content(schema = Schema(implementation = OnboardingStatusResponse::class))],
            ),
            ApiResponse(responseCode = "400", description = "Validation error or invalid step"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
        ],
    )
    @PostMapping("/complete-profile")
    fun completeProfile(
        @Valid @RequestBody request: CompleteProfileRequest,
    ): ResponseEntity<*> {
        val adminId =
            getCurrentAdminId()
                ?: return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorBody("unauthorized", "Not authenticated"),
                )

        return when (
            val result =
                onboardingService.completeProfile(
                    adminId,
                    request.displayName,
                    request.knownAs,
                    request.contactPhone,
                    request.address,
                )
        ) {
            is OnboardingResult.Success ->
                ResponseEntity.ok(OnboardingStatusResponse.from(result.admin))
            is OnboardingResult.Completed ->
                ResponseEntity.ok(OnboardingStatusResponse.from(result.admin))
            is OnboardingResult.AdminNotFound ->
                ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorBody("unauthorized", "Admin not found"),
                )
            is OnboardingResult.ValidationError ->
                ResponseEntity.badRequest().body(
                    ErrorBody("validation_error", result.errors.joinToString("; ")),
                )
            is OnboardingResult.InvalidStep ->
                ResponseEntity.badRequest().body(
                    ErrorBody(
                        "invalid_step",
                        "Profile completion not required. Current status: ${result.current.toDbValue()}",
                    ),
                )
        }
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
 * Response DTO for onboarding status.
 */
@Schema(description = "Onboarding status response")
data class OnboardingStatusResponse(
    @field:Schema(description = "Current onboarding status", example = "pending")
    val status: String,
    @field:Schema(description = "Whether password change is required", example = "true")
    val requiresPasswordChange: Boolean,
    @field:Schema(description = "Whether profile completion is required", example = "false")
    val requiresProfileCompletion: Boolean,
    @field:Schema(description = "Whether onboarding is complete", example = "false")
    val isOnboarded: Boolean,
    @field:Schema(description = "Current display name", example = "John Smith")
    val displayName: String,
) {
    companion object {
        fun from(admin: com.munserv.admin.domain.Admin): OnboardingStatusResponse =
            OnboardingStatusResponse(
                status = admin.onboardingStatus.toDbValue(),
                requiresPasswordChange = admin.requiresPasswordChange,
                requiresProfileCompletion = admin.requiresProfileCompletion,
                isOnboarded = !admin.requiresOnboarding,
                displayName = admin.displayName,
            )
    }
}

/**
 * Request DTO for password change.
 */
@Schema(description = "Password change request")
data class ChangePasswordRequest(
    @field:NotBlank(message = "New password is required")
    @field:Size(min = 8, max = 100, message = "Password must be between 8 and 100 characters")
    @field:Schema(description = "New password", example = "NewSecurePass123")
    val newPassword: String,
)

/**
 * Request DTO for profile completion.
 */
@Schema(description = "Profile completion request")
data class CompleteProfileRequest(
    @field:Size(max = 100, message = "Display name must be 100 characters or less")
    @field:Schema(description = "Display name (optional update)", example = "John D. Smith")
    val displayName: String? = null,
    @field:Size(max = 50, message = "Known-as must be 50 characters or less")
    @field:Schema(description = "Nickname or preferred name", example = "Johnny")
    val knownAs: String? = null,
    @field:Size(max = 20, message = "Contact phone must be 20 characters or less")
    @field:Schema(description = "Contact phone number", example = "+27123456789")
    val contactPhone: String? = null,
    @field:Size(max = 255, message = "Address must be 255 characters or less")
    @field:Schema(description = "Physical address", example = "123 Main St, City")
    val address: String? = null,
)
