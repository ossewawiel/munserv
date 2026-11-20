package com.munserv.admin.domain

import com.munserv.issues.domain.IssueId
import com.munserv.issues.domain.IssueState
import com.munserv.issues.domain.IssueStateHistoryEntry
import java.math.BigDecimal
import java.math.RoundingMode
import java.time.Duration
import java.time.Instant

/**
 * Mean time from reported to fixed, computed from issue state history.
 */
object ResolutionTime {
    private const val MILLIS_PER_DAY = 86_400_000.0
    private const val DECIMAL_PLACES = 1

    /**
     * Average days from the earliest reported entry to the latest fixed entry at or after
     * [windowStart], over the issues in [histories]. Returns null when no issue counts.
     */
    fun averageDays(
        histories: Map<IssueId, List<IssueStateHistoryEntry>>,
        windowStart: Instant,
    ): Double? {
        val days =
            histories.values.mapNotNull { entries ->
                val start = entries.filter { it.state == IssueState.Reported }.minOfOrNull { it.changedAt }
                val end =
                    entries
                        .filter { it.state == IssueState.Fixed && !it.changedAt.isBefore(windowStart) }
                        .maxOfOrNull { it.changedAt }
                if (start == null || end == null || end.isBefore(start)) {
                    null
                } else {
                    Duration.between(start, end).toMillis() / MILLIS_PER_DAY
                }
            }
        if (days.isEmpty()) return null
        return BigDecimal.valueOf(days.average()).setScale(DECIMAL_PLACES, RoundingMode.HALF_UP).toDouble()
    }
}
