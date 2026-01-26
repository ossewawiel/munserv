package com.munserv.bootstrap.api

import com.munserv.bootstrap.service.BootstrapResult
import com.munserv.bootstrap.service.BootstrapService
import com.munserv.pod.repository.PodRepository
import com.munserv.shared.types.PodId
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.media.Content
import io.swagger.v3.oas.annotations.media.Schema
import io.swagger.v3.oas.annotations.responses.ApiResponse
import io.swagger.v3.oas.annotations.responses.ApiResponses
import io.swagger.v3.oas.annotations.security.SecurityRequirement
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

/**
 * Controller for pod bootstrap operations.
 *
 * Provides endpoints for super users to bootstrap a fresh pod by creating
 * the first Pod Chief administrator.
 */
@RestController
@RequestMapping("/api/v1/bootstrap")
@Tag(name = "Bootstrap", description = "Pod bootstrap endpoints for super user")
class BootstrapController(
    private val bootstrapService: BootstrapService,
    private val podRepository: PodRepository,
) {
    /**
     * Create the first Pod Chief for a fresh pod.
     *
     * This endpoint is only available to authenticated super users.
     * It creates the initial Pod Chief administrator who will then
     * manage the pod setup and other administrators.
     */
    @PostMapping("/pod-chief")
    @Operation(
        summary = "Create Pod Chief",
        description = "Creates the first Pod Chief for a fresh pod. Requires SUPER_USER role.",
    )
    @SecurityRequirement(name = "bearerAuth")
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "201",
                description = "Pod Chief created successfully",
                content = [Content(schema = Schema(implementation = CreatePodChiefResponse::class))],
            ),
            ApiResponse(
                responseCode = "400",
                description = "Validation error",
                content = [Content(schema = Schema(implementation = BootstrapValidationErrorResponse::class))],
            ),
            ApiResponse(
                responseCode = "401",
                description = "Unauthorized - requires super user authentication",
            ),
            ApiResponse(
                responseCode = "409",
                description = "Conflict - Pod Chief already exists or email in use",
                content = [Content(schema = Schema(implementation = BootstrapErrorResponse::class))],
            ),
        ],
    )
    fun createPodChief(
        @RequestBody request: CreatePodChiefRequest,
    ): ResponseEntity<*> {
        // Get the current pod (MVP: single pod deployment)
        val pod =
            podRepository.findFirst()
                ?: return ResponseEntity.internalServerError().body(
                    BootstrapErrorResponse("no_pod", "No pod found"),
                )
        val podId = PodId(pod.id.value)

        return when (val result = bootstrapService.createPodChief(request.email, request.displayName, podId)) {
            is BootstrapResult.PodChiefCreated ->
                ResponseEntity.status(201).body(
                    CreatePodChiefResponse(
                        id = result.admin.id.value.toString(),
                        email = result.admin.email,
                        displayName = result.admin.displayName,
                        role = result.admin.role.toDbValue(),
                        temporaryPassword = result.temporaryPassword,
                        createdAt = result.admin.createdAt.toString(),
                    ),
                )

            is BootstrapResult.EmailAlreadyExists ->
                ResponseEntity.status(409).body(
                    BootstrapErrorResponse("email_exists", "Email already in use"),
                )

            is BootstrapResult.PodAlreadyBootstrapped ->
                ResponseEntity.status(409).body(
                    BootstrapErrorResponse("already_bootstrapped", "Pod Chief already exists"),
                )

            is BootstrapResult.ValidationError ->
                ResponseEntity.badRequest().body(
                    BootstrapValidationErrorResponse(messages = result.errors),
                )

            is BootstrapResult.NotAuthorized ->
                ResponseEntity.status(403).body(
                    BootstrapErrorResponse("not_authorized", "Not authorized to create Pod Chief"),
                )
        }
    }
}
