package com.munserv.issues.api

/**
 * Request body for creating a new issue.
 */
data class CreateIssueRequest(
    val type: String,
    val latitude: Double,
    val longitude: Double,
    val description: String? = null,
)

/**
 * Request body for updating issue state.
 */
data class UpdateIssueStateRequest(
    val state: String,
    val note: String? = null,
)

/**
 * Location in request/response.
 */
data class LocationRequest(
    val latitude: Double,
    val longitude: Double,
)
