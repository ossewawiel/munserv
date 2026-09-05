package com.munserv.support.service

import com.munserv.support.domain.SupportGrant

/**
 * Sealed result type for support access operations.
 */
sealed interface SupportAccessResult {
    data class Granted(
        val view: SupportGrantView,
    ) : SupportAccessResult

    data class Grants(
        val views: List<SupportGrantView>,
    ) : SupportAccessResult

    data object Revoked : SupportAccessResult

    data object NotFound : SupportAccessResult

    data object ActiveGrantExists : SupportAccessResult

    data object GrantNotActive : SupportAccessResult

    data object NotAuthorized : SupportAccessResult

    data class ValidationError(
        val errors: List<String>,
    ) : SupportAccessResult
}

/**
 * View of a support grant enriched with the pod chief's display name.
 */
data class SupportGrantView(
    val grant: SupportGrant,
    val grantedByName: String,
)
