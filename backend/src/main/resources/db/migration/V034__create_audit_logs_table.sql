-- B7: Bootstrap audit logging
-- Create enum for audit action types
CREATE TYPE audit_action_type AS ENUM (
    'SUPER_USER_LOGIN_SUCCESS',
    'SUPER_USER_LOGIN_FAILURE',
    'POD_CHIEF_CREATED',
    'SUPPORT_ACCESS_GRANTED',
    'SUPPORT_ACCESS_REVOKED',
    'SUPPORT_ACCESS_EXPIRED',
    'SUPPORT_ACCESS_LOGIN',
    'SUPPORT_ACCESS_ACTIVITY'
);

-- Create audit_logs table
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pod_id UUID NOT NULL REFERENCES pods(id),
    action audit_action_type NOT NULL,
    actor_email VARCHAR(255) NOT NULL,
    actor_type VARCHAR(20) NOT NULL,
    target_type VARCHAR(50),
    target_id UUID,
    details JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Index for querying by pod and time range
CREATE INDEX idx_audit_logs_pod_created ON audit_logs(pod_id, created_at DESC);

-- Index for querying by action type
CREATE INDEX idx_audit_logs_action ON audit_logs(action);

-- Index for querying by actor
CREATE INDEX idx_audit_logs_actor ON audit_logs(actor_email);

COMMENT ON TABLE audit_logs IS 'Audit trail for bootstrap and support access operations';
COMMENT ON COLUMN audit_logs.actor_type IS 'Type of actor: SUPER_USER, POD_CHIEF, SYSTEM';
COMMENT ON COLUMN audit_logs.target_type IS 'Type of target entity: ADMIN, SUPPORT_GRANT';
COMMENT ON COLUMN audit_logs.details IS 'Additional context as JSON';
