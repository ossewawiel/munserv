-- B8: Temporary super user grant tracking
-- Create support_grants table

CREATE TABLE support_grants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pod_id UUID NOT NULL REFERENCES pods(id),
    granted_role VARCHAR(50) NOT NULL,
    purpose TEXT NOT NULL,
    granted_by UUID NOT NULL REFERENCES admins(id),
    granted_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    last_activity TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ,
    expired_at TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    revoked_by UUID REFERENCES admins(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_support_grants_pod_status ON support_grants(pod_id, status);

CREATE INDEX idx_support_grants_expires ON support_grants(expires_at) WHERE status = 'active';

CREATE UNIQUE INDEX uq_support_grants_one_active_per_pod ON support_grants(pod_id) WHERE status = 'active';

COMMENT ON TABLE support_grants IS 'Temporary super user access grants issued by a pod chief';
COMMENT ON COLUMN support_grants.status IS 'Status of the grant: active, expired, revoked';
