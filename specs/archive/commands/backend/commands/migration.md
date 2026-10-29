# Flyway Migration Generator

name: "migration"
description: "Generate Flyway SQL migration"
parameters:
  - name: "description"
    description: "Migration description (e.g., 'create_notifications_table')"
    required: true
  - name: "type"
    description: "Migration type: create, alter, seed"
    required: true

---

You are an expert database developer generating Flyway migrations for the MunServ backend.

## Task

Generate a Flyway migration for: `{{description}}` (type: `{{type}}`).

## Output Location

`src/main/resources/db/migration/V{version}__{description}.sql`

**Naming Convention:** `V{major}_{minor}__{description}.sql`
- Use next available version number
- Description in snake_case
- Example: `V1_9__create_notifications_table.sql`

## Check Existing Migrations

Before creating, check existing migrations:
```bash
ls src/main/resources/db/migration/
```

## Migration Templates by Type

### CREATE TABLE

```sql
-- V{version}__create_{{table}}_table.sql
-- Create {{table}} table for {{feature}} feature

CREATE TABLE IF NOT EXISTS {{table}} (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Foreign keys
    sector_id UUID NOT NULL REFERENCES sectors(id),
    member_id UUID NOT NULL REFERENCES members(id),

    -- Business fields
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'active',

    -- Numeric fields
    count INTEGER NOT NULL DEFAULT 0,
    amount DECIMAL(10,2),

    -- Location (PostGIS)
    location GEOGRAPHY(Point, 4326),

    -- JSON data
    metadata JSONB DEFAULT '{}',

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_{{table}}_sector_id ON {{table}}(sector_id);
CREATE INDEX idx_{{table}}_status ON {{table}}(status);
CREATE INDEX idx_{{table}}_created_at ON {{table}}(created_at);

-- Spatial index (if location field exists)
CREATE INDEX idx_{{table}}_location ON {{table}} USING GIST(location);

-- Comments
COMMENT ON TABLE {{table}} IS '{{description}}';
COMMENT ON COLUMN {{table}}.id IS 'Unique identifier';
```

### ALTER TABLE (Add Column)

```sql
-- V{version}__add_{{column}}_to_{{table}}.sql
-- Add {{column}} column to {{table}} table

ALTER TABLE {{table}}
ADD COLUMN IF NOT EXISTS {{column}} {{type}} {{constraints}};

-- Add index if needed
CREATE INDEX IF NOT EXISTS idx_{{table}}_{{column}} ON {{table}}({{column}});

-- Update existing rows if needed
UPDATE {{table}} SET {{column}} = {{default}} WHERE {{column}} IS NULL;

-- Add NOT NULL constraint after data migration
ALTER TABLE {{table}} ALTER COLUMN {{column}} SET NOT NULL;
```

### ALTER TABLE (Add Foreign Key)

```sql
-- V{version}__add_{{fk_column}}_fk_to_{{table}}.sql
-- Add foreign key from {{table}} to {{ref_table}}

ALTER TABLE {{table}}
ADD COLUMN IF NOT EXISTS {{fk_column}} UUID;

ALTER TABLE {{table}}
ADD CONSTRAINT fk_{{table}}_{{ref_table}}
FOREIGN KEY ({{fk_column}}) REFERENCES {{ref_table}}(id);

CREATE INDEX idx_{{table}}_{{fk_column}} ON {{table}}({{fk_column}});
```

### CREATE ENUM TYPE

```sql
-- V{version}__create_{{enum}}_type.sql
-- Create {{enum}} enum type

DO $$ BEGIN
    CREATE TYPE {{enum}}_type AS ENUM (
        'value_one',
        'value_two',
        'value_three'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
```

### SEED DATA

```sql
-- V{version}__seed_{{table}}_data.sql
-- Seed initial {{table}} data

INSERT INTO {{table}} (id, name, status, created_at, updated_at)
VALUES
    ('550e8400-e29b-41d4-a716-446655440001', 'Default Item', 'active', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;
```

### CREATE INDEX

```sql
-- V{version}__add_{{index_name}}_index.sql
-- Add index on {{table}}({{columns}})

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_{{table}}_{{columns}}
ON {{table}}({{columns}});
```

## PostgreSQL + PostGIS Patterns

### Enable PostGIS

```sql
CREATE EXTENSION IF NOT EXISTS postgis;
```

### Geography Column

```sql
location GEOGRAPHY(Point, 4326)  -- WGS84 coordinate system
```

### Spatial Index

```sql
CREATE INDEX idx_{{table}}_location ON {{table}} USING GIST(location);
```

### Spatial Query Example

```sql
-- Find within radius
SELECT * FROM {{table}}
WHERE ST_DWithin(location, ST_MakePoint(lng, lat)::geography, radius_meters);
```

## Migration Rules

1. **Idempotent** - Use `IF NOT EXISTS`, `IF EXISTS` where possible
2. **Transactional** - Flyway wraps each migration in a transaction
3. **Forward Only** - Never modify existing migrations
4. **Version Order** - Versions must be sequential
5. **Descriptive Names** - Clear snake_case descriptions

## Column Type Reference

| Kotlin Type | PostgreSQL Type |
|-------------|-----------------|
| `UUID` | `UUID` |
| `String` | `VARCHAR(n)` or `TEXT` |
| `Int` | `INTEGER` |
| `Long` | `BIGINT` |
| `Double` | `DOUBLE PRECISION` |
| `BigDecimal` | `DECIMAL(p,s)` |
| `Boolean` | `BOOLEAN` |
| `Instant` | `TIMESTAMP WITH TIME ZONE` |
| `LocalDate` | `DATE` |
| `GeoPoint` | `GEOGRAPHY(Point, 4326)` |
| `Enum` | `VARCHAR(50)` or custom TYPE |
| `JSON` | `JSONB` |

## Common Constraints

```sql
NOT NULL
DEFAULT 'value'
UNIQUE
PRIMARY KEY
REFERENCES other_table(id)
CHECK (column > 0)
```

## Output

Generate the SQL migration file with:
1. Proper version number (check existing migrations)
2. Descriptive header comment
3. Idempotent statements where possible
4. Appropriate indexes
5. Column comments
