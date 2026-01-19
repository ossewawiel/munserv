-- V018__add_ground_admin_fields_to_members.sql
-- Description: Add Ground Admin tracking fields to members table
-- Author: Claude
-- Date: 2026-01-19

-- UP
ALTER TABLE members
ADD COLUMN is_ground_admin BOOLEAN NOT NULL DEFAULT FALSE,
ADD COLUMN ground_admin_status ground_admin_status NULL,
ADD COLUMN ground_admin_since TIMESTAMPTZ NULL,
ADD COLUMN ground_admin_response_rate DECIMAL(5,2) NULL;

-- Constraint: status only set if is_ground_admin
ALTER TABLE members
ADD CONSTRAINT ck_members_ground_admin_status
CHECK (
    (is_ground_admin = FALSE AND ground_admin_status IS NULL)
    OR
    (is_ground_admin = TRUE AND ground_admin_status IS NOT NULL)
);

-- Index for querying Ground Admins in a sector
CREATE INDEX idx_members_ground_admin_sector
ON members(sector_id, is_ground_admin, ground_admin_status)
WHERE is_ground_admin = TRUE;

-- DOWN
-- DROP INDEX idx_members_ground_admin_sector;
-- ALTER TABLE members DROP CONSTRAINT ck_members_ground_admin_status;
-- ALTER TABLE members DROP COLUMN ground_admin_response_rate;
-- ALTER TABLE members DROP COLUMN ground_admin_since;
-- ALTER TABLE members DROP COLUMN ground_admin_status;
-- ALTER TABLE members DROP COLUMN is_ground_admin;
