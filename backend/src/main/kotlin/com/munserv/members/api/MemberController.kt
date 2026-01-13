package com.munserv.members.api

import com.munserv.members.service.MemberResult
import com.munserv.members.service.MemberService
import com.munserv.shared.api.ErrorBody
import com.munserv.shared.api.ErrorCodes
import com.munserv.shared.api.ErrorResponse
import com.munserv.shared.types.MemberId
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.responses.ApiResponse
import io.swagger.v3.oas.annotations.responses.ApiResponses
import io.swagger.v3.oas.annotations.security.SecurityRequirement
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

/**
 * REST controller for member profile operations.
 * Provides endpoints for authenticated members to access their own profile.
 */
@RestController
@RequestMapping("/api/v1/members")
@Tag(name = "Members", description = "Member profile operations")
@SecurityRequirement(name = "bearerAuth")
class MemberController(
    private val memberService: MemberService,
) {
    /**
     * Get the current authenticated member's profile.
     * Requires valid JWT token.
     */
    @Operation(
        summary = "Get current member profile",
        description = "Retrieve the profile of the currently authenticated member",
    )
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "Profile retrieved successfully"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "404", description = "Member not found"),
        ],
    )
    @GetMapping("/me")
    fun getCurrentMember(
        @AuthenticationPrincipal memberId: String?,
    ): ResponseEntity<*> {
        if (memberId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ErrorResponse(ErrorBody(ErrorCodes.UNAUTHORIZED, "Authentication required")))
        }

        val memberIdValue =
            try {
                MemberId(UUID.fromString(memberId))
            } catch (e: IllegalArgumentException) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse(ErrorBody(ErrorCodes.UNAUTHORIZED, "Invalid authentication")))
            }

        return when (val result = memberService.findById(memberIdValue)) {
            is MemberResult.Success -> ResponseEntity.ok(result.member.toResponse())
            is MemberResult.NotFound ->
                ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ErrorResponse(ErrorBody(ErrorCodes.NOT_FOUND, "Member not found")))
        }
    }
}
