-- V030__add_ward_role_test_accounts.sql
-- Description: Add test accounts for ward and pod level admins
-- Author: Claude
-- Date: 2026-01-23

-- Create a test ward for ward-level admin testing
INSERT INTO wards (id, pod_id, name, center) VALUES
    (
        '550e8400-e29b-41d4-a716-446655440030',
        '550e8400-e29b-41d4-a716-446655440000',  -- MunServ Development Pod
        'Test Ward North',
        ST_SetSRID(ST_MakePoint(27.9881, -26.1438), 4326)::geography
    );

-- Assign existing sectors to the test ward (optional - enables full hierarchy testing)
-- UPDATE sectors SET ward_id = '550e8400-e29b-41d4-a716-446655440030'
-- WHERE id IN ('550e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440002');

-- Enable wards for the development pod
UPDATE pods SET uses_wards = TRUE WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Insert Pod Chief test account
-- Email: podchief@munserv.local
-- Password: podchief123
INSERT INTO admins (id, pod_id, sector_id, email, password_hash, display_name, role) VALUES
    (
        '550e8400-e29b-41d4-a716-446655440031',
        '550e8400-e29b-41d4-a716-446655440000',  -- pod_id (required for pod_chief)
        NULL,  -- sector_id (not needed for pod-level admins)
        'podchief@munserv.local',
        '$2b$10$l2rsmeNZEH7ok/N07u0pweIX6rpkDpm8VI3hqt6/FWAJaM9zilLnG',
        'Test Pod Chief',
        'pod_chief'
    );

-- Insert Pod Admin test account
-- Email: podadmin@munserv.local
-- Password: podadmin123
INSERT INTO admins (id, pod_id, sector_id, email, password_hash, display_name, role) VALUES
    (
        '550e8400-e29b-41d4-a716-446655440032',
        '550e8400-e29b-41d4-a716-446655440000',  -- pod_id (required for pod_admin)
        NULL,  -- sector_id (not needed for pod-level admins)
        'podadmin@munserv.local',
        '$2b$10$yXERwBijWMJcIyRTy2.9Nu3W1x0fEaz9bZLq5k5SLZtX/HgNaifO2',
        'Test Pod Admin',
        'pod_admin'
    );

-- Insert Ward Chief test account
-- Email: wardchief@munserv.local
-- Password: wardchief123
INSERT INTO admins (id, ward_id, sector_id, email, password_hash, display_name, role) VALUES
    (
        '550e8400-e29b-41d4-a716-446655440033',
        '550e8400-e29b-41d4-a716-446655440030',  -- ward_id (required for ward_chief)
        NULL,  -- sector_id (not needed for ward-level admins)
        'wardchief@munserv.local',
        '$2b$10$1MvB6s4rLRvTBnrOaJGi0O/AwtkWpZmIdLoGOMvjGhigBqTTVZPXO',
        'Test Ward Chief',
        'ward_chief'
    );

-- Insert Ward Admin test account
-- Email: wardadmin@munserv.local
-- Password: wardadmin123
INSERT INTO admins (id, ward_id, sector_id, email, password_hash, display_name, role) VALUES
    (
        '550e8400-e29b-41d4-a716-446655440034',
        '550e8400-e29b-41d4-a716-446655440030',  -- ward_id (required for ward_admin)
        NULL,  -- sector_id (not needed for ward-level admins)
        'wardadmin@munserv.local',
        '$2b$10$iYC0FxFrhqqTFCNBP4hp.u4nLypxOmwuwn/mPpEx7KBD4p7SJ1IJ.',
        'Test Ward Admin',
        'ward_admin'
    );

-- DOWN (rollback)
-- DELETE FROM admins WHERE id IN (
--     '550e8400-e29b-41d4-a716-446655440031',
--     '550e8400-e29b-41d4-a716-446655440032',
--     '550e8400-e29b-41d4-a716-446655440033',
--     '550e8400-e29b-41d4-a716-446655440034'
-- );
-- UPDATE pods SET uses_wards = FALSE WHERE id = '550e8400-e29b-41d4-a716-446655440000';
-- DELETE FROM wards WHERE id = '550e8400-e29b-41d4-a716-446655440030';
