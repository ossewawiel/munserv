-- V010__create_issue_state_history_table.sql
-- Description: Create issue_state_history table for audit trail
-- Author: Claude
-- Date: 2026-01-05

CREATE TABLE issue_state_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id UUID NOT NULL REFERENCES issues(id) ON DELETE CASCADE,
    state issue_state NOT NULL,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    changed_by UUID REFERENCES admins(id) ON DELETE SET NULL,
    note TEXT
);

CREATE INDEX idx_issue_state_history_issue_id ON issue_state_history(issue_id);
CREATE INDEX idx_issue_state_history_changed_at ON issue_state_history(changed_at DESC);

-- Insert seed state history for test issues
INSERT INTO issue_state_history (id, issue_id, state, changed_at, changed_by, note) VALUES
    -- Pothole - reported
    (
        '550e8400-e29b-41d4-a716-446655440300',
        '550e8400-e29b-41d4-a716-446655440100',
        'reported',
        NOW() - INTERVAL '5 days',
        NULL,
        NULL
    ),
    -- Water leak - reported then confirmed
    (
        '550e8400-e29b-41d4-a716-446655440301',
        '550e8400-e29b-41d4-a716-446655440101',
        'reported',
        NOW() - INTERVAL '3 days',
        NULL,
        NULL
    ),
    (
        '550e8400-e29b-41d4-a716-446655440302',
        '550e8400-e29b-41d4-a716-446655440101',
        'confirmed',
        NOW() - INTERVAL '2 days',
        '550e8400-e29b-41d4-a716-446655440020',
        'Confirmed by field inspection'
    ),
    -- Street light - reported, confirmed, in_progress
    (
        '550e8400-e29b-41d4-a716-446655440303',
        '550e8400-e29b-41d4-a716-446655440102',
        'reported',
        NOW() - INTERVAL '7 days',
        NULL,
        NULL
    ),
    (
        '550e8400-e29b-41d4-a716-446655440304',
        '550e8400-e29b-41d4-a716-446655440102',
        'confirmed',
        NOW() - INTERVAL '5 days',
        '550e8400-e29b-41d4-a716-446655440020',
        NULL
    ),
    (
        '550e8400-e29b-41d4-a716-446655440305',
        '550e8400-e29b-41d4-a716-446655440102',
        'in_progress',
        NOW() - INTERVAL '1 day',
        '550e8400-e29b-41d4-a716-446655440020',
        'Eskom notified, technician scheduled'
    ),
    -- Illegal dumping - reported
    (
        '550e8400-e29b-41d4-a716-446655440306',
        '550e8400-e29b-41d4-a716-446655440103',
        'reported',
        NOW() - INTERVAL '2 days',
        NULL,
        NULL
    ),
    -- Sewage - full lifecycle
    (
        '550e8400-e29b-41d4-a716-446655440307',
        '550e8400-e29b-41d4-a716-446655440104',
        'reported',
        NOW() - INTERVAL '10 days',
        NULL,
        NULL
    ),
    (
        '550e8400-e29b-41d4-a716-446655440308',
        '550e8400-e29b-41d4-a716-446655440104',
        'confirmed',
        NOW() - INTERVAL '8 days',
        '550e8400-e29b-41d4-a716-446655440020',
        NULL
    ),
    (
        '550e8400-e29b-41d4-a716-446655440309',
        '550e8400-e29b-41d4-a716-446655440104',
        'in_progress',
        NOW() - INTERVAL '5 days',
        '550e8400-e29b-41d4-a716-446655440020',
        'JW team dispatched'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440310',
        '550e8400-e29b-41d4-a716-446655440104',
        'fixed',
        NOW() - INTERVAL '1 day',
        '550e8400-e29b-41d4-a716-446655440020',
        'Drain cleaned and repaired'
    );
