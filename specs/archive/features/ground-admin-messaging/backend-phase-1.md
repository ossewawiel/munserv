# Ground Admin & Messaging - Backend Phase 1: Database Foundation

## Status: :white_check_mark: Completed (2026-01-19)

## Overview
Create all database migrations, enums, and shared types for the Ground Admin & Messaging feature.

## Prerequisites
- Database running (Docker: `docker-compose up -d`)
- Backend compiles successfully
- Existing migrations applied

---

## Completed Migrations

All migrations created in `backend/src/main/resources/db/migration/`:

| # | Migration File | Description |
|---|----------------|-------------|
| 1 | `V012__add_closed_issue_state.sql` | Add `closed` to `issue_state` enum |
| 2 | `V013__create_ground_admin_status_enum.sql` | Create `ground_admin_status` enum |
| 3 | `V014__create_verification_mode_enum.sql` | Create `verification_mode` enum |
| 4 | `V015__create_message_type_enum.sql` | Create `message_type` enum |
| 5 | `V016__create_message_status_enum.sql` | Create `message_status` enum |
| 6 | `V017__create_verification_reason_enum.sql` | Create `verification_reason` enum |
| 7 | `V018__add_ground_admin_fields_to_members.sql` | Add Ground Admin fields to `members` table |
| 8 | `V019__create_sector_settings_table.sql` | Create `sector_settings` table |
| 9 | `V020__create_messages_table.sql` | Create `messages` table |
| 10 | `V021__create_issue_verifications_table.sql` | Create `issue_verifications` table |
| 11 | `V022__create_ground_admin_applications_table.sql` | Create `ground_admin_applications` table |

**Note:** Migration for `sector_chief` role was not needed - it already existed in `admin_role` enum (V002).

---

## Completed Kotlin Enum Classes

All enums created in `backend/src/main/kotlin/com/munserv/shared/enums/`:

| File | Values |
|------|--------|
| `GroundAdminStatus.kt` | `ACTIVE`, `ON_HOLD`, `INACTIVE` |
| `VerificationMode.kt` | `ALL_NOTIFIED`, `ADMIN_ASSIGNS`, `NEAREST_AUTO`, `FIRST_COME` |
| `MessageType.kt` | 11 message types for all platform communications |
| `MessageStatus.kt` | `UNREAD`, `READ`, `ACTIONED`, `DISMISSED` |
| `VerificationReason.kt` | `BUSY`, `AWAY`, `CANNOT_FIND`, `WRONG_LOCATION`, `NOT_AN_ISSUE` |

---

## Updated Existing Code

### IssueState.kt

Updated `backend/src/main/kotlin/com/munserv/issues/domain/IssueState.kt`:
- Added `Closed` data object as terminal state
- Added `Fixed -> Closed` transition
- Updated `entries` list and `fromString()` function

---

## Verification Commands

```bash
# Run migrations
cd backend
./gradlew bootRun  # Migrations run on startup

# Check migration status (if using Flyway CLI)
./gradlew flywayInfo

# Verify tables created via postgres MCP:
# SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';

# Verify enums via postgres MCP:
# SELECT enumlabel FROM pg_enum WHERE enumtypid = 'message_type'::regtype;

# Run tests to ensure nothing broke
./gradlew test
```

---

## Definition of Done

- [x] All 11 migrations created (sector_chief already existed)
- [x] All Kotlin enum classes created
- [x] IssueState.kt updated with Closed state
- [x] Code compiles successfully
- [x] IssueState tests pass
- [x] Database schema matches data-model.md

---

## Remaining Work for Other Phases

The following items from the original spec are **not part of Phase 1** and will be done in later phases:

- [ ] Update shared TypeScript types (Phase 2/3)
- [ ] Update shared Dart models (Phase 3)

---

## Migration Details Reference

### Enum Values

**ground_admin_status:**
- `active` - Normal operation, receives verification requests
- `on_hold` - Temporarily paused (low response rate)
- `inactive` - Stepped down or revoked

**verification_mode:**
- `all_notified` - All Ground Admins in sector notified
- `admin_assigns` - Admin manually picks Ground Admin
- `nearest_auto` - System assigns nearest based on address
- `first_come` - All notified, first to respond handles it

**message_type:**
- `ground_admin_invitation`, `ground_admin_application`, `ground_admin_approved`
- `ground_admin_declined`, `ground_admin_invitation_declined`, `ground_admin_revocation`
- `ground_admin_stepdown_request`, `verify_new_issue`, `verify_fix`
- `member_registration`, `monthly_report`

**message_status:**
- `unread`, `read`, `actioned`, `dismissed`

**verification_reason:**
- `busy`, `away`, `cannot_find`, `wrong_location`, `not_an_issue`

### New Tables

1. **sector_settings** - Sector-level configuration for Ground Admin and issues
2. **messages** - Generic messaging system for all platform communications
3. **issue_verifications** - Track verification requests and results
4. **ground_admin_applications** - Track Ground Admin applications and invitations

### Modified Tables

1. **members** - Added Ground Admin tracking fields:
   - `is_ground_admin` (boolean)
   - `ground_admin_status` (enum)
   - `ground_admin_since` (timestamptz)
   - `ground_admin_response_rate` (decimal)
