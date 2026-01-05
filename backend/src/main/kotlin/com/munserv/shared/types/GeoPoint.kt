package com.munserv.shared.types

/**
 * Represents a geographic point with latitude and longitude.
 * Uses WGS84 coordinate system (EPSG:4326).
 *
 * @property latitude The latitude in degrees (-90 to 90)
 * @property longitude The longitude in degrees (-180 to 180)
 */
data class GeoPoint(
    val latitude: Double,
    val longitude: Double,
) {
    init {
        require(latitude in -90.0..90.0) { "Latitude must be between -90 and 90" }
        require(longitude in -180.0..180.0) { "Longitude must be between -180 and 180" }
    }

    companion object {
        /**
         * Creates a GeoPoint from a coordinate pair.
         * Note: Many geographic systems use (longitude, latitude) order (e.g., GeoJSON).
         */
        fun fromLonLat(
            longitude: Double,
            latitude: Double,
        ): GeoPoint = GeoPoint(latitude = latitude, longitude = longitude)
    }
}
