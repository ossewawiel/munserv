package com.munserv.issues.service

import com.munserv.issues.domain.Issue
import com.munserv.issues.domain.IssueId
import com.munserv.issues.domain.IssueState
import com.munserv.issues.domain.IssueStateHistoryEntry
import com.munserv.issues.domain.IssueStateHistoryId
import com.munserv.issues.repository.IssueRepository
import com.munserv.issues.repository.IssueStateHistoryRepository
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.MemberId
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.time.Instant

/**
 * Service for managing issues.
 * Handles business logic and coordinates between domain and repository.
 */
@Service
class IssueService(
    private val repository: IssueRepository,
    private val stateHistoryRepository: IssueStateHistoryRepository,
    private val clock: Clock,
) {
    companion object {
        private const val DEFAULT_HEAT = 10
        private const val HEAT_PER_REPORT = 5
        private const val MAX_HEAT = 100
    }

    /**
     * Find an issue by its ID.
     */
    @Transactional(readOnly = true)
    fun findById(id: IssueId): IssueResult =
        repository.findById(id)
            ?.let { IssueResult.Success(it) }
            ?: IssueResult.NotFound(id)

    /**
     * Find all issues.
     */
    @Transactional(readOnly = true)
    fun findAll(): List<Issue> = repository.findAll()

    /**
     * Find issues reported by a specific member.
     */
    @Transactional(readOnly = true)
    fun findByReporter(reporterId: MemberId): List<Issue> = repository.findByReporterId(reporterId)

    /**
     * Find all open issues (not fixed or rejected), sorted by heat.
     */
    @Transactional(readOnly = true)
    fun findOpenIssues(): List<Issue> = repository.findOpenIssues()

    /**
     * Create a new issue.
     * Records initial "reported" state in history.
     */
    @Transactional
    fun create(command: CreateIssueCommand): IssueResult {
        val now = Instant.now(clock)
        val issue =
            Issue(
                id = IssueId.generate(),
                sectorId = command.sectorId,
                reporterId = command.reporterId,
                type = command.type,
                state = IssueState.Reported,
                location = command.location,
                address = command.address,
                description = command.description,
                heat = DEFAULT_HEAT,
                reportCount = 1,
                createdAt = now,
                updatedAt = now,
            )

        val savedIssue = repository.save(issue)

        // Record initial state in history
        val historyEntry =
            IssueStateHistoryEntry(
                id = IssueStateHistoryId.generate(),
                issueId = savedIssue.id,
                state = IssueState.Reported,
                changedAt = now,
                changedBy = null,
                note = null,
            )
        stateHistoryRepository.save(historyEntry)

        return IssueResult.Success(savedIssue)
    }

    /**
     * Update the state of an issue.
     * Validates that the transition is allowed by the state machine.
     * Records the state change in history.
     */
    @Transactional
    fun updateState(
        id: IssueId,
        newState: IssueState,
        actorId: AdminId? = null,
        note: String? = null,
    ): IssueResult {
        val issue =
            repository.findByIdForUpdate(id)
                ?: return IssueResult.NotFound(id)

        if (!issue.canTransitionTo(newState)) {
            return IssueResult.InvalidTransition(issue.state, newState)
        }

        val now = Instant.now(clock)
        val updatedIssue =
            issue
                .withState(newState)
                .withUpdatedAt(now)

        val savedIssue = repository.save(updatedIssue)

        // Record state change in history
        val historyEntry =
            IssueStateHistoryEntry(
                id = IssueStateHistoryId.generate(),
                issueId = id,
                state = newState,
                changedAt = now,
                changedBy = actorId,
                note = note,
            )
        stateHistoryRepository.save(historyEntry)

        return IssueResult.Success(savedIssue)
    }

    /**
     * Get the state history for an issue.
     * Returns entries ordered chronologically (oldest first).
     */
    @Transactional(readOnly = true)
    fun getStateHistory(issueId: IssueId): List<IssueStateHistoryEntry> = stateHistoryRepository.findByIssueId(issueId)

    /**
     * Increment the report count for an issue (when another member reports the same issue).
     * Also recalculates and updates the heat value.
     */
    @Transactional
    fun incrementReportCount(id: IssueId): IssueResult {
        val issue =
            repository.findByIdForUpdate(id)
                ?: return IssueResult.NotFound(id)

        val newReportCount = issue.reportCount + 1
        val newHeat = calculateHeat(newReportCount)

        val updatedIssue =
            issue
                .withReportCount(newReportCount)
                .withHeat(newHeat)
                .withUpdatedAt(Instant.now(clock))

        val savedIssue = repository.save(updatedIssue)
        return IssueResult.Success(savedIssue)
    }

    /**
     * Update the heat value for an issue.
     */
    @Transactional
    fun updateHeat(
        id: IssueId,
        newHeat: Int,
    ): IssueResult {
        val issue =
            repository.findByIdForUpdate(id)
                ?: return IssueResult.NotFound(id)

        val updatedIssue =
            issue
                .withHeat(newHeat.coerceIn(0, MAX_HEAT))
                .withUpdatedAt(Instant.now(clock))

        val savedIssue = repository.save(updatedIssue)
        return IssueResult.Success(savedIssue)
    }

    /**
     * Calculate heat based on report count.
     * Formula: base_heat + ((report_count - 1) * heat_per_report)
     * The first report gets base heat, each additional report adds HEAT_PER_REPORT.
     * Capped at MAX_HEAT.
     */
    private fun calculateHeat(reportCount: Int): Int {
        val baseHeat = DEFAULT_HEAT
        val additionalReports = (reportCount - 1).coerceAtLeast(0)
        val calculatedHeat = baseHeat + (additionalReports * HEAT_PER_REPORT)
        return calculatedHeat.coerceAtMost(MAX_HEAT)
    }
}
