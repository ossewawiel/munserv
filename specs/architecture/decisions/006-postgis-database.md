# ADR-006: PostgreSQL with PostGIS

**Date:** 2024-12 (recorded 2026-09-05)
**Status:** Accepted

## Context
Issues are located by GPS, sectors have boundaries, and routing an issue to its sector is a spatial query.

## Decision
PostgreSQL (18) with PostGIS (3.6). Points and polygons are `GEOGRAPHY` columns with GIST indexes; sector assignment uses `ST_Within`; nearby queries use `ST_DWithin`. Flyway owns the schema; one database per pod.

## Consequences
✅ Spatial correctness in the database, not in application code.
✅ Managed PostgreSQL is available from every cloud target considered.
⚠️ Tests need a PostGIS image; Testcontainers provides it.
