package com.munserv.shared.enums

import com.fasterxml.jackson.annotation.JsonCreator
import com.fasterxml.jackson.annotation.JsonValue

/**
 * Enum representing types of messages in the messaging system.
 * Matches database enum: message_type
 */
enum class MessageType(
    @JsonValue private val apiString: String,
) {
    GROUND_ADMIN_INVITATION("ground_admin_invitation"),
    GROUND_ADMIN_APPLICATION("ground_admin_application"),
    GROUND_ADMIN_APPROVED("ground_admin_approved"),
    GROUND_ADMIN_DECLINED("ground_admin_declined"),
    GROUND_ADMIN_INVITATION_DECLINED("ground_admin_invitation_declined"),
    GROUND_ADMIN_INVITATION_ACCEPTED("ground_admin_invitation_accepted"),
    GROUND_ADMIN_REVOCATION("ground_admin_revocation"),
    GROUND_ADMIN_STEPDOWN_REQUEST("ground_admin_stepdown_request"),
    VERIFY_NEW_ISSUE("verify_new_issue"),
    VERIFY_FIX("verify_fix"),
    MEMBER_REGISTRATION("member_registration"),
    MONTHLY_REPORT("monthly_report"),
    ADMIN_WELCOME("admin_welcome"),
    ;

    fun toApiString(): String = apiString

    companion object {
        @JsonCreator
        @JvmStatic
        fun fromString(value: String): MessageType =
            entries.find { it.apiString.equals(value, ignoreCase = true) }
                ?: throw IllegalArgumentException("Unknown MessageType: $value")
    }
}
