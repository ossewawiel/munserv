-- Onboarding status for invited administrators
CREATE TYPE onboarding_status AS ENUM ('pending', 'password_changed', 'profile_complete', 'active');

-- Add onboarding fields to admins table
ALTER TABLE admins ADD COLUMN IF NOT EXISTS onboarding_status onboarding_status DEFAULT 'active';
ALTER TABLE admins ADD COLUMN IF NOT EXISTS temporary_password_hash VARCHAR(255);
ALTER TABLE admins ADD COLUMN IF NOT EXISTS onboarding_completed_at TIMESTAMPTZ;

-- Existing admins are already active
UPDATE admins SET onboarding_status = 'active' WHERE onboarding_status IS NULL;

COMMENT ON COLUMN admins.onboarding_status IS 'Tracks administrator onboarding progress';
COMMENT ON COLUMN admins.temporary_password_hash IS 'Temporary password for new administrators (cleared after password change)';
COMMENT ON COLUMN admins.onboarding_completed_at IS 'Timestamp when onboarding was completed';
