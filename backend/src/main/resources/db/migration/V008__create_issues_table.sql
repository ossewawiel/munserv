-- V008__create_issues_table.sql
-- Description: Create issues table for reported infrastructure problems
-- Author: Claude
-- Date: 2026-01-05

CREATE TABLE issues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sector_id UUID NOT NULL REFERENCES sectors(id) ON DELETE RESTRICT,
    reporter_id UUID NOT NULL REFERENCES members(id) ON DELETE RESTRICT,
    type issue_type NOT NULL,
    state issue_state NOT NULL DEFAULT 'reported',
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    address TEXT,
    description TEXT,
    heat INTEGER NOT NULL DEFAULT 10 CHECK (heat >= 0 AND heat <= 100),
    report_count INTEGER NOT NULL DEFAULT 1 CHECK (report_count >= 1),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_issues_sector_id ON issues(sector_id);
CREATE INDEX idx_issues_reporter_id ON issues(reporter_id);
CREATE INDEX idx_issues_state ON issues(state);
CREATE INDEX idx_issues_type ON issues(type);
CREATE INDEX idx_issues_heat ON issues(heat DESC);
CREATE INDEX idx_issues_location ON issues USING GIST (location);
CREATE INDEX idx_issues_created_at ON issues(created_at DESC);

CREATE TRIGGER update_issues_updated_at
    BEFORE UPDATE ON issues
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert seed issues matching mock API data
INSERT INTO issues (id, sector_id, reporter_id, type, state, location, address, description, heat, report_count, created_at, updated_at) VALUES
    (
        '550e8400-e29b-41d4-a716-446655440100',
        '550e8400-e29b-41d4-a716-446655440001',
        '550e8400-e29b-41d4-a716-446655440010',
        'pothole',
        'reported',
        ST_SetSRID(ST_MakePoint(27.9845, -26.1380), 4326)::geography,
        '45 Beyers Naude Drive, Northcliff',
        'Large pothole causing traffic to swerve',
        75,
        3,
        NOW() - INTERVAL '5 days',
        NOW() - INTERVAL '5 days'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440101',
        '550e8400-e29b-41d4-a716-446655440001',
        '550e8400-e29b-41d4-a716-446655440010',
        'water_leak',
        'confirmed',
        ST_SetSRID(ST_MakePoint(27.9820, -26.1350), 4326)::geography,
        '12 Doreen Road, Northcliff',
        'Water running down street for 2 days',
        60,
        2,
        NOW() - INTERVAL '3 days',
        NOW() - INTERVAL '2 days'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440102',
        '550e8400-e29b-41d4-a716-446655440001',
        '550e8400-e29b-41d4-a716-446655440010',
        'street_light',
        'in_progress',
        ST_SetSRID(ST_MakePoint(27.9860, -26.1400), 4326)::geography,
        'Corner of Doreen and Cross Roads',
        'Street light out for a week',
        45,
        1,
        NOW() - INTERVAL '7 days',
        NOW() - INTERVAL '1 day'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440103',
        '550e8400-e29b-41d4-a716-446655440001',
        '550e8400-e29b-41d4-a716-446655440010',
        'illegal_dumping',
        'reported',
        ST_SetSRID(ST_MakePoint(27.9810, -26.1390), 4326)::geography,
        'Open lot on Flora Avenue',
        'Construction rubble dumped illegally',
        55,
        4,
        NOW() - INTERVAL '2 days',
        NOW() - INTERVAL '2 days'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440104',
        '550e8400-e29b-41d4-a716-446655440002',
        '550e8400-e29b-41d4-a716-446655440010',
        'sewage_leak',
        'fixed',
        ST_SetSRID(ST_MakePoint(28.0150, -26.1320), 4326)::geography,
        '88 Republic Road, Fairlands',
        'Sewage smell from drain',
        0,
        1,
        NOW() - INTERVAL '10 days',
        NOW() - INTERVAL '1 day'
    );
