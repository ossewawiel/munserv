-- V004__create_sectors_table.sql
-- Description: Create sectors table (geographic areas)
-- Author: Claude
-- Date: 2026-01-05

CREATE TABLE sectors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pod_id UUID NOT NULL REFERENCES pods(id) ON DELETE RESTRICT,
    name VARCHAR(100) NOT NULL,
    center GEOGRAPHY(POINT, 4326) NOT NULL,
    boundary GEOGRAPHY(POLYGON, 4326),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_sectors_pod_name UNIQUE (pod_id, name)
);

CREATE INDEX idx_sectors_pod_id ON sectors(pod_id);
CREATE INDEX idx_sectors_center ON sectors USING GIST (center);
CREATE INDEX idx_sectors_boundary ON sectors USING GIST (boundary);

CREATE TRIGGER update_sectors_updated_at
    BEFORE UPDATE ON sectors
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert seed sectors matching mock API data
INSERT INTO sectors (id, pod_id, name, center) VALUES
    (
        '550e8400-e29b-41d4-a716-446655440001',
        '550e8400-e29b-41d4-a716-446655440000',
        'Ward 42 - Northcliff',
        ST_SetSRID(ST_MakePoint(27.9833, -26.1367), 4326)::geography
    ),
    (
        '550e8400-e29b-41d4-a716-446655440002',
        '550e8400-e29b-41d4-a716-446655440000',
        'Ward 43 - Fairlands',
        ST_SetSRID(ST_MakePoint(28.0200, -26.1300), 4326)::geography
    );
