package com.munserv.pod.repository

import com.munserv.pod.domain.Pod
import com.munserv.shared.types.PodId
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import org.hibernate.annotations.JdbcTypeCode
import org.hibernate.type.SqlTypes
import java.time.Instant
import java.util.UUID

/**
 * JPA entity for pods table.
 */
@Entity
@Table(name = "pods")
class PodEntity(
    @Id
    val id: UUID,
    @Column(nullable = false, length = 100)
    val name: String,
    @Column(name = "display_name", length = 200)
    val displayName: String?,
    @Column(name = "logo_url", length = 500)
    val logoUrl: String?,
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(nullable = false, columnDefinition = "jsonb")
    val config: Map<String, Any>,
    @Column(name = "setup_completed_at")
    val setupCompletedAt: Instant?,
    @Column(name = "created_at", nullable = false)
    val createdAt: Instant,
    @Column(name = "updated_at", nullable = false)
    val updatedAt: Instant,
) {
    /**
     * Convert JPA entity to domain model.
     */
    fun toDomain(): Pod =
        Pod(
            id = PodId(id),
            name = name,
            displayName = displayName ?: Pod.displayNameFor(name),
            logoUrl = logoUrl,
            config = config,
            setupCompletedAt = setupCompletedAt,
            createdAt = createdAt,
            updatedAt = updatedAt,
        )

    companion object {
        /**
         * Convert domain model to JPA entity.
         */
        fun fromDomain(pod: Pod): PodEntity =
            PodEntity(
                id = pod.id.value,
                name = pod.name,
                displayName = pod.displayName,
                logoUrl = pod.logoUrl,
                config = pod.config,
                setupCompletedAt = pod.setupCompletedAt,
                createdAt = pod.createdAt,
                updatedAt = pod.updatedAt,
            )
    }
}
