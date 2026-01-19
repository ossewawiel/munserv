-- V019__create_sector_settings_table.sql
-- Description: Sector-level configuration for Ground Admin and issues
-- Author: Claude
-- Date: 2026-01-19

-- UP
CREATE TABLE sector_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sector_id UUID NOT NULL REFERENCES sectors(id) ON DELETE CASCADE,

    -- Ground Admin verification settings
    new_issue_verification_mode verification_mode NOT NULL DEFAULT 'all_notified',
    fix_verification_mode verification_mode NOT NULL DEFAULT 'all_notified',

    -- Issue lifecycle settings
    days_fixed_before_closed INTEGER NOT NULL DEFAULT 7,

    -- Ground Admin management
    minimum_ground_admins INTEGER NOT NULL DEFAULT 2,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- One settings row per sector
    CONSTRAINT uq_sector_settings_sector UNIQUE (sector_id),

    -- Validate days_fixed_before_closed is positive
    CONSTRAINT ck_sector_settings_days_positive CHECK (days_fixed_before_closed > 0),

    -- Validate minimum_ground_admins is non-negative
    CONSTRAINT ck_sector_settings_min_ga_positive CHECK (minimum_ground_admins >= 0)
);

-- Index
CREATE INDEX idx_sector_settings_sector ON sector_settings(sector_id);

-- Create default settings for all existing sectors
INSERT INTO sector_settings (sector_id)
SELECT id FROM sectors
ON CONFLICT (sector_id) DO NOTHING;

-- Add trigger for updated_at
CREATE TRIGGER update_sector_settings_updated_at
    BEFORE UPDATE ON sector_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- DOWN
-- DROP TABLE sector_settings;
