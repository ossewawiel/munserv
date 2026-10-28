-- V036__add_admin_welcome_message_type.sql
-- Description: Add message type for the welcome message sent to a new administrator
-- Author: Claude
-- Date: 2026-09-06

-- UP
ALTER TYPE message_type ADD VALUE 'admin_welcome';

-- DOWN (not possible to remove enum values in PostgreSQL)
-- Would need to recreate the enum type
