-- V015__create_message_type_enum.sql
-- Description: Enum for message types in the messaging system
-- Author: Claude
-- Date: 2026-01-19

-- UP
CREATE TYPE message_type AS ENUM (
    'ground_admin_invitation',
    'ground_admin_application',
    'ground_admin_approved',
    'ground_admin_declined',
    'ground_admin_invitation_declined',
    'ground_admin_revocation',
    'ground_admin_stepdown_request',
    'verify_new_issue',
    'verify_fix',
    'member_registration',
    'monthly_report'
);

-- DOWN
-- DROP TYPE message_type;
