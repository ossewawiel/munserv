package com.munserv.groundadmin.api

import com.munserv.shared.enums.GroundAdminStatus
import java.time.Instant

// ==================== Request DTOs ====================

data class InviteGroundAdminRequest(
    val message: String? = null,
)

data class ApproveGroundAdminRequest(
    val applicationId: String,
)

data class DeclineGroundAdminRequest(
    val applicationId: String,
    val reason: String,
)

data class RevokeGroundAdminRequest(
    val reason: String,
)

data class UpdateGroundAdminStatusRequest(
    val status: GroundAdminStatus,
)

data class StepDownRequest(
    val reason: String? = null,
)

data class AcceptInvitationRequest(
    val applicationId: String,
)

data class DeclineInvitationRequest(
    val applicationId: String,
    val reason: String? = null,
)

data class ApproveApplicationRequest(
    val applicationId: String,
)

data class DeclineApplicationRequest(
    val applicationId: String,
    val reason: String,
)

// ==================== Response DTOs ====================

data class GroundAdminApplicationResponse(
    val applicationId: String,
    val status: String,
)

data class GroundAdminResponse(
    val id: String,
    val memberId: String,
    val name: String,
    val phone: String,
    val status: GroundAdminStatus,
    val since: Instant,
    val responseRate: Double,
    val pendingVerifications: Int,
)

data class GroundAdminListResponse(
    val items: List<GroundAdminResponse>,
    val total: Int,
)

data class GroundAdminInfoResponse(
    val status: GroundAdminStatus,
    val since: Instant,
    val responseRate: Double,
    val pendingVerifications: Int,
    val totalVerifications: Int,
)

data class MemberGroundAdminStatusResponse(
    val isGroundAdmin: Boolean,
    val groundAdminStatus: GroundAdminStatus?,
    val hasPendingApplication: Boolean,
    val hasPendingInvitation: Boolean,
)
