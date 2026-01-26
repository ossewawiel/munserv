-- Add optional profile fields for administrators
-- Part of W27: Pod Chief completes optional profile info

ALTER TABLE admins
ADD COLUMN known_as VARCHAR(50) NULL,
ADD COLUMN contact_phone VARCHAR(20) NULL,
ADD COLUMN address VARCHAR(255) NULL;

COMMENT ON COLUMN admins.known_as IS 'Nickname or preferred name';
COMMENT ON COLUMN admins.contact_phone IS 'Contact phone number';
COMMENT ON COLUMN admins.address IS 'Physical address';
