package com.munserv.photos.repository

import com.munserv.issues.domain.IssueId
import com.munserv.photos.domain.IssuePhoto
import com.munserv.photos.domain.PhotoId
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.time.Instant
import java.util.UUID

/**
 * JPA Entity for issue_photos table.
 * Converts between database representation and domain model.
 */
@Entity
@Table(name = "issue_photos")
class IssuePhotoEntity(
    @Id
    val id: UUID,
    @Column(name = "issue_id", nullable = false)
    val issueId: UUID,
    @Column(nullable = false)
    val url: String,
    @Column(name = "thumbnail_url", nullable = false)
    val thumbnailUrl: String,
    @Column(name = "sort_order", nullable = false)
    val sortOrder: Int,
    @Column(name = "created_at", nullable = false)
    val createdAt: Instant,
) {
    /**
     * Convert JPA entity to domain model.
     */
    fun toDomain(): IssuePhoto =
        IssuePhoto(
            id = PhotoId(id),
            issueId = IssueId(issueId),
            url = url,
            thumbnailUrl = thumbnailUrl,
            sortOrder = sortOrder,
            createdAt = createdAt,
        )

    companion object {
        /**
         * Convert domain model to JPA entity.
         */
        fun fromDomain(photo: IssuePhoto): IssuePhotoEntity =
            IssuePhotoEntity(
                id = photo.id.value,
                issueId = photo.issueId.value,
                url = photo.url,
                thumbnailUrl = photo.thumbnailUrl,
                sortOrder = photo.sortOrder,
                createdAt = photo.createdAt,
            )
    }
}
