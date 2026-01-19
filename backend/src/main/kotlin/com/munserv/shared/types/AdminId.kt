package com.munserv.shared.types

import java.util.UUID

/**
 * Value class for Admin IDs to ensure type safety.
 */
@JvmInline
value class AdminId(val value: UUID)
