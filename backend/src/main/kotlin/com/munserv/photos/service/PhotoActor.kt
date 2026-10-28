package com.munserv.photos.service

import com.munserv.issues.domain.Issue
import com.munserv.shared.types.MemberId

/**
 * Who is acting on a photo. A ground admin authenticates with a member token, so
 * the ground-admin check is a separate question the service asks of the verification module.
 */
sealed interface PhotoActor {
    data class Member(
        val id: MemberId,
    ) : PhotoActor

    data object Admin : PhotoActor
}

fun PhotoActor.isReporterOrAdminOf(issue: Issue): Boolean =
    when (this) {
        is PhotoActor.Admin -> true
        is PhotoActor.Member -> id == issue.reporterId
    }
