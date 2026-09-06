# Backend Requirements

## Pod Chief MVP Stories

| ID | Story | Acceptance Criteria | Status | Issue |
|----|-------|---------------------|--------|-------|
| B1 | Pod setup status and settings API | Setup status endpoint works ǀ Settings CRUD works ǀ Tests pass | 🟢 Done | [#33](https://github.com/ossewawiel/munserv/issues/33) |
| B2 | Pod dashboard statistics API | Pod stats endpoint works ǀ Ward/sector stats work ǀ Tests pass | 🟢 Done | [#34](https://github.com/ossewawiel/munserv/issues/34) |
| B3 | Pod administrators management API | List admins works ǀ Create admin works ǀ Email sent ǀ Tests pass | 🟢 Done | [#35](https://github.com/ossewawiel/munserv/issues/35) |
| B4 | Administrator onboarding API | Password change works ǀ Profile completion works ǀ Welcome message sent ǀ Tests pass | 🟢 Done | [#36](https://github.com/ossewawiel/munserv/issues/36) |
| B10 | As a new administrator, I receive a welcome message with my initial tasks when my account is created | `admin_welcome` message type in domain, Kotlin, DB enum, contracts and Dart ǀ `POST /pod/administrators` creates the message ǀ `metadata.tasks` lists the initial tasks ǀ Domain language validation and tests pass | 🟢 Done | [#95](https://github.com/ossewawiel/munserv/issues/95) |
| B11 | As a Pod Chief, I can upload a pod logo file | `POST /pod/logo` multipart, pod chief only ǀ Stored through the existing photo storage and served from `/uploads` ǀ Returns `{ logoUrl }` ǀ `PATCH /pod/settings` keeps accepting `logoUrl` ǀ Documented in api.md ǀ Tests pass | 🔴 Pending | [#96](https://github.com/ossewawiel/munserv/issues/96) |

## Pod Chief Bootstrap Stories

| ID | Story | Acceptance Criteria | Status | Issue |
|----|-------|---------------------|--------|-------|
| B5 | As a developer, I can configure super user via environment | `SUPER_USER_EMAIL`, `SUPER_USER_PASSWORD` env vars ǀ `bootstrap.super-user.*` config properties ǀ Enabled flag to disable feature | 🟢 Done | [#46](https://github.com/ossewawiel/munserv/issues/46) |
| B6 | As a developer, the system checks bootstrap eligibility | Query: Pod Chief exists AND is onboarded? ǀ Returns bootstrap status ǀ No new DB table needed | 🟢 Done | [#47](https://github.com/ossewawiel/munserv/issues/47) |
| B7 | As a developer, bootstrap actions are audit logged | All super user actions logged ǀ Includes timestamp, action type, actor ǀ Pod Chief creation logged | 🟢 Done | [#48](https://github.com/ossewawiel/munserv/issues/48) |
| B8 | As a developer, the system tracks temporary super user grants | Store grants with: role, purpose, granted_by, granted_at, expires_at, last_activity ǀ Auto-expire logic ǀ Activity tracking updates last_activity | 🟢 Done | [#49](https://github.com/ossewawiel/munserv/issues/49) |
| B9 | As a super user, I can log in to a bootstrapped pod under an active support grant so that I can help with a live problem under the role the pod chief allowed | Login succeeds when an active grant exists and the pod is not bootstrap-eligible ǀ JWT subject is the grant id and its role is the granted role only ǀ Login response carries grantId, grantedRole, expiresAt ǀ `GET /support-access/grants/current` returns the caller's own grant ǀ `POST /auth/logout` revokes a grant-scoped login ǀ `SUPPORT_ACCESS_LOGIN` audit entry written | 🟢 Done | [#68](https://github.com/ossewawiel/munserv/issues/68) |

## Status Legend
- 🟢 Done
- 🟡 In Progress
- 🔴 Pending

## Stack
Kotlin 2.3 + Spring Boot 4 + PostgreSQL 18 + PostGIS
