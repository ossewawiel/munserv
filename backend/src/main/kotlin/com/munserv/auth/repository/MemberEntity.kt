package com.munserv.auth.repository

import com.munserv.auth.domain.Member
import com.munserv.auth.domain.MemberStatus
import com.munserv.shared.enums.GroundAdminStatus
import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import org.hibernate.annotations.ColumnTransformer
import org.locationtech.jts.geom.Coordinate
import org.locationtech.jts.geom.GeometryFactory
import org.locationtech.jts.geom.Point
import org.locationtech.jts.geom.PrecisionModel
import java.math.BigDecimal
import java.time.Instant
import java.util.UUID

/**
 * JPA entity for members table.
 * Handles PostGIS geography type for registration_location.
 *
 * Supports both authentication flows:
 * 1. Legacy phone+PIN (mobile app registration with OTP)
 * 2. Email+password (web registration with admin approval)
 */
@Entity
@Table(name = "members")
class MemberEntity(
    @Id
    val id: UUID,
    @Column(name = "sector_id", nullable = false)
    val sectorId: UUID,
    // Email authentication fields (web registration)
    @Column(nullable = false, length = 255)
    val email: String,
    @Column(name = "email_hash", nullable = false, length = 64)
    val emailHash: String,
    @Column(name = "password_hash", length = 60)
    val passwordHash: String?,
    @Column(name = "must_change_password", nullable = false)
    val mustChangePassword: Boolean = true,
    // Phone authentication fields (legacy, now nullable)
    @Column(name = "phone_hash", length = 64)
    val phoneHash: String?,
    @Column(name = "pin_hash", length = 64)
    val pinHash: String?,
    // Contact info
    @Column(length = 20)
    val phone: String?,
    // Profile
    @Column(name = "first_name", nullable = false, length = 50)
    val firstName: String,
    @Column(nullable = false, length = 50)
    val surname: String,
    @Column(nullable = false, columnDefinition = "TEXT")
    val address: String,
    @Column(name = "registration_location", nullable = false, columnDefinition = "geography(Point,4326)")
    val registrationLocation: Point,
    // Status
    @Column(nullable = false, columnDefinition = "member_status")
    @ColumnTransformer(write = "?::member_status")
    val status: String,
    @Column(name = "created_at", nullable = false)
    val createdAt: Instant,
    @Column(name = "updated_at", nullable = false)
    val updatedAt: Instant,
    @Column(name = "deleted_at")
    val deletedAt: Instant? = null,
    // Ground Admin fields
    @Column(name = "is_ground_admin", nullable = false)
    val isGroundAdmin: Boolean = false,
    @Column(name = "ground_admin_status", columnDefinition = "ground_admin_status")
    @ColumnTransformer(write = "?::ground_admin_status")
    val groundAdminStatus: String? = null,
    @Column(name = "ground_admin_since")
    val groundAdminSince: Instant? = null,
    @Column(name = "ground_admin_response_rate", precision = 5, scale = 2)
    val groundAdminResponseRate: BigDecimal? = null,
) {
    fun toDomain(): Member =
        Member(
            id = MemberId(id),
            sectorId = SectorId(sectorId),
            email = email,
            emailHash = emailHash,
            passwordHash = passwordHash,
            mustChangePassword = mustChangePassword,
            phoneHash = phoneHash,
            pinHash = pinHash,
            phone = phone ?: "",
            firstName = firstName,
            surname = surname,
            address = address,
            registrationLocation = GeoPoint(registrationLocation.x, registrationLocation.y),
            status = MemberStatus.fromString(status),
            createdAt = createdAt,
            updatedAt = updatedAt,
            isGroundAdmin = isGroundAdmin,
            groundAdminStatus = groundAdminStatus?.let { GroundAdminStatus.fromString(it) },
            groundAdminSince = groundAdminSince,
            groundAdminResponseRate = groundAdminResponseRate,
        )

    companion object {
        private val geometryFactory = GeometryFactory(PrecisionModel(), 4326)

        fun fromDomain(member: Member): MemberEntity =
            MemberEntity(
                id = member.id.value,
                sectorId = member.sectorId.value,
                email = member.email,
                emailHash = member.emailHash,
                passwordHash = member.passwordHash,
                mustChangePassword = member.mustChangePassword,
                phoneHash = member.phoneHash,
                pinHash = member.pinHash,
                phone = member.phone,
                firstName = member.firstName,
                surname = member.surname,
                address = member.address,
                registrationLocation =
                    geometryFactory.createPoint(
                        Coordinate(
                            member.registrationLocation.longitude,
                            member.registrationLocation.latitude,
                        ),
                    ),
                status = member.status.toString(),
                createdAt = member.createdAt,
                updatedAt = member.updatedAt,
                isGroundAdmin = member.isGroundAdmin,
                groundAdminStatus = member.groundAdminStatus?.toApiString(),
                groundAdminSince = member.groundAdminSince,
                groundAdminResponseRate = member.groundAdminResponseRate,
            )
    }
}
