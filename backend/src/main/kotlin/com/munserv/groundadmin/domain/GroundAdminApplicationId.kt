package com.munserv.groundadmin.domain

import java.util.UUID

/**
 * Type-safe wrapper for Ground Admin Application IDs.
 * Prevents mixing application IDs with other UUID types.
 */
@JvmInline
value class GroundAdminApplicationId(
    val value: UUID,
) {
    companion object {
        fun generate(): GroundAdminApplicationId = GroundAdminApplicationId(UUID.randomUUID())

        fun fromString(value: String): GroundAdminApplicationId = GroundAdminApplicationId(UUID.fromString(value))
    }

    override fun toString(): String = value.toString()
}
