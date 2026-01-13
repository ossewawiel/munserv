-- V007__fix_member_phone_hash.sql
-- Description: Fix seed member phone_hash to use correct SHA-256 hash
-- Author: Claude
-- Date: 2026-01-05

-- Update phone_hash to correct SHA-256 hash of '+27821234567'
UPDATE members
SET phone_hash = '44ecafe03bc4f3fe722ac4b67a6621bf147ea8776efdc1cc7acf2d4bbfe18bf4'
WHERE id = '550e8400-e29b-41d4-a716-446655440010';
