package com.munserv.issues.repository

import com.munserv.issues.domain.Issue
import com.munserv.issues.domain.IssueId
import com.munserv.issues.domain.IssueState
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId

/**
 * Repository interface for Issue persistence.
 * Abstracts the persistence layer from the domain.
 */
interface IssueRepository {
    fun findById(id: IssueId): Issue?

    fun save(issue: Issue): Issue

    fun findAll(): List<Issue>

    fun findBySectorId(sectorId: SectorId): List<Issue>

    fun findByReporterId(reporterId: MemberId): List<Issue>

    fun findByState(state: IssueState): List<Issue>

    fun findOpenIssues(): List<Issue>

    fun findByIdForUpdate(id: IssueId): Issue?

    fun deleteById(id: IssueId)
}
