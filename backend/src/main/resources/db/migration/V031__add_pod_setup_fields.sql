-- V031__add_pod_setup_fields.sql
-- Description: Add pod setup tracking fields and setup steps table
-- Author: Claude
-- Date: 2026-01-23

-- Add setup tracking fields to pods table
ALTER TABLE pods ADD COLUMN IF NOT EXISTS logo_url VARCHAR(500);
ALTER TABLE pods ADD COLUMN IF NOT EXISTS display_name VARCHAR(200);
ALTER TABLE pods ADD COLUMN IF NOT EXISTS setup_completed_at TIMESTAMPTZ;

-- Update existing pod with display_name
UPDATE pods SET display_name = 'Munserv Pod ' || name WHERE display_name IS NULL;

-- Setup steps tracking table
CREATE TABLE IF NOT EXISTS pod_setup_steps (
    pod_id UUID NOT NULL REFERENCES pods(id) ON DELETE CASCADE,
    step VARCHAR(50) NOT NULL,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (pod_id, step)
);

CREATE INDEX idx_pod_setup_steps_pod_id ON pod_setup_steps(pod_id);

COMMENT ON TABLE pod_setup_steps IS 'Tracks Pod Chief setup progress through required steps';
COMMENT ON COLUMN pod_setup_steps.step IS 'Setup step: pod_name, pod_boundaries, wards_sectors, first_admin';
COMMENT ON COLUMN pods.logo_url IS 'URL to pod logo image';
COMMENT ON COLUMN pods.display_name IS 'Display name shown in UI, e.g. Munserv Pod {name}';
COMMENT ON COLUMN pods.setup_completed_at IS 'Timestamp when all setup steps were completed';
