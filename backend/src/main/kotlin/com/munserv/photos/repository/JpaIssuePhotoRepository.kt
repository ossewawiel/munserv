package com.munserv.photos.repository

import com.munserv.issues.domain.IssueId
import com.munserv.photos.domain.IssuePhoto
import com.munserv.photos.domain.PhotoId
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.findByIdOrNull
import org.springframework.stereotype.Repository
import java.util.UUID

/**
 * Spring Data JPA repository for IssuePhotoEntity.
 */
interface SpringDataIssuePhotoRepository : JpaRepository<IssuePhotoEntity, UUID> {
    @Query("SELECT p FROM IssuePhotoEntity p WHERE p.issueId = :issueId ORDER BY p.sortOrder ASC")
    fun findByIssueIdOrderBySortOrder(issueId: UUID): List<IssuePhotoEntity>

    @Query("SELECT COALESCE(MAX(p.sortOrder), -1) + 1 FROM IssuePhotoEntity p WHERE p.issueId = :issueId")
    fun findNextSortOrder(issueId: UUID): Int

    fun deleteByIssueId(issueId: UUID)
}

/**
 * Implementation of IssuePhotoRepository using Spring Data JPA.
 * Converts between domain and JPA entities.
 */
@Repository
class JpaIssuePhotoRepository(
    private val jpa: SpringDataIssuePhotoRepository,
) : IssuePhotoRepository {
    override fun findById(id: PhotoId): IssuePhoto? = jpa.findByIdOrNull(id.value)?.toDomain()

    override fun findByIssueId(issueId: IssueId): List<IssuePhoto> = jpa.findByIssueIdOrderBySortOrder(issueId.value).map { it.toDomain() }

    override fun save(photo: IssuePhoto): IssuePhoto = jpa.save(IssuePhotoEntity.fromDomain(photo)).toDomain()

    override fun deleteById(id: PhotoId) {
        jpa.deleteById(id.value)
    }

    override fun deleteByIssueId(issueId: IssueId) {
        jpa.deleteByIssueId(issueId.value)
    }

    override fun getNextSortOrder(issueId: IssueId): Int = jpa.findNextSortOrder(issueId.value)
}
