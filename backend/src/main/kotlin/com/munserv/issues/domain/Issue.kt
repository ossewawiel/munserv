package com.munserv.issues.domain

import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import java.time.Instant

/**
 * Domain entity representing an infrastructure issue reported by a member.
 *
 * This is a pure domain class with no framework dependencies.
 * All updates are immutable via copy() methods.
 */
data class Issue(
    val id: IssueId,
    val sectorId: SectorId,
    val reporterId: MemberId,
    val type: IssueType,
    val state: IssueState,
    val location: GeoPoint,
    val address: String?,
    val description: String?,
    val heat: Int,
    val reportCount: Int,
    val createdAt: Instant,
    val updatedAt: Instant,
) {
    /**
     * Whether this issue is in an open (active) state.
     */
    val isOpen: Boolean get() = state.isOpen

    /**
     * Whether this issue is in a closed (resolved) state.
     */
    val isClosed: Boolean get() = state.isClosed

    /**
     * Check if this issue can transition to the given new state.
     * Delegates to the state's transition rules.
     */
    fun canTransitionTo(newState: IssueState): Boolean = state.canTransitionTo(newState)

    /**
     * Returns a new Issue with the updated state.
     */
    fun withState(newState: IssueState): Issue = copy(state = newState)

    /**
     * Returns a new Issue with the updated heat value.
     */
    fun withHeat(newHeat: Int): Issue = copy(heat = newHeat)

    /**
     * Returns a new Issue with the updated report count.
     */
    fun withReportCount(newCount: Int): Issue = copy(reportCount = newCount)

    /**
     * Returns a new Issue with the updated timestamp.
     */
    fun withUpdatedAt(timestamp: Instant): Issue = copy(updatedAt = timestamp)
}
