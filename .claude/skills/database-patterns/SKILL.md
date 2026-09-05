---
name: database-patterns
description: PostgreSQL + PostGIS query, enum, indexing and schema patterns for MunServ - spatial queries (within sector, radius, nearest), query style, indexing strategy, and the migration file template. Load when writing SQL, a Flyway migration, or a JPA query beyond what database/CLAUDE.md covers.
---

# Database patterns

The core rules live in `database/CLAUDE.md`. Enum values are defined in `domain/language.yaml`, not here.

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
