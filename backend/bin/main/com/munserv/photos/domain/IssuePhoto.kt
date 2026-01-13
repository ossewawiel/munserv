package com.munserv.photos.domain

import com.munserv.issues.domain.IssueId
import java.time.Instant

/**
 * Domain entity representing a photo attached to an issue.
 * Immutable - use copy() for updates.
 */
data class IssuePhoto(
    val id: PhotoId,
    val issueId: IssueId,
    val url: String,
    val thumbnailUrl: String,
    val sortOrder: Int,
    val createdAt: Instant,
)
