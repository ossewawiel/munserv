# Database card - PostgreSQL 18 + PostGIS 3.6, Flyway

Read `domain/README.md` first; enum values and their meaning live there. Load the `database-patterns` skill for spatial queries, query style, indexing and the migration template. Check the live schema through the `postgres` MCP (localhost:5435) before writing a migration.

## Naming
| Element | Pattern | Example |
|---|---|---|
| Table | snake_case plural | `issues`, `issue_photos` |
| Column | snake_case | `sector_id`, `created_at` |
| Primary key | `id UUID PRIMARY KEY DEFAULT gen_random_uuid()` | |
| Foreign key | `{singular}_id ... REFERENCES t(id) ON DELETE RESTRICT` | `sector_id` |
| Index | `idx_{table}_{columns}` | `idx_issues_sector_state` |
| Unique / FK / check | `uq_` / `fk_` / `ck_` prefixes | `ck_issues_state` |
| Enum type | snake_case, values snake_case | `issue_state` |

Every table has `created_at` and `updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`; soft delete is `deleted_at TIMESTAMPTZ NULL`. Never `ON DELETE CASCADE` on core entities (issues, members, sectors, admins).

## Geography
Points are `GEOGRAPHY(POINT, 4326)`, boundaries `GEOGRAPHY(POLYGON, 4326)`, both with a GIST index. Hibernate maps them to JTS types; do not store lat/lng in two float columns.

## Migrations
`backend/src/main/resources/db/migration/V{NNN}__{description}.sql`, three-digit numbers, one transaction each, immutable once merged to `master`, rollback as a comment. Currently at V034. Adding an enum value is `ALTER TYPE ... ADD VALUE` plus the Kotlin, web, mobile and `domain/` changes in the same PR; renaming a type uses the create-new, cast, drop, rename sequence (see V028).

## Forbidden
`SELECT *` in application queries; `ON DELETE CASCADE` on core entities; `VARCHAR` without length (use `TEXT`); nullable foreign keys without a comment saying why; string-concatenated SQL; storing passwords or PINs in clear.

## Before writing a migration
1. Query the schema through the MCP: tables, columns, constraints.
2. Confirm the change is described in `domain/` and, if it changes the wire contract, in `specs/contracts/types.md`.
3. Write the migration, run `./gradlew test` (Testcontainers applies every migration from scratch), then `bootRun` against the dev database.
