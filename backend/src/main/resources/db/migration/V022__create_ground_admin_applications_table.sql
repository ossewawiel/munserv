-- V022__create_ground_admin_applications_table.sql
-- Description: Track Ground Admin applications and invitations
-- Author: Claude
-- Date: 2026-01-19

-- UP
CREATE TABLE ground_admin_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Who
    member_id UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    sector_id UUID NOT NULL REFERENCES sectors(id) ON DELETE CASCADE,

    -- Type: member applied or admin invited
    type VARCHAR(20) NOT NULL,

    -- If invitation, who invited
    invited_by UUID NULL REFERENCES members(id) ON DELETE SET NULL,

    -- Status tracking
    status VARCHAR(20) NOT NULL DEFAULT 'pending',

    -- Outcome details
    processed_by UUID NULL REFERENCES members(id) ON DELETE SET NULL,
    processed_at TIMESTAMPTZ NULL,
    decline_reason TEXT NULL,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT ck_ga_applications_type CHECK (type IN ('application', 'invitation')),
    CONSTRAINT ck_ga_applications_status CHECK (status IN ('pending', 'approved', 'declined', 'accepted', 'rejected', 'withdrawn'))
);

-- Indexes
CREATE INDEX idx_ga_applications_member ON ground_admin_applications(member_id);
CREATE INDEX idx_ga_applications_sector ON ground_admin_applications(sector_id);
CREATE INDEX idx_ga_applications_pending ON ground_admin_applications(sector_id, status) WHERE status = 'pending';

-- Unique constraint: one pending application per member per sector
CREATE UNIQUE INDEX uq_ga_applications_pending
ON ground_admin_applications(member_id, sector_id)
WHERE status = 'pending';

-- Add trigger for updated_at
CREATE TRIGGER update_ground_admin_applications_updated_at
    BEFORE UPDATE ON ground_admin_applications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- DOWN
-- DROP TABLE ground_admin_applications;
