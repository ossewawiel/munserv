package com.munserv.photos.repository

import com.munserv.issues.domain.IssueId
import com.munserv.photos.domain.IssuePhoto
import com.munserv.photos.domain.PhotoId

/**
 * Repository interface for IssuePhoto persistence.
 * Abstracts the persistence layer from the domain.
 */
interface IssuePhotoRepository {
    /**
     * Find a photo by its ID.
     */
    fun findById(id: PhotoId): IssuePhoto?

    /**
     * Find all photos for an issue, ordered by sort_order.
     */
    fun findByIssueId(issueId: IssueId): List<IssuePhoto>

    /**
     * Save a photo.
     */
    fun save(photo: IssuePhoto): IssuePhoto

    /**
     * Delete a photo by ID.
     */
    fun deleteById(id: PhotoId)

    /**
     * Delete all photos for an issue.
     */
    fun deleteByIssueId(issueId: IssueId)

    /**
     * Get the next sort order for photos of an issue.
     */
    fun getNextSortOrder(issueId: IssueId): Int
}
