package com.munserv.issues.service

import com.munserv.issues.domain.IssueType
import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId

/**
 * Command object for creating a new issue.
 */
data class CreateIssueCommand(
    val sectorId: SectorId,
    val reporterId: MemberId,
    val type: IssueType,
    val location: GeoPoint,
    val address: String?,
    val description: String?,
)
