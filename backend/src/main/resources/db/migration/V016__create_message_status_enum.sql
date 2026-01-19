-- V016__create_message_status_enum.sql
-- Description: Enum for message status tracking
-- Author: Claude
-- Date: 2026-01-19

-- UP
CREATE TYPE message_status AS ENUM (
    'unread',
    'read',
    'actioned',
    'dismissed'
);

-- DOWN
-- DROP TYPE message_status;
