-- V005__create_members_table.sql
-- Description: Create members table for community users
-- Author: Claude
-- Date: 2026-01-05

CREATE TABLE members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sector_id UUID NOT NULL REFERENCES sectors(id) ON DELETE RESTRICT,
    phone_hash VARCHAR(64) NOT NULL,
    pin_hash VARCHAR(64) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    surname VARCHAR(50) NOT NULL,
    address TEXT NOT NULL,
    registration_location GEOGRAPHY(POINT, 4326) NOT NULL,
    status member_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    CONSTRAINT uq_members_phone_hash UNIQUE (phone_hash)
);

CREATE INDEX idx_members_sector_id ON members(sector_id);
CREATE INDEX idx_members_status ON members(status);
CREATE INDEX idx_members_registration_location ON members USING GIST (registration_location);

CREATE TRIGGER update_members_updated_at
    BEFORE UPDATE ON members
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert seed member matching mock API data
INSERT INTO members (id, sector_id, phone_hash, pin_hash, first_name, surname, address, registration_location, status) VALUES
    (
        '550e8400-e29b-41d4-a716-446655440010',
        '550e8400-e29b-41d4-a716-446655440001',
        -- SHA-256 hash of '+27821234567'
        'a1b2c3d4e5f6789012345678901234567890123456789012345678901234abcd',
        -- SHA-256 hash of '1234'
        '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4',
        'John',
        'Doe',
        '123 Main Street, Northcliff',
        ST_SetSRID(ST_MakePoint(27.9833, -26.1367), 4326)::geography,
        'active'
    );
