-- V028__add_ward_roles_to_enum.sql
-- Description: Add ward_admin and ward_chief roles to admin_role enum
-- Author: Claude
-- Date: 2026-01-23

-- PostgreSQL enums don't support reordering values, and ordinal position matters for role hierarchy.
-- The new hierarchy should be:
-- sector_admin (0) < sector_chief (1) < ward_admin (2) < ward_chief (3) < pod_admin (4) < pod_chief (5)
--
-- Strategy: Create new enum with correct order, migrate data, drop old enum.

-- Step 1: Create new enum with all roles in correct ordinal order
CREATE TYPE admin_role_new AS ENUM (
    'sector_admin',   -- 0: Basic sector administrator
    'sector_chief',   -- 1: Sector supervisor
    'ward_admin',     -- 2: Ward administrator (manages multiple sectors)
    'ward_chief',     -- 3: Ward supervisor
    'pod_admin',      -- 4: Pod administrator (manages entire pod)
    'pod_chief'       -- 5: Pod supervisor (highest level)
);

-- Step 2: Update admins table to use new enum
ALTER TABLE admins
    ALTER COLUMN role TYPE admin_role_new
    USING role::text::admin_role_new;

-- Step 3: Drop old enum and rename new one
DROP TYPE admin_role;
ALTER TYPE admin_role_new RENAME TO admin_role;

-- DOWN (rollback - loses ward_admin/ward_chief data)
-- Note: Rollback would require ensuring no ward_admin/ward_chief records exist first
-- CREATE TYPE admin_role_old AS ENUM ('sector_admin', 'sector_chief', 'pod_admin', 'pod_chief');
-- UPDATE admins SET role = 'sector_admin' WHERE role IN ('ward_admin', 'ward_chief');
-- ALTER TABLE admins ALTER COLUMN role TYPE admin_role_old USING role::text::admin_role_old;
-- DROP TYPE admin_role;
-- ALTER TYPE admin_role_old RENAME TO admin_role;
