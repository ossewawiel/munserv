package com.munserv.shared.types

import java.util.UUID

/**
 * Type-safe wrapper for SectorSettings identifiers.
 * Prevents accidentally passing other ID types where settings IDs are expected.
 */
@JvmInline
value class SectorSettingsId(
    val value: UUID,
) {
    override fun toString(): String = value.toString()

    companion object {
        fun fromString(value: String): SectorSettingsId = SectorSettingsId(UUID.fromString(value))

        fun generate(): SectorSettingsId = SectorSettingsId(UUID.randomUUID())
    }
}
