-- V026__fix_admin_password_hashes.sql
-- Description: Fix admin password hashes to use valid bcrypt format
-- Author: Claude
-- Date: 2026-01-22

-- Update existing sector_admin password hash with valid bcrypt hash of 'admin123'
-- Also update email to match test expectations
UPDATE admins
SET password_hash = '$2b$10$oOvi7DSTtiDNfnj.hwhJxOcD876O7ZBp3Mm7E1oR2fFBLsPNxUr6y',
    email = 'admin@ward42.example.com'
WHERE id = '550e8400-e29b-41d4-a716-446655440020';
