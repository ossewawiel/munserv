-- V025__add_sector_chief_test_account.sql
-- Description: Add a sector chief test account for development/testing
-- Author: Claude
-- Date: 2026-01-22

-- Insert sector chief admin for testing
-- Email: chief@munserv.local
-- Password: chief123 (bcrypt hash below)
INSERT INTO admins (id, sector_id, email, password_hash, display_name, role) VALUES
    (
        '550e8400-e29b-41d4-a716-446655440021',
        '550e8400-e29b-41d4-a716-446655440001',
        'chief@munserv.local',
        -- bcrypt hash of 'chief123' with cost 10
        '$2b$10$swK8ZS8as9c0LQJiBNkVfueEEEt6YwP8hXRxQNgVabaLquIk3yoJa',
        'Test Sector Chief',
        'sector_chief'
    );
