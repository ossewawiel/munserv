-- V020__create_messages_table.sql
-- Description: Generic messaging system for all platform communications
-- Author: Claude
-- Date: 2026-01-19

-- UP
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Message type and content
    type message_type NOT NULL,
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,

    -- Recipient (polymorphic - member or admin)
    recipient_id UUID NOT NULL,
    recipient_type VARCHAR(20) NOT NULL,

    -- Sender (optional - system messages have no sender)
    sender_id UUID NULL,
    sender_type VARCHAR(20) NULL,

    -- Status tracking
    status message_status NOT NULL DEFAULT 'unread',
    read_at TIMESTAMPTZ NULL,
    actioned_at TIMESTAMPTZ NULL,
    action_result VARCHAR(50) NULL,

    -- Related entity (for context)
    related_entity_id UUID NULL,
    related_entity_type VARCHAR(50) NULL,

    -- Action configuration (what buttons to show)
    action_type VARCHAR(50) NULL,

    -- Metadata (flexible JSON for type-specific data)
    metadata JSONB NULL,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NULL,

    -- Constraints
    CONSTRAINT ck_messages_recipient_type CHECK (recipient_type IN ('member', 'admin')),
    CONSTRAINT ck_messages_sender_type CHECK (sender_type IS NULL OR sender_type IN ('member', 'admin', 'system')),
    CONSTRAINT ck_messages_read_at CHECK (read_at IS NULL OR status IN ('read', 'actioned', 'dismissed')),
    CONSTRAINT ck_messages_actioned_at CHECK (actioned_at IS NULL OR status = 'actioned')
);

-- Indexes for common queries
CREATE INDEX idx_messages_recipient ON messages(recipient_id, recipient_type);
CREATE INDEX idx_messages_unread ON messages(recipient_id, status) WHERE status = 'unread';
CREATE INDEX idx_messages_type ON messages(type);
CREATE INDEX idx_messages_related_entity ON messages(related_entity_id, related_entity_type);
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);

-- DOWN
-- DROP TABLE messages;
