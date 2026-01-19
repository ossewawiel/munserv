package com.munserv.sectors.domain

import com.munserv.shared.enums.VerificationMode
import com.munserv.shared.types.SectorId
import com.munserv.shared.types.SectorSettingsId
import java.time.Instant

/**
 * Domain entity representing sector-level configuration for Ground Admin and issues.
 *
 * This is a pure domain class with no framework dependencies.
 * All updates return new instances (immutability).
 */
data class SectorSettings(
    val id: SectorSettingsId,
    val sectorId: SectorId,
    val newIssueVerificationMode: VerificationMode,
    val fixVerificationMode: VerificationMode,
    val daysFixedBeforeClosed: Int,
    val minimumGroundAdmins: Int,
    val createdAt: Instant,
    val updatedAt: Instant,
) {
    /**
     * Update newIssueVerificationMode immutably.
     */
    fun withNewIssueVerificationMode(
        mode: VerificationMode,
        now: Instant,
    ): SectorSettings = copy(newIssueVerificationMode = mode, updatedAt = now)

    /**
     * Update fixVerificationMode immutably.
     */
    fun withFixVerificationMode(
        mode: VerificationMode,
        now: Instant,
    ): SectorSettings = copy(fixVerificationMode = mode, updatedAt = now)

    /**
     * Update daysFixedBeforeClosed immutably.
     */
    fun withDaysFixedBeforeClosed(
        days: Int,
        now: Instant,
    ): SectorSettings = copy(daysFixedBeforeClosed = days, updatedAt = now)

    /**
     * Update minimumGroundAdmins immutably.
     */
    fun withMinimumGroundAdmins(
        count: Int,
        now: Instant,
    ): SectorSettings = copy(minimumGroundAdmins = count, updatedAt = now)

    /**
     * Update updatedAt timestamp.
     */
    fun withUpdatedAt(now: Instant): SectorSettings = copy(updatedAt = now)

    companion object {
        private const val DEFAULT_DAYS_FIXED_BEFORE_CLOSED = 7
        private const val DEFAULT_MINIMUM_GROUND_ADMINS = 2

        /**
         * Create default settings for a sector.
         */
        fun createDefault(
            sectorId: SectorId,
            now: Instant,
        ): SectorSettings =
            SectorSettings(
                id = SectorSettingsId.generate(),
                sectorId = sectorId,
                newIssueVerificationMode = VerificationMode.ALL_NOTIFIED,
                fixVerificationMode = VerificationMode.ALL_NOTIFIED,
                daysFixedBeforeClosed = DEFAULT_DAYS_FIXED_BEFORE_CLOSED,
                minimumGroundAdmins = DEFAULT_MINIMUM_GROUND_ADMINS,
                createdAt = now,
                updatedAt = now,
            )
    }
}
