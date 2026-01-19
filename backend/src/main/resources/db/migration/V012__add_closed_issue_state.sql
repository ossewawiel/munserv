-- V012__add_closed_issue_state.sql
-- Description: Add closed state to issue_state enum
-- Author: Claude
-- Date: 2026-01-19

-- UP
ALTER TYPE issue_state ADD VALUE 'closed' AFTER 'reopened';

-- DOWN (commented - enum values cannot be removed easily in PostgreSQL)
-- Requires recreating the type and updating all references
