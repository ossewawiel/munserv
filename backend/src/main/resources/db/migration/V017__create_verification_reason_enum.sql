-- V017__create_verification_reason_enum.sql
-- Description: Reasons why Ground Admin cannot verify an issue
-- Author: Claude
-- Date: 2026-01-19

-- UP
CREATE TYPE verification_reason AS ENUM (
    'busy',
    'away',
    'cannot_find',
    'wrong_location',
    'not_an_issue'
);

-- DOWN
-- DROP TYPE verification_reason;
