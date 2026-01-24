package com.munserv.pod.repository

import com.munserv.shared.types.PodId
import com.munserv.shared.types.SectorId
import com.munserv.shared.types.WardId
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate
import org.springframework.stereotype.Repository

/**
 * Repository for dashboard statistics queries.
 * Uses native SQL for efficient aggregation across multiple tables.
 */
interface PodDashboardRepository {
    fun getPodStats(podId: PodId): PodStatsRow

    fun getWardStats(wardId: WardId): WardStatsRow?

    fun getSectorStats(sectorId: SectorId): SectorStatsRow?

    fun getWardName(wardId: WardId): String?

    fun getSectorName(sectorId: SectorId): String?
}

/**
 * Raw statistics row for pod-level dashboard.
 */
data class PodStatsRow(
    val totalIssues: Int,
    val openIssues: Int,
    val resolvedThisMonth: Int,
    val pendingIssues: Int,
    val activeAdministrators: Int,
    val totalMembers: Int,
    val activeGroundAdmins: Int,
    val wardCount: Int,
    val sectorCount: Int,
)

/**
 * Raw statistics row for ward-level dashboard.
 */
data class WardStatsRow(
    val totalIssues: Int,
    val openIssues: Int,
    val resolvedThisMonth: Int,
    val sectorCount: Int,
    val activeGroundAdmins: Int,
)

/**
 * Raw statistics row for sector-level dashboard.
 */
data class SectorStatsRow(
    val totalIssues: Int,
    val openIssues: Int,
    val resolvedThisMonth: Int,
    val activeGroundAdmins: Int,
    val totalMembers: Int,
)

/**
 * JDBC implementation of dashboard statistics repository.
 */
@Repository
class JdbcPodDashboardRepository(
    private val jdbcTemplate: NamedParameterJdbcTemplate,
) : PodDashboardRepository {
    override fun getPodStats(podId: PodId): PodStatsRow {
        val params = MapSqlParameterSource("podId", podId.value)

        val sql =
            """
            WITH pod_sectors AS (
                SELECT id FROM sectors WHERE pod_id = :podId
            ),
            pod_issues AS (
                SELECT state, updated_at
                FROM issues
                WHERE sector_id IN (SELECT id FROM pod_sectors)
                AND deleted_at IS NULL
            )
            SELECT
                (SELECT COUNT(*) FROM pod_issues) as total_issues,
                (SELECT COUNT(*) FROM pod_issues
                 WHERE state IN ('reported', 'confirmed', 'in_progress', 'reopened')) as open_issues,
                (SELECT COUNT(*) FROM pod_issues
                 WHERE state IN ('fixed', 'rejected')
                 AND updated_at >= date_trunc('month', CURRENT_DATE)) as resolved_this_month,
                (SELECT COUNT(*) FROM pod_issues WHERE state = 'reported') as pending_issues,
                (SELECT COUNT(*) FROM admins
                 WHERE pod_id = :podId AND deleted_at IS NULL) as active_administrators,
                (SELECT COUNT(*) FROM members
                 WHERE sector_id IN (SELECT id FROM pod_sectors)
                 AND deleted_at IS NULL) as total_members,
                (SELECT COUNT(*) FROM members
                 WHERE sector_id IN (SELECT id FROM pod_sectors)
                 AND is_ground_admin = true
                 AND ground_admin_status = 'active'
                 AND deleted_at IS NULL) as active_ground_admins,
                (SELECT COUNT(*) FROM wards WHERE pod_id = :podId) as ward_count,
                (SELECT COUNT(*) FROM pod_sectors) as sector_count
            """.trimIndent()

        return jdbcTemplate.queryForObject(sql, params) { rs, _ ->
            PodStatsRow(
                totalIssues = rs.getInt("total_issues"),
                openIssues = rs.getInt("open_issues"),
                resolvedThisMonth = rs.getInt("resolved_this_month"),
                pendingIssues = rs.getInt("pending_issues"),
                activeAdministrators = rs.getInt("active_administrators"),
                totalMembers = rs.getInt("total_members"),
                activeGroundAdmins = rs.getInt("active_ground_admins"),
                wardCount = rs.getInt("ward_count"),
                sectorCount = rs.getInt("sector_count"),
            )
        } ?: PodStatsRow(0, 0, 0, 0, 0, 0, 0, 0, 0)
    }

    override fun getWardStats(wardId: WardId): WardStatsRow? {
        val params = MapSqlParameterSource("wardId", wardId.value)

        // First check if ward exists
        val existsSql = "SELECT COUNT(*) FROM wards WHERE id = :wardId"
        val exists = jdbcTemplate.queryForObject(existsSql, params, Int::class.java) ?: 0
        if (exists == 0) return null

        val sql =
            """
            WITH ward_sectors AS (
                SELECT id FROM sectors WHERE ward_id = :wardId
            ),
            ward_issues AS (
                SELECT state, updated_at
                FROM issues
                WHERE sector_id IN (SELECT id FROM ward_sectors)
                AND deleted_at IS NULL
            )
            SELECT
                (SELECT COUNT(*) FROM ward_issues) as total_issues,
                (SELECT COUNT(*) FROM ward_issues
                 WHERE state IN ('reported', 'confirmed', 'in_progress', 'reopened')) as open_issues,
                (SELECT COUNT(*) FROM ward_issues
                 WHERE state IN ('fixed', 'rejected')
                 AND updated_at >= date_trunc('month', CURRENT_DATE)) as resolved_this_month,
                (SELECT COUNT(*) FROM ward_sectors) as sector_count,
                (SELECT COUNT(*) FROM members
                 WHERE sector_id IN (SELECT id FROM ward_sectors)
                 AND is_ground_admin = true
                 AND ground_admin_status = 'active'
                 AND deleted_at IS NULL) as active_ground_admins
            """.trimIndent()

        return jdbcTemplate.queryForObject(sql, params) { rs, _ ->
            WardStatsRow(
                totalIssues = rs.getInt("total_issues"),
                openIssues = rs.getInt("open_issues"),
                resolvedThisMonth = rs.getInt("resolved_this_month"),
                sectorCount = rs.getInt("sector_count"),
                activeGroundAdmins = rs.getInt("active_ground_admins"),
            )
        }
    }

    override fun getSectorStats(sectorId: SectorId): SectorStatsRow? {
        val params = MapSqlParameterSource("sectorId", sectorId.value)

        // First check if sector exists
        val existsSql = "SELECT COUNT(*) FROM sectors WHERE id = :sectorId"
        val exists = jdbcTemplate.queryForObject(existsSql, params, Int::class.java) ?: 0
        if (exists == 0) return null

        val sql =
            """
            WITH sector_issues AS (
                SELECT state, updated_at
                FROM issues
                WHERE sector_id = :sectorId
                AND deleted_at IS NULL
            )
            SELECT
                (SELECT COUNT(*) FROM sector_issues) as total_issues,
                (SELECT COUNT(*) FROM sector_issues
                 WHERE state IN ('reported', 'confirmed', 'in_progress', 'reopened')) as open_issues,
                (SELECT COUNT(*) FROM sector_issues
                 WHERE state IN ('fixed', 'rejected')
                 AND updated_at >= date_trunc('month', CURRENT_DATE)) as resolved_this_month,
                (SELECT COUNT(*) FROM members
                 WHERE sector_id = :sectorId
                 AND is_ground_admin = true
                 AND ground_admin_status = 'active'
                 AND deleted_at IS NULL) as active_ground_admins,
                (SELECT COUNT(*) FROM members
                 WHERE sector_id = :sectorId
                 AND deleted_at IS NULL) as total_members
            """.trimIndent()

        return jdbcTemplate.queryForObject(sql, params) { rs, _ ->
            SectorStatsRow(
                totalIssues = rs.getInt("total_issues"),
                openIssues = rs.getInt("open_issues"),
                resolvedThisMonth = rs.getInt("resolved_this_month"),
                activeGroundAdmins = rs.getInt("active_ground_admins"),
                totalMembers = rs.getInt("total_members"),
            )
        }
    }

    override fun getWardName(wardId: WardId): String? {
        val params = MapSqlParameterSource("wardId", wardId.value)
        val sql = "SELECT name FROM wards WHERE id = :wardId"
        return try {
            jdbcTemplate.queryForObject(sql, params, String::class.java)
        } catch (e: Exception) {
            null
        }
    }

    override fun getSectorName(sectorId: SectorId): String? {
        val params = MapSqlParameterSource("sectorId", sectorId.value)
        val sql = "SELECT name FROM sectors WHERE id = :sectorId"
        return try {
            jdbcTemplate.queryForObject(sql, params, String::class.java)
        } catch (e: Exception) {
            null
        }
    }
}
