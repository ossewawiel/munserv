-- V002__create_enums.sql
-- Description: Create domain enumeration types
-- Author: Claude
-- Date: 2026-01-05

-- Issue states with allowed transitions
CREATE TYPE issue_state AS ENUM (
    'reported',     -- Initial state
    'confirmed',    -- Verified by admin/community
    'in_progress',  -- Work started
    'fixed',        -- Resolved
    'rejected',     -- Invalid/spam
    'reopened'      -- Fix was inadequate
);

-- Issue type categories
CREATE TYPE issue_type AS ENUM (
    'pothole',
    'water_leak',
    'sewage_leak',
    'traffic_light',
    'street_light',
    'illegal_dumping',
    'graffiti',
    'other'
);

-- Member account status
CREATE TYPE member_status AS ENUM (
    'active',
    'pending',
    'suspended'
);

-- Admin role levels
CREATE TYPE admin_role AS ENUM (
    'sector_admin',
    'sector_chief',
    'pod_admin',
    'pod_chief'
);
