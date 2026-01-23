---
issue: 20
title: "Adding the Rest of the Roles"
platform: database
status: completed
created_by: central-agent
created_at: 2026-01-23
updated_at: 2026-01-23
dependencies: []
files_changed:
  - backend/src/main/resources/db/migration/V027__create_wards_table.sql
  - backend/src/main/resources/db/migration/V028__add_ward_roles_to_enum.sql
  - backend/src/main/resources/db/migration/V029__add_ward_references.sql
  - backend/src/main/resources/db/migration/V030__add_ward_role_test_accounts.sql
tests_added: []
commits: []
blockers: []
---

# Issue #20: Adding the Rest of the Roles (Database)

## Status: COMPLETED

## Implementation Summary

Created 4 database migrations to support the 6-level role hierarchy:

### V027: Create Wards Table
- Created `wards` table with PostGIS geography columns (center, boundary)
- Added indexes for pod_id and spatial queries
- Added unique constraint on (pod_id, name)

### V028: Add Ward Roles to Enum
- Recreated `admin_role` enum with correct ordinal order
- New values: `ward_admin` (2), `ward_chief` (3)
- Full enum: sector_admin, sector_chief, ward_admin, ward_chief, pod_admin, pod_chief

### V029: Add Ward References
- Added `uses_wards` boolean to `pods` table
- Added `ward_id` to `sectors` table (nullable)
- Added `pod_id` and `ward_id` to `admins` table
- Made `sector_id` nullable in `admins`
- Added check constraint `ck_admins_role_scope` to enforce proper scope fields

### V030: Test Accounts
- Created test ward: "Test Ward North"
- Created test accounts with bcrypt-hashed passwords:
  - podchief@munserv.local / podchief123
  - podadmin@munserv.local / podadmin123
  - wardchief@munserv.local / wardchief123
  - wardadmin@munserv.local / wardadmin123

## Acceptance Criteria (All Met)

- [x] Wards table exists with correct schema
- [x] admin_role enum has all 6 values in correct order
- [x] admins table has pod_id and ward_id columns (nullable)
- [x] sectors table has ward_id column (nullable)
- [x] Check constraint enforces role-scope relationship
- [x] All test accounts created successfully
