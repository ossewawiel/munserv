package com.munserv.admin.repository

import com.munserv.admin.domain.Admin
import com.munserv.admin.domain.AdminRole
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.SectorId
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import org.hibernate.annotations.ColumnTransformer
import java.time.Instant
import java.util.UUID

/**
 * JPA entity for admins table.
 * Admins manage sectors via the web portal.
 */
@Entity
@Table(name = "admins")
class AdminEntity(
    @Id
    val id: UUID,
    @Column(name = "sector_id", nullable = false)
    val sectorId: UUID,
    @Column(nullable = false, length = 255)
    val email: String,
    @Column(name = "password_hash", nullable = false, length = 255)
    val passwordHash: String,
    @Column(name = "display_name", nullable = false, length = 100)
    val displayName: String,
    @Column(nullable = false, columnDefinition = "admin_role")
    @ColumnTransformer(write = "?::admin_role")
    val role: String,
    @Column(name = "created_at", nullable = false)
    val createdAt: Instant,
    @Column(name = "updated_at", nullable = false)
    val updatedAt: Instant,
    @Column(name = "deleted_at")
    val deletedAt: Instant? = null,
) {
    /**
     * Convert JPA entity to domain model.
     */
    fun toDomain(): Admin =
        Admin(
            id = AdminId(id),
            sectorId = SectorId(sectorId),
            email = email,
            displayName = displayName,
            role = AdminRole.fromDbValue(role),
            createdAt = createdAt,
            updatedAt = updatedAt,
            deletedAt = deletedAt,
        )

    companion object {
        /**
         * Convert domain model to JPA entity.
         */
        fun fromDomain(
            admin: Admin,
            passwordHash: String,
        ): AdminEntity =
            AdminEntity(
                id = admin.id.value,
                sectorId = admin.sectorId.value,
                email = admin.email,
                passwordHash = passwordHash,
                displayName = admin.displayName,
                role = admin.role.toDbValue(),
                createdAt = admin.createdAt,
                updatedAt = admin.updatedAt,
                deletedAt = admin.deletedAt,
            )
    }
}
