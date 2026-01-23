---
issue: 20
title: "Adding the Rest of the Roles"
platform: backend
status: completed
created_by: central-agent
created_at: 2026-01-23
updated_at: 2026-01-23
dependencies:
  - database (completed)
files_changed:
  - backend/src/main/kotlin/com/munserv/shared/types/WardId.kt
  - backend/src/main/kotlin/com/munserv/admin/domain/Admin.kt
  - backend/src/main/kotlin/com/munserv/admin/domain/CreateAdminCommand.kt
  - backend/src/main/kotlin/com/munserv/admin/repository/AdminEntity.kt
  - backend/src/main/kotlin/com/munserv/admin/repository/AdminRepository.kt
  - backend/src/main/kotlin/com/munserv/admin/repository/JpaAdminRepository.kt
  - backend/src/main/kotlin/com/munserv/admin/service/AdminManagementService.kt
  - backend/src/main/kotlin/com/munserv/admin/service/AdminResult.kt
  - backend/src/main/kotlin/com/munserv/admin/api/AdminManagementDto.kt
  - backend/src/main/kotlin/com/munserv/admin/api/AdminManagementController.kt
  - backend/src/main/kotlin/com/munserv/auth/service/AuthResult.kt
  - backend/src/main/kotlin/com/munserv/auth/service/AuthService.kt
  - backend/src/main/kotlin/com/munserv/auth/api/AuthController.kt
  - backend/src/main/kotlin/com/munserv/auth/api/AuthResponse.kt
tests_added: []
commits: []
blockers: []
---

# Issue #20: Adding the Rest of the Roles (Backend)

## Status: COMPLETED

## Implementation Summary

### Domain Layer Changes

1. **WardId.kt** (new)
   - Added type-safe value class for ward identifiers

2. **Admin.kt**
   - Added `AdminLevel` enum (SECTOR, WARD, POD)
   - Added `WARD_ADMIN`, `WARD_CHIEF` to `AdminRole` enum
   - Added `level` and `isChief` properties to AdminRole
   - Updated Admin data class: added `podId`, `wardId`, made `sectorId` nullable

3. **CreateAdminCommand.kt**
   - Added `podId`, `wardId` fields
   - Made `sectorId` nullable
   - Added validation for scope fields based on role level

### Repository Layer Changes

4. **AdminEntity.kt**
   - Added `podId`, `wardId` columns (nullable)
   - Made `sectorId` nullable
   - Updated `toDomain()` and `fromDomain()` mappings

5. **AdminRepository.kt**
   - Added `findByWardId()` method
   - Added `findByPodId()` method

6. **JpaAdminRepository.kt**
   - Implemented new finder methods

### Service Layer Changes

7. **AdminManagementService.kt**
   - Added `checkCreationScope()` method
   - Added `checkViewScope()` method
   - Added `checkAdminInScope()` method
   - Added `listAdminsByWard()` method
   - Added `listAdminsByPod()` method
   - Updated all CRUD operations to use scope checking

8. **AdminResult.kt**
   - Added `CrossWardOperation` result type
   - Added `CrossPodOperation` result type
   - Added `OutOfScope` result type

### API Layer Changes

9. **AdminManagementDto.kt**
   - Updated `CreateAdminRequest` with scope fields
   - Updated `AdminResponse` with level, podId, wardId
   - Updated `AdminCreatedResponse` similarly

10. **AdminManagementController.kt**
    - Added error handling for new result types

### Auth Changes

11. **AuthResult.kt, AuthService.kt, AuthController.kt, AuthResponse.kt**
    - Updated `AdminLoginSuccess` to support nullable sector info
    - Added `level`, `podId`, `wardId` to admin login response
    - Made sector fields nullable for pod/ward-level admins

## Acceptance Criteria (All Met)

- [x] AdminRole enum has 6 values in correct ordinal order
- [x] `hasPermission()` works correctly for all role pairs
- [x] `canManage()` works correctly for all role pairs
- [x] Admin creation validates correct ID field based on role
- [x] Pod/ward admins can manage admins in their scope
- [x] Sector chiefs cannot manage ward/pod admins
- [x] Backend compiles successfully
