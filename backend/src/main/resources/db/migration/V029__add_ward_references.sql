-- V029__add_ward_references.sql
-- Description: Add ward references to sectors and admins tables, add pod configuration
-- Author: Claude
-- Date: 2026-01-23

-- Step 1: Add uses_wards flag to pods table
-- This determines if a pod uses the ward organizational level (pod -> wards -> sectors)
-- or goes directly from pod to sectors (pod -> sectors)
ALTER TABLE pods ADD COLUMN uses_wards BOOLEAN NOT NULL DEFAULT FALSE;

-- Step 2: Add ward_id to sectors table
-- Nullable because pods without wards will have sectors with ward_id = NULL
ALTER TABLE sectors ADD COLUMN ward_id UUID REFERENCES wards(id) ON DELETE RESTRICT;
CREATE INDEX idx_sectors_ward_id ON sectors(ward_id);

-- Step 3: Add pod_id and ward_id to admins table for pod/ward level admins
-- Also make sector_id nullable since pod/ward admins don't need a specific sector
ALTER TABLE admins ADD COLUMN pod_id UUID REFERENCES pods(id) ON DELETE RESTRICT;
ALTER TABLE admins ADD COLUMN ward_id UUID REFERENCES wards(id) ON DELETE RESTRICT;
ALTER TABLE admins ALTER COLUMN sector_id DROP NOT NULL;

CREATE INDEX idx_admins_pod_id ON admins(pod_id);
CREATE INDEX idx_admins_ward_id ON admins(ward_id);

-- Step 4: Migrate existing sector admins - they keep sector_id, constraint will pass
-- (Existing sector_admin and sector_chief records already have sector_id set)

-- Add check constraint to ensure admins have appropriate scope fields based on role
-- sector_admin/sector_chief: must have sector_id
-- ward_admin/ward_chief: must have ward_id
-- pod_admin/pod_chief: must have pod_id
ALTER TABLE admins ADD CONSTRAINT ck_admins_role_scope CHECK (
    (role IN ('sector_admin', 'sector_chief') AND sector_id IS NOT NULL) OR
    (role IN ('ward_admin', 'ward_chief') AND ward_id IS NOT NULL) OR
    (role IN ('pod_admin', 'pod_chief') AND pod_id IS NOT NULL)
);

-- DOWN (rollback)
-- ALTER TABLE admins DROP CONSTRAINT ck_admins_role_scope;
-- DROP INDEX IF EXISTS idx_admins_ward_id;
-- DROP INDEX IF EXISTS idx_admins_pod_id;
-- ALTER TABLE admins DROP COLUMN ward_id;
-- ALTER TABLE admins DROP COLUMN pod_id;
-- ALTER TABLE admins ALTER COLUMN sector_id SET NOT NULL;
-- DROP INDEX IF EXISTS idx_sectors_ward_id;
-- ALTER TABLE sectors DROP COLUMN ward_id;
-- ALTER TABLE pods DROP COLUMN uses_wards;
