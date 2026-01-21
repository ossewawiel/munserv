-- V023__fix_ground_admin_applications_fk_to_admins.sql
-- Description: Change invited_by and processed_by FKs from members to admins
-- Author: Claude
-- Date: 2026-01-21
--
-- The invited_by and processed_by columns should reference the admins table,
-- not the members table, since these actions are performed by admins.

-- UP

-- Drop existing foreign key constraints
ALTER TABLE ground_admin_applications
    DROP CONSTRAINT IF EXISTS ground_admin_applications_invited_by_fkey;

ALTER TABLE ground_admin_applications
    DROP CONSTRAINT IF EXISTS ground_admin_applications_processed_by_fkey;

-- Add new foreign key constraints referencing admins table
ALTER TABLE ground_admin_applications
    ADD CONSTRAINT ground_admin_applications_invited_by_fkey
    FOREIGN KEY (invited_by) REFERENCES admins(id) ON DELETE SET NULL;

ALTER TABLE ground_admin_applications
    ADD CONSTRAINT ground_admin_applications_processed_by_fkey
    FOREIGN KEY (processed_by) REFERENCES admins(id) ON DELETE SET NULL;

-- DOWN
-- ALTER TABLE ground_admin_applications
--     DROP CONSTRAINT IF EXISTS ground_admin_applications_invited_by_fkey;
-- ALTER TABLE ground_admin_applications
--     DROP CONSTRAINT IF EXISTS ground_admin_applications_processed_by_fkey;
-- ALTER TABLE ground_admin_applications
--     ADD CONSTRAINT ground_admin_applications_invited_by_fkey
--     FOREIGN KEY (invited_by) REFERENCES members(id) ON DELETE SET NULL;
-- ALTER TABLE ground_admin_applications
--     ADD CONSTRAINT ground_admin_applications_processed_by_fkey
--     FOREIGN KEY (processed_by) REFERENCES members(id) ON DELETE SET NULL;
