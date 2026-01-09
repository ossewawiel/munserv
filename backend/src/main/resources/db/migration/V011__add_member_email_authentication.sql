-- V011__add_member_email_authentication.sql
-- Description: Add email-based authentication fields to members table
-- Support for web registration with admin approval workflow
-- Author: Claude
-- Date: 2026-01-09

-- ================================================
-- 1. Add new status values to enum
-- Note: PostgreSQL doesn't allow removing/renaming enum values
-- We add the new values needed for the web registration flow
-- ================================================
ALTER TYPE member_status ADD VALUE IF NOT EXISTS 'pending_approval';
ALTER TYPE member_status ADD VALUE IF NOT EXISTS 'deleted';

-- ================================================
-- 2. Add email authentication columns
-- ================================================
ALTER TABLE members
    ADD COLUMN IF NOT EXISTS email VARCHAR(255),
    ADD COLUMN IF NOT EXISTS email_hash VARCHAR(64),
    ADD COLUMN IF NOT EXISTS password_hash VARCHAR(60),
    ADD COLUMN IF NOT EXISTS must_change_password BOOLEAN DEFAULT true,
    ADD COLUMN IF NOT EXISTS phone VARCHAR(20);

-- ================================================
-- 3. Make phone_hash and pin_hash nullable
-- (Required for web registrations without phone-based auth)
-- ================================================
ALTER TABLE members
    ALTER COLUMN phone_hash DROP NOT NULL,
    ALTER COLUMN pin_hash DROP NOT NULL;

-- ================================================
-- 4. Migrate existing members
-- Existing members get placeholder email based on their ID
-- They will continue using phone+PIN authentication
-- ================================================
UPDATE members
SET
    email = COALESCE(email, 'legacy-' || id::text || '@pending-migration.local'),
    email_hash = COALESCE(email_hash, encode(sha256(('legacy-' || id::text || '@pending-migration.local')::bytea), 'hex')),
    must_change_password = COALESCE(must_change_password, false),
    phone = COALESCE(phone, '')
WHERE email IS NULL;

-- ================================================
-- 5. Add NOT NULL constraints after migration
-- ================================================
ALTER TABLE members
    ALTER COLUMN email SET NOT NULL,
    ALTER COLUMN email_hash SET NOT NULL,
    ALTER COLUMN must_change_password SET NOT NULL;

-- ================================================
-- 6. Add unique constraints and indexes
-- ================================================
-- Unique email
ALTER TABLE members
    ADD CONSTRAINT uq_members_email UNIQUE (email);

-- Unique email hash for lookups
ALTER TABLE members
    ADD CONSTRAINT uq_members_email_hash UNIQUE (email_hash);

-- Index for email hash lookups
CREATE INDEX IF NOT EXISTS idx_members_email_hash ON members(email_hash);

-- Composite index for sector + status queries (used by admin approval list)
CREATE INDEX IF NOT EXISTS idx_members_sector_status ON members(sector_id, status);

-- ================================================
-- 7. Update seed data with new fields
-- ================================================
UPDATE members
SET
    email = 'john.doe@example.com',
    email_hash = encode(sha256('john.doe@example.com'::bytea), 'hex'),
    phone = '+27821234567',
    must_change_password = false
WHERE id = '550e8400-e29b-41d4-a716-446655440010';

-- ================================================
-- 8. Add comments for documentation
-- ================================================
COMMENT ON COLUMN members.email IS 'Member email address for login and contact';
COMMENT ON COLUMN members.email_hash IS 'SHA-256 hash of lowercase email for lookups';
COMMENT ON COLUMN members.password_hash IS 'BCrypt hashed password, null until approved';
COMMENT ON COLUMN members.must_change_password IS 'True if member must change password on next login';
COMMENT ON COLUMN members.phone IS 'Plain phone number for contact purposes';
