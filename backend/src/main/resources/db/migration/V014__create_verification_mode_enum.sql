-- V014__create_verification_mode_enum.sql
-- Description: Enum for how Ground Admins are notified about verification requests
-- Author: Claude
-- Date: 2026-01-19

-- UP
CREATE TYPE verification_mode AS ENUM (
    'all_notified',    -- All Ground Admins in sector notified
    'admin_assigns',   -- Admin manually picks Ground Admin
    'nearest_auto',    -- System assigns nearest based on address
    'first_come'       -- All notified, first to respond handles it
);

-- DOWN
-- DROP TYPE verification_mode;
