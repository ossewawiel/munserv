-- V006__create_admins_table.sql
-- Description: Create admins table for administrative users
-- Author: Claude
-- Date: 2026-01-05

CREATE TABLE admins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sector_id UUID NOT NULL REFERENCES sectors(id) ON DELETE RESTRICT,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(64) NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    role admin_role NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    CONSTRAINT uq_admins_email UNIQUE (email)
);

CREATE INDEX idx_admins_sector_id ON admins(sector_id);
CREATE INDEX idx_admins_role ON admins(role);

CREATE TRIGGER update_admins_updated_at
    BEFORE UPDATE ON admins
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert seed admin matching mock API data
-- Password: 'admin123' -> bcrypt hash would be used in real implementation
INSERT INTO admins (id, sector_id, email, password_hash, display_name, role) VALUES
    (
        '550e8400-e29b-41d4-a716-446655440020',
        '550e8400-e29b-41d4-a716-446655440001',
        'admin@munserv.local',
        -- For dev, we store plain 'admin123' but in prod this would be bcrypt hash
        '$2a$10$dummyhashforadmin123passwordthatwillbereplacedlater',
        'Test Admin',
        'sector_admin'
    );
