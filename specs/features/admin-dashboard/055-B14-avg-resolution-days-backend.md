---
issue: 55
story: B14
title: "Dashboard avgResolutionDays computed from issue state history"
platform: backend
status: completed
depends_on: []
touches:
  - backend/src/main/kotlin/com/munserv/admin
  - backend/src/main/kotlin/com/munserv/issues
  - specs/contracts
ui: false
user_facing: true
eyeball_exempt: [AC2, AC3]
design_canvas: ""
design_artboards: []
design_approved: false
created_by: feature-planner
created_at: "2026-11-20"
files_changed:
  - backend/src/main/kotlin/com/munserv/admin/domain/ResolutionTime.kt
  - backend/src/main/kotlin/com/munserv/admin/service/DashboardService.kt
  - backend/src/main/kotlin/com/munserv/admin/api/AdminResponse.kt
  - backend/src/main/kotlin/com/munserv/issues/service/IssueService.kt
  - backend/src/main/kotlin/com/munserv/issues/repository/IssueStateHistoryRepository.kt
  - specs/contracts/openapi.json
tests_added:
  - backend/src/test/kotlin/com/munserv/admin/domain/ResolutionTimeTest.kt
  - backend/src/test/kotlin/com/munserv/admin/service/DashboardServiceTest.kt
  - backend/src/test/kotlin/com/munserv/admin/api/AdminControllerTest.kt
  - backend/src/test/kotlin/com/munserv/issues/service/IssueServiceTest.kt
  - backend/src/test/kotlin/com/munserv/issues/repository/IssueStateHistoryRepositoryTest.kt
---

# B14 · Dashboard avgResolutionDays computed from issue state history (Backend)

Read `domain/README.md` for every term used below. This handoff is complete on its own; do not read the feature spec or other platforms' handoffs unless a step says so.

## Outcome
`GET /api/v1/admin/dashboard` returns `stats.avgResolutionDays`: the mean days from `reported` to `fixed` over the sector's issues fixed in the last 90 days, instead of always null. The window is agreed at 90 days. "No issue has been fixed" means none inside that window.

## Acceptance criteria
- [ ] AC1 avgResolutionDays computed over issues fixed in the sector (rolling window to be agreed, default 90 days)
- [ ] AC2 null only when no issue has been fixed
- [ ] AC3 unit test on the calculation, contract test on the dashboard response

## Visual (ui stories only)
None.

## Contract
No new route or field. `StatsResponse.avgResolutionDays` in `specs/contracts/openapi.json` stays:
```json
"avgResolutionDays" : { "format" : "double", "type" : [ "null", "number" ] }
```
Step 6 adds only a `description` to it. `application.yml` sets `default-property-inclusion: non_null`, so a null value is left out of the JSON. A number is days, rounded half-up to one decimal place, for example `9.0`.

## Steps
Write each test first (TDD), then the code.

1. `backend/src/main/kotlin/com/munserv/issues/repository/IssueStateHistoryRepository.kt`: add `findByIssueIdInOrderByChangedAtAsc(issueIds: Collection<UUID>)` to `IssueStateHistoryJpaRepository`. Add `findByIssueIds(issueIds: Collection<IssueId>): List<IssueStateHistoryEntry>` to the interface and to `JpaIssueStateHistoryRepository`. Test: `IssueStateHistoryRepositoryTest` new `@Nested inner class FindByIssueIds`, `should return entries of every given issue ordered by changedAt`.
2. `backend/src/main/kotlin/com/munserv/issues/service/IssueService.kt`: add `@Transactional(readOnly = true) fun getStateHistories(issueIds: Collection<IssueId>): Map<IssueId, List<IssueStateHistoryEntry>>`, grouped by `issueId`. Return `emptyMap()` with no query when `issueIds` is empty. Test: `IssueServiceTest` `should group state history by issue when ids are given` and `should not query when no ids are given`.
3. `backend/src/main/kotlin/com/munserv/admin/domain/ResolutionTime.kt` (new, pure Kotlin, no Spring): `object ResolutionTime` with `fun averageDays(histories: Map<IssueId, List<IssueStateHistoryEntry>>, windowStart: Instant): Double?`. For each issue, the start is its earliest `IssueState.Reported` entry. The end is its latest `IssueState.Fixed` entry with `changedAt >= windowStart`. Skip an issue that lacks either one, or whose end is before its start. Days are `Duration.between(start, end).toMillis() / MILLIS_PER_DAY` (a named `const`). Average them and round half-up to one decimal place with `BigDecimal.setScale(1, RoundingMode.HALF_UP)`. Return null when no issue counts. Test: `backend/src/test/kotlin/com/munserv/admin/domain/ResolutionTimeTest.kt`:
   `should return null when no issue was fixed`; `should return null when every fix is older than the window`; `should average days from reported to fixed` (2 and 4 days give `3.0`); `should use the latest fix inside the window when an issue was fixed twice`; `should round half up to one decimal place` (1 day 6 hours gives `1.3`); `should skip an issue that has no reported entry`.
4. `backend/src/main/kotlin/com/munserv/admin/service/DashboardService.kt`: inject `IssueService` and add `companion object { private const val RESOLUTION_WINDOW_DAYS = 90L }`. Get `issueService.getStateHistories(issues.map { it.id })` and pass it to `ResolutionTime.averageDays` with `windowStart = now.minus(RESOLUTION_WINDOW_DAYS, ChronoUnit.DAYS)`. Set `avgResolutionDays` from the result. Delete the `// Tracked in #55` comment. Test: `DashboardServiceTest`: build the service with a mocked `IssueService` and stub `getStateHistories` to `emptyMap()` in the existing tests. Add `should return avgResolutionDays from state history when an issue was fixed in the window`, and `should return null avgResolutionDays when no issue was fixed`.
5. `backend/src/test/kotlin/com/munserv/admin/api/AdminControllerTest.kt`, `ApiContractTests`: add `dashboard response should carry avgResolutionDays when the sector has a fixed issue`. Call the dashboard with `sectorId=550e8400-e29b-41d4-a716-446655440002` and assert `jsonPath("$.stats.avgResolutionDays") { isNumber() }`. Flyway seeds that sector's issue `...0104` as reported 10 days ago and fixed 1 day ago. Do not assert null on sector `...0001`: other test classes share the database and may fix issues there.
6. `backend/src/main/kotlin/com/munserv/admin/api/AdminResponse.kt`: on `StatsResponse.avgResolutionDays`, add `@field:Schema(description = "Mean days from reported to fixed over issues fixed in the last 90 days, one decimal; absent when none was fixed", nullable = true)`. Then regenerate the contract: `cd backend && ./gradlew test --tests '*OpenApiContractTest*'`. Review and commit `specs/contracts/openapi.json`, then run the command again.

## Do not
- Do not edit `specs/contracts/openapi.json` by hand, and do not rename `avgResolutionDays` or change its wire spelling.
- Do not touch `web/`, `mobile/` or `infrastructure/mock-api`. The web type `avgResolutionDays: number` is a separate change.
- Do not move `DashboardService` off `IssueRepository`. That is outside this story; only the new history read goes through `IssueService`.
- Do not call `IssueService.getStateHistory` once per issue (N+1); use the batch method from step 2. Do not compute from `Issue.updatedAt` or the issue's current state. A fixed-then-closed issue still counts, and only history knows when the fix happened.
- Do not add a configuration property or a migration for the window. It is the named constant from step 4. Do not change `PodDashboardService` or the pod, ward or sector dashboards.

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end, not after every step
cd backend && ./gradlew ktlintCheck test
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a summary of changes. If you cannot finish, set `status: blocked` and end your message with `BLOCKED: <reason>`.

## Eyeball

```yaml
- id: E1
  title: Fixing an issue gives the sector an average resolution time
  as: sector_admin
  auto: true
  services: [db, backend]
  url: http://localhost:8080/swagger-ui/index.html#/Admin/getAdminDashboard
  probe:
    - method: GET
      path: /api/v1/issues?sectorId=550e8400-e29b-41d4-a716-446655440001&state=reported&limit=1
      expect_status: 200
      save: {issue: "items.0.id"}
    - {method: PATCH, path: "/api/v1/issues/{issue}/state", body: {state: confirmed}, expect_status: 200}
    - {method: PATCH, path: "/api/v1/issues/{issue}/state", body: {state: in_progress}, expect_status: 200}
    - {method: PATCH, path: "/api/v1/issues/{issue}/state", body: {state: fixed}, expect_status: 200}
    - method: GET
      path: /api/v1/admin/dashboard?sectorId=550e8400-e29b-41d4-a716-446655440001
      expect_status: 200
      expect_body: avgResolutionDays
  steps:
    - Open http://localhost:8080/swagger-ui/index.html#/Authentication/adminLogin and press Try it out.
    - 'Send {"email": "admin@ward42.example.com", "password": "admin123"} and copy the accessToken.'
    - Press Authorize, paste the token, then press Authorize again.
    - Open http://localhost:8080/swagger-ui/index.html#/Issues/listIssues with sectorId 550e8400-e29b-41d4-a716-446655440001 and state reported.
    - 'Open updateIssueState and send {"state": "confirmed"} for one issue from that list.'
    - Move the same issue to in_progress, then to fixed.
    - Open getAdminDashboard and press Try it out.
    - Enter sector 550e8400-e29b-41d4-a716-446655440001, then press Execute.
  expect: The stats block holds avgResolutionDays with a number of days.
  covers: [AC1]
- id: E2
  title: The dashboard shows the average resolution time
  as: sector_admin
  services: [db, backend, web]
  url: http://localhost:3000/
  steps:
    - Run check E1 first.
    - Log in as the sector admin.
    - Open the Dashboard.
    - Read the Avg Resolution card.
  expect: The Avg Resolution card shows a number of days, not a blank.
  covers: [AC1]
```
