# Database Context - PostgreSQL + PostGIS

## Related Specs
- **DevOps Strategy** (`/specs/DevOps_Strategy.md`): Docker Compose setup, Flyway integration, migration workflow
- **Domain Modeling** (`/specs/Domain_and_Data_Modeling.md`): Entity definitions, relationships

## MCP First
**Always query postgres MCP before writing migrations or queries.**
```
→ Check current schema: SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'
→ Check table columns: SELECT column_name, data_type FROM information_schema.columns WHERE table_name = '{table}'
→ Check constraints: SELECT constraint_name, constraint_type FROM information_schema.table_constraints WHERE table_name = '{table}'
```

## Naming Conventions

| Element | Pattern | Example |
|---------|---------|---------|
| Tables | snake_case plural | `issues`, `sector_members` |
| Columns | snake_case | `created_at`, `sector_id` |
| Primary key | `id` | `id UUID PRIMARY KEY` |
| Foreign key | `{singular_table}_id` | `sector_id`, `reporter_id` |
| Index | `idx_{table}_{columns}` | `idx_issues_sector_id` |
| Unique constraint | `uq_{table}_{columns}` | `uq_members_phone_hash` |
| Foreign key constraint | `fk_{table}_{ref_table}` | `fk_issues_sectors` |
| Check constraint | `ck_{table}_{column}` | `ck_issues_state` |

## Standard Column Patterns

### Primary Keys
```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
```

### Timestamps (all tables)
```sql
created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
```

### Soft Delete
```sql
deleted_at TIMESTAMPTZ NULL
```

### Foreign Keys
```sql
sector_id UUID NOT NULL REFERENCES sectors(id) ON DELETE RESTRICT,
reporter_id UUID NOT NULL REFERENCES members(id) ON DELETE RESTRICT
```

**Rule:** Never use `ON DELETE CASCADE` on core entities (issues, members, sectors). Use `RESTRICT` and handle deletion logic in application.

## PostGIS Patterns

### Column Types
```sql
-- Point location (GPS coordinates)
location GEOGRAPHY(POINT, 4326) NOT NULL

-- Area boundary (sector/region)
boundary GEOGRAPHY(POLYGON, 4326) NOT NULL
```

### Spatial Indexes
```sql
CREATE INDEX idx_issues_location ON issues USING GIST (location);
CREATE INDEX idx_sectors_boundary ON sectors USING GIST (boundary);
```

### Common Queries

**Find issues within a sector:**
```sql
SELECT i.* FROM issues i
JOIN sectors s ON ST_Within(i.location::geometry, s.boundary::geometry)
WHERE s.id = :sector_id;
```

**Find issues within radius (meters):**
```sql
SELECT * FROM issues
WHERE ST_DWithin(location, ST_MakePoint(:lng, :lat)::geography, :radius_meters);
```

**Find nearest issues:**
```sql
SELECT *, ST_Distance(location, ST_MakePoint(:lng, :lat)::geography) AS distance
FROM issues
ORDER BY location <-> ST_MakePoint(:lng, :lat)::geography
LIMIT 10;
```

**Check if point is in any sector:**
```sql
SELECT id, name FROM sectors
WHERE ST_Within(ST_MakePoint(:lng, :lat)::geometry, boundary::geometry);
```

## Enum Patterns

Use PostgreSQL enums for fixed value sets:

```sql
CREATE TYPE issue_state AS ENUM (
    'reported', 'confirmed', 'in_progress', 'fixed', 'rejected', 'reopened'
);

CREATE TYPE issue_type AS ENUM (
    'pothole', 'water_leak', 'sewerage_leak', 'traffic_light', 
    'street_light', 'illegal_dumping', 'graffiti', 'other'
);

CREATE TYPE member_role AS ENUM (
    'member', 'community_admin', 'sector_admin', 'sector_chief',
    'pod_admin', 'pod_chief'
);
```

## Migration Workflow

**Tool:** Flyway (integrated with Spring Boot)

```bash
# Migrations run automatically on Spring Boot startup
./gradlew bootRun

# Or run standalone
flyway -url=jdbc:postgresql://localhost:5435/munserv_dev migrate
```

**Rules:**
- Migrations are immutable once merged to main
- Use 3-digit version numbers (V001, V002, V010)
- Each migration runs in a single transaction
- Include rollback comments

See `/specs/DevOps_Strategy.md` Section 9 for full migration workflow.

## Migration File Structure

```
/database
├── migrations/
│   ├── V001__create_enums.sql
│   ├── V002__create_pods_table.sql
│   ├── V003__create_sectors_table.sql
│   ├── V004__create_members_table.sql
│   ├── V005__create_issues_table.sql
│   └── V006__create_issue_photos_table.sql
└── seeds/
    ├── dev/
    │   └── seed_test_data.sql
    └── prod/
        └── seed_initial_enums.sql
```

### Migration Naming
```
V{number}__{description}.sql

V001__create_enums.sql
V002__add_heat_column_to_issues.sql
V003__create_index_on_issues_location.sql
```

### Migration Template
```sql
-- V00X__{description}.sql
-- Description: {what this migration does}
-- Author: {name}
-- Date: {date}

-- UP
{sql statements}

-- DOWN (in separate file or commented)
-- {rollback statements}
```

## Core Schema Overview

```
pods
├── id, name, config (JSONB)
└── sectors
    ├── id, pod_id, name, boundary (GEOGRAPHY)
    └── members
        ├── id, sector_id, phone_hash, role, status
        └── issues (as reporter)
            ├── id, sector_id, reporter_id, type, state, location, heat
            └── issue_photos
                └── id, issue_id, storage_key, captured_at
```

## Query Style

```sql
-- DO: Uppercase keywords, lowercase identifiers
SELECT i.id, i.type, i.state, s.name AS sector_name
FROM issues i
INNER JOIN sectors s ON s.id = i.sector_id
WHERE i.state = 'reported'
  AND i.created_at > :since
ORDER BY i.heat DESC
LIMIT :limit;

-- DO: Named parameters (:param)
-- DO: Explicit column lists
-- DO: Table aliases for joins
-- DO: AND/OR at start of line

-- DON'T: SELECT *
-- DON'T: Implicit joins (comma syntax)
-- DON'T: Positional parameters ($1, $2) in documentation
```

## Indexing Strategy

### Always Index
- Foreign keys (`sector_id`, `reporter_id`)
- Columns in WHERE clauses (`state`, `type`)
- Columns in ORDER BY (`created_at`, `heat`)
- Spatial columns (GIST index)

### Composite Indexes
```sql
-- For queries filtering by sector + state
CREATE INDEX idx_issues_sector_state ON issues(sector_id, state);

-- For heat-sorted lists within sector
CREATE INDEX idx_issues_sector_heat ON issues(sector_id, heat DESC);
```

## Forbidden
- `SELECT *` in application queries
- `ON DELETE CASCADE` on core entities
- `VARCHAR` without length (use `TEXT` or `VARCHAR(n)`)
- Nullable foreign keys without documented reason
- Raw SQL string concatenation (use parameterized queries)
- Storing passwords (only hashes)

## Before Writing Migrations
1. Query postgres MCP for current schema state
2. Check if columns/tables already exist
3. Verify foreign key targets exist
4. Include rollback strategy (even if commented)
5. Test on dev database via MCP before committing
