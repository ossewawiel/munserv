package com.munserv.audit.domain

/**
 * Types of actions that can be audited.
 * Maps to the audit_action_type enum in the database.
 */
enum class AuditAction(
    val dbValue: String,
) {
    SUPER_USER_LOGIN_SUCCESS("SUPER_USER_LOGIN_SUCCESS"),
    SUPER_USER_LOGIN_FAILURE("SUPER_USER_LOGIN_FAILURE"),
    POD_CHIEF_CREATED("POD_CHIEF_CREATED"),
    SUPPORT_ACCESS_GRANTED("SUPPORT_ACCESS_GRANTED"),
    SUPPORT_ACCESS_REVOKED("SUPPORT_ACCESS_REVOKED"),
    SUPPORT_ACCESS_EXPIRED("SUPPORT_ACCESS_EXPIRED"),
    SUPPORT_ACCESS_LOGIN("SUPPORT_ACCESS_LOGIN"),
    SUPPORT_ACCESS_ACTIVITY("SUPPORT_ACCESS_ACTIVITY"),
    ;

    companion object {
        fun fromDbValue(value: String): AuditAction =
            entries.find { it.dbValue == value }
                ?: throw IllegalArgumentException("Unknown audit action: $value")
    }
}
