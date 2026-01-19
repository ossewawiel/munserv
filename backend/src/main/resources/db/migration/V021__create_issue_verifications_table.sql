-- V021__create_issue_verifications_table.sql
-- Description: Track verification requests and results for issues
-- Author: Claude
-- Date: 2026-01-19

-- UP
CREATE TABLE issue_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Which issue
    issue_id UUID NOT NULL REFERENCES issues(id) ON DELETE CASCADE,

    -- What type of verification
    verification_type VARCHAR(20) NOT NULL,

    -- Who was assigned (if admin_assigns mode)
    assigned_to UUID NULL REFERENCES members(id) ON DELETE SET NULL,

    -- Who actually verified
    verified_by UUID NULL REFERENCES members(id) ON DELETE SET NULL,

    -- Result
    result VARCHAR(20) NULL,
    reason verification_reason NULL,
    note TEXT NULL,

    -- Photo evidence (optional)
    photo_id UUID NULL REFERENCES issue_photos(id) ON DELETE SET NULL,

    -- Timing
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    responded_at TIMESTAMPTZ NULL,

    -- Status
    status VARCHAR(20) NOT NULL DEFAULT 'pending',

    -- Constraints
    CONSTRAINT ck_issue_verifications_type CHECK (verification_type IN ('existence', 'fix')),
    CONSTRAINT ck_issue_verifications_status CHECK (status IN ('pending', 'completed', 'expired'))
);

-- Indexes
CREATE INDEX idx_issue_verifications_issue ON issue_verifications(issue_id);
CREATE INDEX idx_issue_verifications_assigned ON issue_verifications(assigned_to) WHERE status = 'pending';
CREATE INDEX idx_issue_verifications_pending ON issue_verifications(status) WHERE status = 'pending';

-- DOWN
-- DROP TABLE issue_verifications;
