-- V027__create_wards_table.sql
-- Description: Create wards table for organizing sectors within pods
-- Author: Claude
-- Date: 2026-01-23

-- Wards are optional organizational units between pods and sectors.
-- A pod can choose to use wards (pod -> wards -> sectors) or not (pod -> sectors directly).
-- This table stores ward information including geographic boundaries.

CREATE TABLE wards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pod_id UUID NOT NULL REFERENCES pods(id) ON DELETE RESTRICT,
    name VARCHAR(100) NOT NULL,
    center GEOGRAPHY(POINT, 4326),
    boundary GEOGRAPHY(POLYGON, 4326),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_wards_pod_name UNIQUE (pod_id, name)
);

-- Indexes
CREATE INDEX idx_wards_pod_id ON wards(pod_id);
CREATE INDEX idx_wards_center ON wards USING GIST (center);
CREATE INDEX idx_wards_boundary ON wards USING GIST (boundary);

-- Update trigger
CREATE TRIGGER update_wards_updated_at
    BEFORE UPDATE ON wards
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- DOWN (rollback)
-- DROP TRIGGER IF EXISTS update_wards_updated_at ON wards;
-- DROP TABLE IF EXISTS wards;
