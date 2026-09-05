package com.munserv.sectors.service

import com.munserv.sectors.domain.SectorSettings
import com.munserv.shared.types.SectorId

/**
 * Sealed interface representing the possible results of sector settings operations.
 * Used instead of exceptions for business logic flow control.
 */
sealed interface SectorSettingsResult {
    /**
     * Operation completed successfully.
     */
    data class Success(
        val settings: SectorSettings,
    ) : SectorSettingsResult

    /**
     * Sector was not found.
     */
    data class SectorNotFound(
        val sectorId: SectorId,
    ) : SectorSettingsResult

    /**
     * Validation errors occurred.
     */
    data class ValidationError(
        val errors: List<String>,
    ) : SectorSettingsResult
}
