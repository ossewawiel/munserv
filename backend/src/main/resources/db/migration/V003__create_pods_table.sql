-- V003__create_pods_table.sql
-- Description: Create pods table (deployment instances)
-- Author: Claude
-- Date: 2026-01-05

CREATE TABLE pods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    config JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_pods_updated_at
    BEFORE UPDATE ON pods
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert default pod for development
INSERT INTO pods (id, name, config) VALUES (
    '550e8400-e29b-41d4-a716-446655440000',
    'MunServ Development Pod',
    '{"timezone": "Africa/Johannesburg", "locale": "en-ZA"}'
);
