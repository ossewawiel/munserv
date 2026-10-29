# Investigation: enum columns written as varchar break verification requests and sector settings

Issue: #166 · Investigated 2026-10-29 · Platform: backend · Fix handoff: `166-verification-enum-cast-backend.md`

## Problem
`POST /api/v1/issues/{issueId}/request-verification` answers `500 INTERNAL_ERROR` on every call. No admin can request a [verification](../../../domain/verification.md). Ground admins never receive one, and `scripts/dev-seed.py` stops at its last step. The same class of defect also breaks `GET` and `PATCH /api/v1/sectors/{sectorId}/settings`, which the web Sector Settings page (`/settings/sector`) calls.

## Reproduction
The reproduction ran on the live dev stack: the backend runs from `~/Work/munserv-console` at `f6c23ed` with the `local` profile, and the dev database is on port 5435. No data changed: both failing calls roll back, and the row counts read before and after match.

| Step | Call | Answer |
|---|---|---|
| 1 | `POST /api/v1/auth/admin/login` as `admin@ward42.example.com` | `200` |
| 2 | `POST /api/v1/issues/550e8400-e29b-41d4-a716-446655440103/request-verification`, body `{"type":"existence"}` | `500 INTERNAL_ERROR` |
| 3 | `POST /api/v1/auth/admin/login` as `chief@munserv.local` | `200` |
| 4 | `GET /api/v1/sectors/550e8400-e29b-41d4-a716-446655440001/settings` as the sector chief | `500 INTERNAL_ERROR` |

The backend log (`~/Work/munserv-console/.console/logs/backend.log`) records both failures.

- Step 2, 09:09:51: Hibernate binds parameter 6 of the INSERT into `issue_verifications` as `(6:VARCHAR) <- [null]`. PostgreSQL answers `ERROR: column "reason" is of type verification_reason but expression is of type character varying` (SQLState `42804`).
- Step 4, 09:10:28: `InvalidDataAccessApiUsageException: No enum constant com.munserv.shared.enums.VerificationMode.all_notified`, thrown from `JpaSectorSettingsRepository.findBySectorId` (`JpaSectorSettingsRepository.kt:29`).

`issue_verifications` holds zero rows before and after step 2. No message was created in the same window.

## Steps taken
1. Read `domain/verification.md`. `reason` is one of `busy`, `away`, `cannot_find`, `wrong_location`, `not_an_issue`, and only a declined verification carries one. A pending verification has none.
2. Followed the request: `VerificationController.kt:63-80` → `VerificationService.requestVerification` (`VerificationService.kt:51-89`) → `DefaultIssueVerificationRepository.save` → `IssueVerificationEntity.fromDomain` → `V021__create_issue_verifications_table.sql:24`.
3. Listed every enum-typed column in the live schema from `information_schema.columns` joined to `pg_type.typtype = 'e'`. There are 13. Matched each one to its entity field (table below).
4. Ran the INSERT shape through `EXPLAIN`, which type-checks a statement without running it, on the dev database:
   - `reason` given as `CAST(NULL AS varchar)` fails with the same `42804` error as the log.
   - `reason` given as `CAST(CAST(NULL AS varchar) AS verification_reason)` passes, and so does `'busy'` through the same cast.
   - An UPDATE of `new_issue_verification_mode` through `CAST(... AS verification_mode)` passes.
5. Swept every Spring Data repository on the 8 entities for queries that compare an enum column to a bound parameter.
6. Read the tests that touch verification and sector settings to find why CI stays green.

## Root cause
`IssueVerificationEntity.kt:36-37` maps `issue_verifications.reason`, a PostgreSQL `verification_reason` enum, as a plain `String?`:

```kotlin
@Column(name = "reason", length = 50)
val reason: String? = null,
```

Hibernate binds a `String` as `VARCHAR`. PostgreSQL has no implicit or assignment cast from `varchar` to an enum. It rejects the value even when the value is null, because the bound parameter still carries the `varchar` type. A new verification always has `reason = null`, so every INSERT fails.

The request reaches the INSERT in this way. `requestVerification` calls `verificationRepository.save` at `VerificationService.kt:84`, which only queues the INSERT. `sendVerificationMessages` then calls `notifyAllGroundAdmins`, and that runs a native query at `VerificationService.kt:333`. Hibernate flushes the queued INSERT before the query runs. The INSERT fails there, the transaction rolls back, and `GlobalExceptionHandler` turns the `InvalidDataAccessResourceUsageException` into `500`.

The suspected cause in #166 is **confirmed**. One correction: the failure is not specific to a non-null reason. The null case alone breaks every call.

## Every enum column and its mapping
Ten of the 13 columns use the house pattern: a `String` field with `columnDefinition = "<type>"` and `@ColumnTransformer(write = "?::<type>")`. Three do not.

| Table.column | PG type | Entity | Write cast | State |
|---|---|---|---|---|
| `admins.role` | `admin_role` | `AdminEntity.kt:45-47` | yes | works |
| `admins.onboarding_status` | `onboarding_status` | `AdminEntity.kt:48-50` | yes | works |
| `audit_logs.action` | `audit_action_type` | `AuditLogEntity.kt:27-29` | yes | works |
| `issue_state_history.state` | `issue_state` | `IssueStateHistoryEntity.kt:27-29` | yes | works |
| `issues.type` | `issue_type` | `IssueEntity.kt:35-37` | yes | works |
| `issues.state` | `issue_state` | `IssueEntity.kt:38-40` | yes | works |
| `members.status` | `member_status` | `MemberEntity.kt:64-66` | yes | works |
| `members.ground_admin_status` | `ground_admin_status` | `MemberEntity.kt:76-78` | yes | works |
| `messages.type` | `message_type` | `MessageEntity.kt:26-28` | yes | works |
| `messages.status` | `message_status` | `MessageEntity.kt:41-43` | yes | works |
| **`issue_verifications.reason`** | `verification_reason` | `IssueVerificationEntity.kt:36-37` | **no** | **every INSERT and UPDATE fails** |
| **`sector_settings.new_issue_verification_mode`** | `verification_mode` | `SectorSettingsEntity.kt:27-29` | **no** | **every read and write fails** |
| **`sector_settings.fix_verification_mode`** | `verification_mode` | `SectorSettingsEntity.kt:30-32` | **no** | **every read and write fails** |

`issue_verifications.verification_type`, `.result` and `.status` are `VARCHAR` with CHECK constraints, not enums. Their plain `String` mapping is correct.

### The two `verification_mode` columns fail twice
`SectorSettingsEntity` maps both columns as `@Enumerated(EnumType.STRING) val …: VerificationMode`. `EnumType.STRING` uses the Kotlin constant name, so it writes `ALL_NOTIFIED` and reads with `VerificationMode.valueOf(...)`. The database labels are `all_notified` and the other snake_case values from V014. The read fails first: the dev database holds `all_notified` in both rows, and `valueOf("all_notified")` throws. A write would fail twice: the value binds as `varchar` with no cast, and `ALL_NOTIFIED` is not a label of `verification_mode`. A cast alone does not fix these columns. The entity must also map through `VerificationMode.toApiString()` and `VerificationMode.fromString()`, as `MemberEntity` does for `GroundAdminStatus`.

A sector chief who opens Sector Settings in the web portal today sees the page fail to load. `SectorSettingsService.getSettings` (`SectorSettingsService.kt:33`) throws while it maps the row, before any role or business logic runs.

### Read-side comparisons, latent
`@ColumnTransformer(write = …)` covers INSERT and UPDATE only. A query that compares an enum column to a bound `String` fails with `operator does not exist: <type> = character varying`. The dev database confirms this: `SELECT count(*) FROM issues WHERE state = CAST('reported' AS varchar)` raises that error. The swept repositories hold two such queries:

- `JpaIssueRepository.kt:24`, the derived query `findByState(state: String)`, reached through `IssueRepository.findByState` (`IssueRepository.kt:24`).
- `JpaAuditLogRepository.kt:19`, JPQL `a.action = :action`, reached through `AuditLogRepository.findByPodIdAndAction`.

Neither has a caller outside its own repository, so no request reaches them today. Every other enum filter uses `CAST(:x AS <type>)` in a native query (`JpaMemberRepository`, `JpaAdminRepository`, `MessageRepository`). The fix handoff leaves these two alone. They need a separate issue: cast them, or delete them under the no-dead-code rule.

## Why no test caught it
- **The verification path has no test that reaches the database.** `VerificationServiceTest` mocks `IssueVerificationRepository` with MockK. There is no repository test for `issue_verifications`, and there is no `VerificationController` test of any kind.
- **The sector settings path mocks the service.** `SectorSettingsControllerTest` is a `@SpringBootTest` with Testcontainers, but it declares `@MockkBean SectorSettingsService`. The JSON round trip passes, and the entity is never loaded. `SectorSettingsServiceTest` mocks the repository. No repository test exists for `sector_settings`.
- **Schema validation does not see the mismatch.** `application.yml:34` sets `ddl-auto: validate`, and the backend starts with all three mismatched columns in place. The validator accepts an enum column for a `String` or `EnumType.STRING` field.
- **A save-only repository test would not catch it either.** Both entities assign their own UUID, so Spring Data treats `save` as a merge. Hibernate queues the INSERT until a flush, and `@DataJpaTest` rolls back without one. A test must call `TestEntityManager.flush()` (then `clear()` and read back) to make PostgreSQL see the statement. `IssueStateHistoryRepositoryTest` shows the shape that misses this: it asserts on the object `save` returns.

## Affected components

### Backend (fix)
- `backend/src/main/kotlin/com/munserv/verification/repository/IssueVerificationEntity.kt:36-37`: add the cast for `reason`. This fixes request-verification and the decline path of `POST /issues/{issueId}/verify` (`result: cannot_verify` with a `reason`), which writes `reason` through the same entity.
- `backend/src/main/kotlin/com/munserv/sectors/repository/SectorSettingsEntity.kt:27-32` and its `toDomain` / `fromDomain`: map both modes as `String` with the cast, converting through `toApiString` / `fromString`. This fixes `GET` and `PATCH /api/v1/sectors/{sectorId}/settings` and the default-settings insert in `SectorSettingsService.createDefaultSettings`.

### Web
No change. `web/src/features/sector-settings/api.ts` already sends and expects the snake_case wire values, which `VerificationMode`'s `@JsonValue` produces. The Sector Settings page starts to load once the backend is fixed.

### Mobile
No change. The verify flow calls the same endpoints, and the wire contract stays the same.

### Database
No migration. The enum types and columns are correct. The entities are wrong.

## Fix approach
Use the pattern the other 10 enum columns already use. Do not switch to `@JdbcTypeCode(SqlTypes.NAMED_ENUM)`: it would still write the Kotlin constant name for `VerificationMode`, and it would make these 3 columns differ from the other 10.

1. `IssueVerificationEntity.reason`: `@Column(name = "reason", columnDefinition = "verification_reason")` plus `@ColumnTransformer(write = "?::verification_reason")`. The field stays `String?`, and `fromDomain` / `toDomain` already convert through `toApiString` / `fromString`.
2. `SectorSettingsEntity` modes: change both fields to `String` with `columnDefinition = "verification_mode"` and `@ColumnTransformer(write = "?::verification_mode")`. Drop `@Enumerated`. Convert in `fromDomain` with `toApiString()` and in `toDomain` with `VerificationMode.fromString(...)`.
3. Tests first: repository tests that flush against Testcontainers for both entities, and a `@SpringBootTest` request-verification case that answers `200` with no mocks below the controller.

## Risk
- **Low for the code change.** Three field mappings change. The wire, the domain and the schema stay the same. A cast on a null parameter yields null, which the `EXPLAIN` check above confirms.
- **Behaviour that starts to run.** After the fix, request-verification creates messages for every active ground admin in the sector. On the dev database that is Sipho Dlamini. That is the intended flow, but it has never run end to end, so a later step can still fail. The `@SpringBootTest` case with a seeded ground admin guards it.
- **`fromString` on a bad label.** `VerificationMode.fromString` throws on an unknown value. The database enum allows only the four labels the Kotlin enum knows, so the read cannot meet one.
- **Unblocks other checks.** #163's Eyeball check E5 and plan step S40 (`scripts/dev-seed.py`) are both blocked by this issue.
