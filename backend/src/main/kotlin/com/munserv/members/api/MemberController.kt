package com.munserv.members.api

import com.munserv.auth.repository.MemberRepository
import com.munserv.shared.types.MemberId
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.responses.ApiResponse
import io.swagger.v3.oas.annotations.responses.ApiResponses
import io.swagger.v3.oas.annotations.security.SecurityRequirement
import io.swagger.v3.oas.annotations.tags.Tag
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
    private val memberRepository: MemberRepository,
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
    ): ResponseEntity<MemberProfileResponse> {
        if (memberId == null) {
            return ResponseEntity.status(401).build()
        }

        val memberIdValue =
            try {
                MemberId(UUID.fromString(memberId))
            } catch (e: IllegalArgumentException) {
                return ResponseEntity.status(401).build()
            }

        val member =
            memberRepository.findById(memberIdValue)
                ?: return ResponseEntity.notFound().build()

        return ResponseEntity.ok(member.toResponse())
    }
}
