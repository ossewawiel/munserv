# Ground Admin & Messaging - Data Model

## Overview

This document defines all database changes required for the Ground Admin and Messaging feature.

## Enum Changes

### Update: member_role

Add `sector_chief` to existing enum:

```sql
-- V0XX__add_sector_chief_role.sql
ALTER TYPE member_role ADD VALUE 'sector_chief' AFTER 'sector_admin';
```

**Updated Values:**
```sql
CREATE TYPE member_role AS ENUM (
    'member',
    'community_admin',
    'sector_admin',
    'sector_chief',      -- NEW
    'pod_admin',
    'pod_chief'
);
```

### Update: issue_state

Add `CLOSED` to existing enum:

```sql
-- V0XX__add_closed_issue_state.sql
ALTER TYPE issue_state ADD VALUE 'closed' AFTER 'reopened';
```

**Updated Values:**
```sql
CREATE TYPE issue_state AS ENUM (
    'reported',
    'confirmed',
    'in_progress',
    'fixed',
    'rejected',
    'reopened',
    'closed'       -- NEW
);
```

### New: ground_admin_status

```sql
-- V0XX__create_ground_admin_status_enum.sql
CREATE TYPE ground_admin_status AS ENUM (
    'active',      -- Normal operation, receives verification requests
    'on_hold',     -- Temporarily paused (low response rate)
    'inactive'     -- Stepped down or revoked
);
```

### New: verification_mode

```sql
-- V0XX__create_verification_mode_enum.sql
CREATE TYPE verification_mode AS ENUM (
    'all_notified',    -- All Ground Admins in sector notified
    'admin_assigns',   -- Admin manually picks Ground Admin
    'nearest_auto',    -- System assigns nearest based on address
    'first_come'       -- All notified, first to respond handles it
);
```

### New: message_type

```sql
-- V0XX__create_message_type_enum.sql
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
```

### New: message_status

```sql
-- V0XX__create_message_status_enum.sql
CREATE TYPE message_status AS ENUM (
    'unread',
    'read',
    'actioned',
    'dismissed'
);
```

### New: verification_reason

```sql
-- V0XX__create_verification_reason_enum.sql
CREATE TYPE verification_reason AS ENUM (
    'busy',
    'away',
    'cannot_find',
    'wrong_location',
    'not_an_issue'
);
```

---

## Table Changes

### Update: members

Add Ground Admin fields:

```sql
-- V0XX__add_ground_admin_fields_to_members.sql
ALTER TABLE members
ADD COLUMN is_ground_admin BOOLEAN NOT NULL DEFAULT FALSE,
ADD COLUMN ground_admin_status ground_admin_status NULL,
ADD COLUMN ground_admin_since TIMESTAMPTZ NULL,
ADD COLUMN ground_admin_response_rate DECIMAL(5,2) NULL;

-- Constraint: status only set if is_ground_admin
ALTER TABLE members
ADD CONSTRAINT ck_members_ground_admin_status
CHECK (
    (is_ground_admin = FALSE AND ground_admin_status IS NULL)
    OR
    (is_ground_admin = TRUE AND ground_admin_status IS NOT NULL)
);

-- Index for querying Ground Admins in a sector
CREATE INDEX idx_members_ground_admin_sector
ON members(sector_id, is_ground_admin, ground_admin_status)
WHERE is_ground_admin = TRUE;
```

**Updated members table:**

| Column | Type | Notes |
|--------|------|-------|
| ... existing columns ... | | |
| is_ground_admin | boolean | Default FALSE |
| ground_admin_status | ground_admin_status | NULL if not GA |
| ground_admin_since | timestamptz | When became GA |
| ground_admin_response_rate | decimal(5,2) | 0.00-100.00 percentage |

---

### New: sector_settings

```sql
-- V0XX__create_sector_settings_table.sql
CREATE TABLE sector_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sector_id UUID NOT NULL REFERENCES sectors(id) ON DELETE CASCADE,
    
    -- Ground Admin verification settings
    new_issue_verification_mode verification_mode NOT NULL DEFAULT 'all_notified',
    fix_verification_mode verification_mode NOT NULL DEFAULT 'all_notified',
    
    -- Issue lifecycle settings
    days_fixed_before_closed INTEGER NOT NULL DEFAULT 7,
    
    -- Ground Admin management
    minimum_ground_admins INTEGER NOT NULL DEFAULT 2,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- One settings row per sector
    CONSTRAINT uq_sector_settings_sector UNIQUE (sector_id)
);

-- Index
CREATE INDEX idx_sector_settings_sector ON sector_settings(sector_id);
```

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| sector_id | UUID | FK to sectors, unique |
| new_issue_verification_mode | verification_mode | Default 'all_notified' |
| fix_verification_mode | verification_mode | Default 'all_notified' |
| days_fixed_before_closed | integer | Default 7 |
| minimum_ground_admins | integer | Default 2 |
| created_at | timestamptz | |
| updated_at | timestamptz | |

---

### New: messages

```sql
-- V0XX__create_messages_table.sql
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Message type and content
    type message_type NOT NULL,
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    
    -- Recipient (polymorphic - member or admin)
    recipient_id UUID NOT NULL,
    recipient_type VARCHAR(20) NOT NULL,  -- 'member' or 'admin'
    
    -- Sender (optional - system messages have no sender)
    sender_id UUID NULL,
    sender_type VARCHAR(20) NULL,
    
    -- Status tracking
    status message_status NOT NULL DEFAULT 'unread',
    read_at TIMESTAMPTZ NULL,
    actioned_at TIMESTAMPTZ NULL,
    action_result VARCHAR(50) NULL,  -- e.g., 'accepted', 'declined', 'approved'
    
    -- Related entity (for context)
    related_entity_id UUID NULL,
    related_entity_type VARCHAR(50) NULL,  -- 'issue', 'member', 'sector'
    
    -- Action configuration (what buttons to show)
    action_type VARCHAR(50) NULL,  -- e.g., 'accept_decline', 'approve_reject', 'confirm_verify'
    
    -- Metadata (flexible JSON for type-specific data)
    metadata JSONB NULL,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NULL,  -- Auto-dismiss after this time
    
    -- Constraints
    CONSTRAINT ck_messages_recipient_type CHECK (recipient_type IN ('member', 'admin')),
    CONSTRAINT ck_messages_sender_type CHECK (sender_type IS NULL OR sender_type IN ('member', 'admin', 'system')),
    CONSTRAINT ck_messages_read_at CHECK (read_at IS NULL OR status IN ('read', 'actioned', 'dismissed')),
    CONSTRAINT ck_messages_actioned_at CHECK (actioned_at IS NULL OR status IN ('actioned'))
);

-- Indexes
CREATE INDEX idx_messages_recipient ON messages(recipient_id, recipient_type);
CREATE INDEX idx_messages_status ON messages(recipient_id, status) WHERE status = 'unread';
CREATE INDEX idx_messages_type ON messages(type);
CREATE INDEX idx_messages_related_entity ON messages(related_entity_id, related_entity_type);
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);
```

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| type | message_type | Enum |
| title | varchar(200) | Short display title |
| body | text | Full message content |
| recipient_id | UUID | Member or admin ID |
| recipient_type | varchar(20) | 'member' or 'admin' |
| sender_id | UUID | Nullable (system messages) |
| sender_type | varchar(20) | 'member', 'admin', 'system' |
| status | message_status | Default 'unread' |
| read_at | timestamptz | When first read |
| actioned_at | timestamptz | When action taken |
| action_result | varchar(50) | Result of action |
| related_entity_id | UUID | FK to related record |
| related_entity_type | varchar(50) | Type of related record |
| action_type | varchar(50) | UI action buttons |
| metadata | jsonb | Type-specific data |
| created_at | timestamptz | |
| expires_at | timestamptz | Auto-dismiss time |

---

### New: issue_verifications

Track verification requests and results:

```sql
-- V0XX__create_issue_verifications_table.sql
CREATE TABLE issue_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Which issue
    issue_id UUID NOT NULL REFERENCES issues(id) ON DELETE CASCADE,
    
    -- What type of verification
    verification_type VARCHAR(20) NOT NULL,  -- 'existence' or 'fix'
    
    -- Who was assigned (if admin_assigns mode)
    assigned_to UUID NULL REFERENCES members(id) ON DELETE SET NULL,
    
    -- Who actually verified
    verified_by UUID NULL REFERENCES members(id) ON DELETE SET NULL,
    
    -- Result
    result VARCHAR(20) NULL,  -- 'confirmed', 'not_found', 'not_fixed', etc.
    reason verification_reason NULL,
    note TEXT NULL,
    
    -- Photo evidence
    photo_id UUID NULL REFERENCES issue_photos(id) ON DELETE SET NULL,
    
    -- Timing
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    responded_at TIMESTAMPTZ NULL,
    
    -- Status
    status VARCHAR(20) NOT NULL DEFAULT 'pending',  -- 'pending', 'completed', 'expired'
    
    CONSTRAINT ck_issue_verifications_type CHECK (verification_type IN ('existence', 'fix')),
    CONSTRAINT ck_issue_verifications_status CHECK (status IN ('pending', 'completed', 'expired'))
);

-- Indexes
CREATE INDEX idx_issue_verifications_issue ON issue_verifications(issue_id);
CREATE INDEX idx_issue_verifications_assigned ON issue_verifications(assigned_to) WHERE status = 'pending';
CREATE INDEX idx_issue_verifications_pending ON issue_verifications(status) WHERE status = 'pending';
```

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| issue_id | UUID | FK to issues |
| verification_type | varchar(20) | 'existence' or 'fix' |
| assigned_to | UUID | FK to members (nullable) |
| verified_by | UUID | FK to members (who responded) |
| result | varchar(20) | Verification outcome |
| reason | verification_reason | If cannot verify |
| note | text | Optional note |
| photo_id | UUID | FK to issue_photos |
| requested_at | timestamptz | |
| responded_at | timestamptz | |
| status | varchar(20) | pending/completed/expired |

---

### New: ground_admin_applications

Track Ground Admin applications and invitations:

```sql
-- V0XX__create_ground_admin_applications_table.sql
CREATE TABLE ground_admin_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Who
    member_id UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    sector_id UUID NOT NULL REFERENCES sectors(id) ON DELETE CASCADE,
    
    -- Type: member applied or admin invited
    type VARCHAR(20) NOT NULL,  -- 'application' or 'invitation'
    
    -- If invitation, who invited
    invited_by UUID NULL REFERENCES members(id) ON DELETE SET NULL,
    
    -- Status tracking
    status VARCHAR(20) NOT NULL DEFAULT 'pending',  -- 'pending', 'approved', 'declined', 'accepted', 'rejected'
    
    -- Outcome details
    processed_by UUID NULL REFERENCES members(id) ON DELETE SET NULL,
    processed_at TIMESTAMPTZ NULL,
    decline_reason TEXT NULL,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT ck_ga_applications_type CHECK (type IN ('application', 'invitation')),
    CONSTRAINT ck_ga_applications_status CHECK (status IN ('pending', 'approved', 'declined', 'accepted', 'rejected', 'withdrawn'))
);

-- Indexes
CREATE INDEX idx_ga_applications_member ON ground_admin_applications(member_id);
CREATE INDEX idx_ga_applications_sector ON ground_admin_applications(sector_id);
CREATE INDEX idx_ga_applications_pending ON ground_admin_applications(sector_id, status) WHERE status = 'pending';
```

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| member_id | UUID | FK to members |
| sector_id | UUID | FK to sectors |
| type | varchar(20) | 'application' or 'invitation' |
| invited_by | UUID | FK to members (if invitation) |
| status | varchar(20) | Workflow status |
| processed_by | UUID | Admin who processed |
| processed_at | timestamptz | |
| decline_reason | text | If declined |
| created_at | timestamptz | |
| updated_at | timestamptz | |

---

## Migration Order

Migrations applied in this order (completed 2026-01-19):

```
-- sector_chief already existed in admin_role enum (V002), skipped
V012__add_closed_issue_state.sql              -- Enum update
V013__create_ground_admin_status_enum.sql     -- New enum
V014__create_verification_mode_enum.sql       -- New enum
V015__create_message_type_enum.sql            -- New enum
V016__create_message_status_enum.sql          -- New enum
V017__create_verification_reason_enum.sql     -- New enum
V018__add_ground_admin_fields_to_members.sql  -- Alter members
V019__create_sector_settings_table.sql        -- New table
V020__create_messages_table.sql               -- New table
V021__create_issue_verifications_table.sql    -- New table (depends on members)
V022__create_ground_admin_applications_table.sql -- New table (depends on members)
```

---

## Shared Types (TypeScript/Dart)

### GroundAdminStatus

```typescript
// TypeScript
type GroundAdminStatus = 'active' | 'on_hold' | 'inactive';

// Dart
enum GroundAdminStatus { active, onHold, inactive }
```

### VerificationMode

```typescript
// TypeScript
type VerificationMode = 'all_notified' | 'admin_assigns' | 'nearest_auto' | 'first_come';

// Dart
enum VerificationMode { allNotified, adminAssigns, nearestAuto, firstCome }
```

### MessageType

```typescript
// TypeScript
type MessageType =
  | 'ground_admin_invitation'
  | 'ground_admin_application'
  | 'ground_admin_approved'
  | 'ground_admin_declined'
  | 'ground_admin_invitation_declined'
  | 'ground_admin_revocation'
  | 'ground_admin_stepdown_request'
  | 'verify_new_issue'
  | 'verify_fix'
  | 'member_registration'
  | 'monthly_report';
```

### MessageStatus

```typescript
// TypeScript
type MessageStatus = 'unread' | 'read' | 'actioned' | 'dismissed';

// Dart
enum MessageStatus { unread, read, actioned, dismissed }
```

### Message

```typescript
// TypeScript
interface Message {
  id: string;
  type: MessageType;
  title: string;
  body: string;
  recipientId: string;
  recipientType: 'member' | 'admin';
  status: MessageStatus;
  actionType?: string;
  relatedEntityId?: string;
  relatedEntityType?: string;
  actionResult?: string;
  createdAt: string;
  readAt?: string;
  actionedAt?: string;
}
```

### SectorSettings

```typescript
// TypeScript
interface SectorSettings {
  id: string;
  sectorId: string;
  newIssueVerificationMode: VerificationMode;
  fixVerificationMode: VerificationMode;
  daysFixedBeforeClosed: number;
  minimumGroundAdmins: number;
}
```

### IssueVerification

```typescript
// TypeScript
interface IssueVerification {
  id: string;
  issueId: string;
  verificationType: 'existence' | 'fix';
  assignedTo?: string;
  verifiedBy?: string;
  result?: string;
  reason?: VerificationReason;
  note?: string;
  photoId?: string;
  requestedAt: string;
  respondedAt?: string;
  status: 'pending' | 'completed' | 'expired';
}
```

---

## Entity Relationships

```
┌─────────────────────────────────────────────────────────────────────┐
│                        ENTITY RELATIONSHIPS                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  sectors ─────────────┬──────────────────────────────────────────┐  │
│     │                 │                                          │  │
│     │              1:1│                                          │  │
│     │                 ▼                                          │  │
│     │          sector_settings                                   │  │
│     │                                                            │  │
│     │  1:n                                                       │  │
│     ▼                                                            │  │
│  members ◄────────────────────────────────────────────┐          │  │
│     │  (is_ground_admin, ground_admin_status)         │          │  │
│     │                                                 │          │  │
│     │  1:n                              1:n           │          │  │
│     ▼                                   │             │          │  │
│  messages                               │             │          │  │
│     │                                   │             │          │  │
│     │ related_entity_id ────────────────┼─────────────┤          │  │
│     │                                   │             │          │  │
│     │                                   │             │          │  │
│  issues ◄───────────────────────────────┘             │          │  │
│     │                                                 │          │  │
│     │  1:n                                            │          │  │
│     ▼                                                 │          │  │
│  issue_verifications ─────────────────────────────────┘          │  │
│     │  (assigned_to, verified_by → members)                      │  │
│     │                                                            │  │
│     │  n:1                                                       │  │
│     ▼                                                            │  │
│  issue_photos (optional verification photo)                      │  │
│                                                                  │  │
│                                                                  │  │
│  ground_admin_applications                                       │  │
│     │  (member_id, invited_by, processed_by → members)           │  │
│     │  (sector_id → sectors)                                     │  │
│                                                                  │  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Queries Reference

### Get Active Ground Admins in Sector

```sql
SELECT m.*
FROM members m
WHERE m.sector_id = :sector_id
  AND m.is_ground_admin = TRUE
  AND m.ground_admin_status = 'active';
```

### Get Unread Messages for Member

```sql
SELECT *
FROM messages
WHERE recipient_id = :member_id
  AND recipient_type = 'member'
  AND status = 'unread'
ORDER BY created_at DESC;
```

### Get Pending Verifications for Ground Admin

```sql
SELECT iv.*, i.type, i.location
FROM issue_verifications iv
JOIN issues i ON i.id = iv.issue_id
WHERE (iv.assigned_to = :member_id OR iv.assigned_to IS NULL)
  AND iv.status = 'pending'
  AND i.sector_id = :sector_id;
```

### Check if Sector Has Minimum Ground Admins

```sql
SELECT 
    s.id AS sector_id,
    ss.minimum_ground_admins,
    COUNT(m.id) AS current_count,
    COUNT(m.id) < ss.minimum_ground_admins AS below_minimum
FROM sectors s
JOIN sector_settings ss ON ss.sector_id = s.id
LEFT JOIN members m ON m.sector_id = s.id 
    AND m.is_ground_admin = TRUE 
    AND m.ground_admin_status = 'active'
WHERE s.id = :sector_id
GROUP BY s.id, ss.minimum_ground_admins;
```

### Auto-Close Fixed Issues

```sql
-- Scheduled job query
UPDATE issues
SET state = 'closed',
    updated_at = NOW()
WHERE state = 'fixed'
  AND updated_at < NOW() - (
    SELECT INTERVAL '1 day' * ss.days_fixed_before_closed
    FROM sector_settings ss
    WHERE ss.sector_id = issues.sector_id
  );
```
