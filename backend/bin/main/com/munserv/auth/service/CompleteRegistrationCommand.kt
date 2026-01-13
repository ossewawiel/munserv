package com.munserv.auth.service

import com.munserv.shared.types.GeoPoint

/**
 * Command object for completing member registration.
 * Groups registration parameters to reduce function parameter count.
 */
data class CompleteRegistrationCommand(
    val phone: String,
    val pin: String,
    val firstName: String,
    val surname: String,
    val address: String,
    val sectorId: String,
    val location: GeoPoint,
)
