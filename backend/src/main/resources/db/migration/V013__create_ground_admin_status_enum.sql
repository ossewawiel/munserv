-- V013__create_ground_admin_status_enum.sql
-- Description: Enum for Ground Admin status states
-- Author: Claude
-- Date: 2026-01-19

-- UP
CREATE TYPE ground_admin_status AS ENUM (
    'active',      -- Normal operation, receives verification requests
    'on_hold',     -- Temporarily paused (low response rate)
    'inactive'     -- Stepped down or revoked
);

-- DOWN
-- DROP TYPE ground_admin_status;
