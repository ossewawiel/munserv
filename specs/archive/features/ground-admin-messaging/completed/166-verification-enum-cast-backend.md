---
issue: 166
story: ""               # bug fix, no story id; Operation V1 plan step S40 found it
title: "Verification reason and sector verification modes are written to their Postgres enum columns with a cast"
platform: backend
status: completed
depends_on: []
touches: [ground-admin-messaging]
ui: false
design_canvas: ""
design_artboards: []
design_approved: false
created_by: investigator
created_at: "2026-10-29"
files_changed:
  - backend/src/main/kotlin/com/munserv/verification/repository/IssueVerificationEntity.kt
  - backend/src/main/kotlin/com/munserv/sectors/repository/SectorSettingsEntity.kt
tests_added:
  - backend/src/test/kotlin/com/munserv/verification/repository/IssueVerificationRepositoryTest.kt
  - backend/src/test/kotlin/com/munserv/sectors/repository/SectorSettingsRepositoryTest.kt
  - backend/src/test/kotlin/com/munserv/verification/api/VerificationFlowIntegrationTest.kt
---

# #166 · Enum columns get their cast (Backend)

Read `domain/README.md` and `domain/verification.md` for every term used below. This handoff is complete on its own. The evidence is in `166-verification-enum-cast-investigation.md` in this folder; read it only if a step surprises you.

## Outcome
An admin can request a verification and get `200`, a ground admin can decline one with a reason, and a sector chief can read and change the sector's verification modes.

## Acceptance criteria
- [ ] AC1 `POST /api/v1/issues/{issueId}/request-verification` with `{"type":"existence"}` on a `reported` issue answers `200` and stores one `pending` row with a null `reason`.
- [ ] AC2 `POST /api/v1/issues/{issueId}/verify` with `"result":"cannot_verify"` and a `reason` answers `200` and stores that reason.
- [ ] AC3 `GET /api/v1/sectors/{sectorId}/settings` answers `200` for a seeded sector, and `PATCH` with any of the four verification modes stores it.
- [ ] AC4 A repository test against Testcontainers saves a pending verification with a null reason and a completed one with a reason, and flushes both to PostgreSQL.
- [ ] AC5 `python3 scripts/dev-seed.py` exits `0` on a fresh dev database, and the ground admin `sipho.dlamini@example.com` then has one pending verification.

## Visual (ui stories only)
None.

## Contract
None. The wire values stay the same: `VerificationReason` and `VerificationMode` already serialise to snake_case through `@JsonValue`.

## Background in three facts
- `issue_verifications.reason` is the PostgreSQL enum `verification_reason` (V017, V021). `sector_settings.new_issue_verification_mode` and `.fix_verification_mode` are the enum `verification_mode` (V014, V019).
- Hibernate binds a Kotlin `String` as `varchar`. PostgreSQL has no implicit cast from `varchar` to an enum, so it rejects the INSERT even when the value is null.
- Ten other enum columns already solve this with `columnDefinition = "<type>"` plus `@ColumnTransformer(write = "?::<type>")` on a `String` field. `MemberEntity.kt:76-78` (`ground_admin_status`, nullable) is the model to copy.

## Steps
Tests come first. Write steps 1 to 3 and watch each one fail for the stated reason before you change any `main` file.

1. `backend/src/test/kotlin/com/munserv/verification/repository/IssueVerificationRepositoryTest.kt` (new). `@DataJpaTest`, `@ActiveProfiles("test")`, `@AutoConfigureTestDatabase(replace = Replace.NONE)`, `@Import(TestContainersConfig::class, DefaultIssueVerificationRepository::class)`. Inject `IssueVerificationRepository` and `TestEntityManager`. Use the Flyway-seeded issue `550e8400-e29b-41d4-a716-446655440103` (state `reported`) and the seeded member `550e8400-e29b-41d4-a716-446655440010` as `verifiedBy`. Every case calls `entityManager.flush()` and `entityManager.clear()` after `save`, then reads back with `findById`. Without the flush the INSERT never reaches PostgreSQL, and the test passes on the broken code.
   - `` `should persist a pending verification when reason is null` ``: save `IssueVerification.createExistenceVerification(issueId)`. Expect `reason` null and `status` `PENDING`. Fails today with `column "reason" is of type verification_reason but expression is of type character varying`.
   - `` `should persist a completed verification when reason is set` ``: save a pending one, flush, then save `pending.complete(verifiedBy = john, outcome = VerificationOutcome.CANNOT_VERIFY, reason = VerificationReason.BUSY)`. Flush, clear and read back. Expect `reason` `BUSY` and `status` `COMPLETED`.
   - `` `should round-trip every reason when completed` ``: `@ParameterizedTest` over `VerificationReason.entries`. This proves every Kotlin value matches a database label.
2. `backend/src/test/kotlin/com/munserv/sectors/repository/SectorSettingsRepositoryTest.kt` (new). Same annotations, importing `JpaSectorSettingsRepository::class`. Use the seeded sector `550e8400-e29b-41d4-a716-446655440001`; V019 gives it a settings row with `all_notified` in both columns.
   - `` `should read seeded settings when modes are stored as snake_case labels` ``: `findBySectorId` returns `ALL_NOTIFIED` for both modes. Fails today with `No enum constant com.munserv.shared.enums.VerificationMode.all_notified`.
   - `` `should persist every verification mode when saved` ``: `@ParameterizedTest` over `VerificationMode.entries`. Read the seeded row, apply `withNewIssueVerificationMode(mode, now)` and `withFixVerificationMode(mode, now)`, save, flush, clear, read back. Expect `mode` in both fields.
3. `backend/src/test/kotlin/com/munserv/verification/api/VerificationFlowIntegrationTest.kt` (new). `@SpringBootTest`, `@AutoConfigureMockMvc`, `@ActiveProfiles("test")`, `@Import(TestContainersConfig::class)`. No `@MockkBean`: the point is the path from controller to PostgreSQL. Do **not** annotate the class `@Transactional`. The service transaction must commit, so PostgreSQL sees the INSERT. Inject `JdbcTemplate` and `JwtService`.
   - `@BeforeEach`: make the seeded member `…0010` an active ground admin: `UPDATE members SET is_ground_admin = true, ground_admin_status = 'active' WHERE id = ?`.
   - `@AfterEach`: `DELETE FROM messages WHERE recipient_id = ?` for `…0010`, `DELETE FROM issue_verifications WHERE issue_id = ?` for `…0103`, and reset the member to `is_ground_admin = false, ground_admin_status = NULL`. The Testcontainers database is shared across test classes, so leave nothing behind.
   - Tokens: `jwtService.generateAccessToken(MemberId(<admin …0020>), "admin")` for the admin, and `generateAccessToken(MemberId(<…0010>), "member")` for the ground admin.
   - `` `POST request-verification should return 200 when the issue is reported` ``: as the admin, post `{"type":"existence"}` to `/api/v1/issues/550e8400-e29b-41d4-a716-446655440103/request-verification`. Expect `200`, `$.status` `pending`, and no non-null `$.reason`. Then expect one `issue_verifications` row for the issue with `reason IS NULL`, and one `messages` row of type `verify_new_issue` for `…0010`. Fails today with `500`.
   - `` `POST verify should return 200 and store the reason when the ground admin cannot verify` ``: request as above. Then post `{"verificationId":"<id from the response>","result":"cannot_verify","reason":"busy"}` to `/api/v1/issues/…0103/verify` as `…0010`. Expect `200`. Then `GET /api/v1/issues/…0103/verifications` shows `reason` `busy`.
4. `backend/src/main/kotlin/com/munserv/verification/repository/IssueVerificationEntity.kt:36-37`: replace the `reason` mapping with `@Column(name = "reason", columnDefinition = "verification_reason")` and `@ColumnTransformer(write = "?::verification_reason")`. Remove `length = 50`. Import `org.hibernate.annotations.ColumnTransformer`. The field stays `String?`. `toDomain` and `fromDomain` already convert through `VerificationReason.fromString` and `toApiString`. Tests: step 1 and step 3 go green.
5. `backend/src/main/kotlin/com/munserv/sectors/repository/SectorSettingsEntity.kt:27-32`: drop both `@Enumerated(EnumType.STRING)` annotations and their imports. Change both fields to `String` with `columnDefinition = "verification_mode"` and `@ColumnTransformer(write = "?::verification_mode")`. In `fromDomain`, write `settings.newIssueVerificationMode.toApiString()` and the same for `fixVerificationMode`. In `toDomain`, read with `VerificationMode.fromString(...)`. A cast alone is not enough here: `EnumType.STRING` writes the constant name `ALL_NOTIFIED`, which is not a label of `verification_mode`. Test: step 2 goes green, and `SectorSettingsControllerTest` and `SectorSettingsServiceTest` stay green.
6. Run `./gradlew ktlintFormat`, then the Done-when block.

## Do not
- Do not add a Flyway migration or change any enum type. The schema is correct; the entities are wrong.
- Do not switch to `@JdbcTypeCode(SqlTypes.NAMED_ENUM)` or add `stringtype=unspecified` to the JDBC URL. Both change behaviour for every other column and break the one pattern the codebase uses.
- Do not touch `JpaIssueRepository.findByState` (`JpaIssueRepository.kt:24`) or `JpaAuditLogRepository.findByPodIdAndAction` (`JpaAuditLogRepository.kt:19`). Both compare an enum column to a `varchar` and would fail if called, but nothing calls them. They belong to a separate issue.
- Do not change `VerificationService`, `VerificationController`, the DTOs, `scripts/dev-seed.py`, web or mobile.
- Do not rename `IssueVerificationEntity.outcome` (column `result`) or touch `verification_type`, `result` or `status`. Those columns are `VARCHAR` with CHECK constraints, and their `String` mapping is correct.

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end, not after every step
cd backend && ./gradlew ktlintCheck test
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a summary of changes. If you cannot finish, set `status: blocked` and end your message with `BLOCKED: <reason>`.

## Eyeball
Rules for every check: `url` is the complete address a tester can paste into a browser (scheme, host, port, path, and for Swagger the deep link `http://localhost:8080/swagger-ui/index.html#/<Tag>/<operationId>`). Steps that go through Swagger name the deep link of each operation, the exact request body, and say where the token goes (Authorize button). Never write a bare path like `/api/v1/pod/logo`. The tester reaches the laptop through a terminal only (root `CLAUDE.md`, "When a person must act"); the console rewrites `localhost` in `url` to the LAN host, so browser links stay as they are. A step that needs the laptop itself (a mail in Mailpit, a log line, a database row) is an exact command to paste into that terminal, never "open http://localhost:8026" or a desktop app.

Manual acceptance checks a human runs in `scripts/eyeball.py` before merge. The planner writes 2 to
6 checks that together cover every acceptance criterion above; the implementer corrects `url` (and
`as`, if the route or account changed) if it differs from what shipped; the reviewer verifies the
checks still cover every AC. `as` is an account key from `scripts/eyeball/accounts.yaml`, or `none`.
`services` lists what must be running, from `db`, `backend`, `web`, `mobile`, `mock-api`,
`storybook`. `url` is a full local URL (`http://localhost:3000/...`), or a mobile screen name
(`MembersListScreen`) for `platform: mobile` stories.

The backend must run with `SPRING_PROFILES_ACTIVE=local,mailpit`; `scripts/eyeball-up.sh <pr>` starts it that way through the console. `db` brings up Mailpit with PostgreSQL. Run E1 to E3 in order, in the laptop terminal, from the checkout that `scripts/eyeball-up.sh` prepared (`~/Work/munserv-console`). E2 and E3 use `jq`, which is installed.

```yaml
- id: E1
  title: The dev seed finishes and leaves a pending verification
  as: sector_admin
  services: [db, backend]
  url: http://localhost:8080/swagger-ui/index.html#/Verifications/requestVerification
  steps:
    - |
      # Run the dev seed against the backend and print its exit code
      cd ~/Work/munserv-console && python3 scripts/dev-seed.py; echo "exit=$?"
  expect: >
    The last lines are either "verification: requested on issue <uuid>, unassigned" or
    "verification: 1 already pending for the ground admin", followed by exit=0. Before the fix the
    script printed "a 500 here is issue #166" and exit=1.
- id: E2
  title: The ground admin sees exactly one pending verification
  as: ground_admin
  services: [db, backend]
  url: http://localhost:8080/swagger-ui/index.html#/Verifications/getPendingVerifications
  steps:
    - |
      # Log in as the ground admin Sipho Dlamini (password from scripts/console/accounts.yaml)
      GA=$(curl -s -X POST http://localhost:8080/api/v1/auth/member/login -H 'Content-Type: application/json' -d '{"email":"sipho.dlamini@example.com","password":"Ground456"}' | jq -r .accessToken)
      # List Sipho's pending verifications: the count, then the first item
      curl -s http://localhost:8080/api/v1/members/me/pending-verifications -H "Authorization: Bearer $GA" | jq '.items | length, .[0]'
  expect: >
    The first line is 1. The item has verificationType "existence", an issueId, and an issueType.
    Keep the terminal open for E3; it reuses $GA.
- id: E3
  title: The ground admin declines with a reason and the reason is stored
  as: ground_admin
  services: [db, backend]
  url: http://localhost:8080/swagger-ui/index.html#/Verifications/submitVerification
  steps:
    - |
      # Read the pending verification's ids from Sipho's list
      V=$(curl -s http://localhost:8080/api/v1/members/me/pending-verifications -H "Authorization: Bearer $GA" | jq -r '.items[0].verificationId')
      I=$(curl -s http://localhost:8080/api/v1/members/me/pending-verifications -H "Authorization: Bearer $GA" | jq -r '.items[0].issueId')
      # Decline it as "busy" and print the HTTP status
      curl -s -o /dev/null -w '%{http_code}\n' -X POST "http://localhost:8080/api/v1/issues/$I/verify" -H "Authorization: Bearer $GA" -H 'Content-Type: application/json' -d "{\"verificationId\":\"$V\",\"result\":\"cannot_verify\",\"reason\":\"busy\"}"
      # Read the issue's verification history back from the database through the API
      curl -s "http://localhost:8080/api/v1/issues/$I/verifications" -H "Authorization: Bearer $GA" | jq --arg v "$V" '.items[] | select(.id == $v) | {status, result, reason}'
      # Put a fresh pending verification back for later checks
      python3 scripts/dev-seed.py; echo "exit=$?"
  expect: >
    The decline prints 200. The history shows {"status":"completed","result":"cannot_verify","reason":"busy"}.
    The dev seed reruns with exit=0 and requests a new verification.
- id: E4
  title: The sector chief reads and changes verification modes
  as: sector_chief
  services: [db, backend, web]
  url: http://localhost:3000/settings/sector
  steps:
    - Log in as chief@munserv.local / chief123 and open Sector Settings from the sidebar.
    - Set "New Issue Verification Mode" to "Admin assigns Ground Admin" and press Save Changes.
    - Reload the page.
    - Set "New Issue Verification Mode" back to "Notify all Ground Admins" and press Save Changes.
  expect: >
    The page loads with both modes on "Notify all Ground Admins". After the reload "New Issue
    Verification Mode" still shows "Admin assigns Ground Admin". Before the fix the page showed a
    load error, because the backend answered 500.
```
