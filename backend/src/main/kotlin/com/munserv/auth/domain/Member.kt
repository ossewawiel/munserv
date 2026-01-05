package com.munserv.auth.domain

import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import java.time.Instant

/**
 * Domain entity representing a community member.
 * Pure Kotlin data class with business logic, no framework dependencies.
 */
data class Member(
    val id: MemberId,
    val sectorId: SectorId,
    val phoneHash: String,
    val pinHash: String,
    val firstName: String,
    val surname: String,
    val address: String,
    val registrationLocation: GeoPoint,
    val status: MemberStatus = MemberStatus.Active,
    val createdAt: Instant = Instant.now(),
    val updatedAt: Instant = Instant.now(),
) {
    val fullName: String
        get() = "$firstName $surname"

    val isActive: Boolean
        get() = status == MemberStatus.Active

    fun canTransitionTo(newStatus: MemberStatus): Boolean = status.canTransitionTo(newStatus)

    fun withStatus(newStatus: MemberStatus): Member = copy(status = newStatus, updatedAt = Instant.now())

    fun withPinHash(newPinHash: String): Member = copy(pinHash = newPinHash, updatedAt = Instant.now())
}
