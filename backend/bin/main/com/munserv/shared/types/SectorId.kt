package com.munserv.shared.types

import java.util.UUID

/**
 * Type-safe wrapper for Sector identifiers.
 * Prevents accidentally passing pod/member IDs where sector IDs are expected.
 */
@JvmInline
value class SectorId(val value: UUID) {
    override fun toString(): String = value.toString()

    companion object {
        fun fromString(value: String): SectorId = SectorId(UUID.fromString(value))

        fun generate(): SectorId = SectorId(UUID.randomUUID())
    }
}
