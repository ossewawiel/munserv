package com.munserv.admin.domain

import com.munserv.auth.domain.MemberStatus
import com.munserv.shared.enums.GroundAdminStatus
import com.munserv.shared.types.MemberId
import java.time.Instant

/**
 * Domain model representing a member with their issue count and Ground Admin info.
 * Used for the admin members list endpoint.
 */
data class MemberWithStats(
    val id: MemberId,
    val firstName: String,
    val surname: String,
    val phoneNumber: String,
    val address: String,
    val status: MemberStatus,
    val issueCount: Int,
    val joinedAt: Instant,
    // Ground Admin fields
    val isGroundAdmin: Boolean = false,
    val groundAdminStatus: GroundAdminStatus? = null,
    val hasPendingApplication: Boolean = false,
    val hasInvitationPending: Boolean = false,
    val pendingApplicationId: String? = null,
)
