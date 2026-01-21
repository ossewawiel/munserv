-- V024__add_ground_admin_invitation_accepted_message_type.sql
-- Description: Add message type for ground admin invitation acceptance notification
-- Author: Claude
-- Date: 2026-01-21

-- UP
ALTER TYPE message_type ADD VALUE 'ground_admin_invitation_accepted';

-- DOWN (not possible to remove enum values in PostgreSQL)
-- Would need to recreate the enum type
