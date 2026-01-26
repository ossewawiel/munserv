package com.munserv.audit.domain

/**
 * Types of actors that can perform audited actions.
 */
enum class AuditActorType(val dbValue: String) {
    SUPER_USER("SUPER_USER"),
    POD_CHIEF("POD_CHIEF"),
    SYSTEM("SYSTEM"),
    ;

    companion object {
        fun fromDbValue(value: String): AuditActorType =
            entries.find { it.dbValue == value }
                ?: throw IllegalArgumentException("Unknown actor type: $value")
    }
}
