---
issue: 327
story: FIX327
title: "Dashboard avgResolutionDays rounds an exact .x5 mean half up"
platform: backend
status: completed
depends_on: [55]
touches:
  - backend/src/main/kotlin/com/munserv/admin
ui: false
user_facing: true
eyeball_exempt: [AC2]
design_canvas: ""
design_artboards: []
design_approved: false
created_by: feature-planner
created_at: "2026-11-20"
files_changed: [backend/src/main/kotlin/com/munserv/admin/domain/ResolutionTime.kt, backend/src/test/kotlin/com/munserv/admin/domain/ResolutionTimeTest.kt]
tests_added: [ResolutionTimeTest]
---

# FIX327 · Dashboard avgResolutionDays rounds an exact .x5 mean half up (Backend)

Read `domain/README.md` for every term used below. This handoff is complete on its own; do not read the feature spec or other platforms' handoffs unless a step says so.

## Outcome
`stats.avgResolutionDays` on `GET /api/v1/admin/dashboard` rounds a mean that ends in exactly 5 at the second decimal up, as half-up rounding promises: 0.15 days shows `0.2`, not `0.1`.

## Acceptance criteria
- [ ] AC1: a mean of exactly 0.15 days returns `0.2`, and a mean of 0.25 days returns `0.3`.
- [ ] AC2: a unit test in `ResolutionTimeTest` covers the 0.15-day case, and it fails on the current code.

## Visual (ui stories only)
None.

## Contract
None. `StatsResponse.avgResolutionDays` in `specs/contracts/openapi.json` keeps its shape and description:
```json
"avgResolutionDays" : { "description" : "Mean days from reported to fixed over issues fixed in the last 90 days, one decimal; absent when none was fixed", "format" : "double", "type" : [ "null", "number" ] }
```
Only the rounding of the value changes.

## Steps
Write the tests first and watch the 0.15 case fail, then fix the code.

1. `backend/src/test/kotlin/com/munserv/admin/domain/ResolutionTimeTest.kt`: add two tests next to `should round half up to one decimal place`, each with one issue built like that test (reported at `base`, fixed later):
   - `should round an exact half up when the mean is 0.15 days`: fixed at `base.plus(216, ChronoUnit.MINUTES)` (3 h 36 min); expect `0.2`. Run `cd backend && ./gradlew test --tests 'com.munserv.admin.domain.ResolutionTimeTest'` and confirm this test fails with `0.1` before step 2.
   - `should round an exact half up when the mean is 0.25 days`: fixed at `base.plus(6, ChronoUnit.HOURS)`; expect `0.3`. 0.25 is exact in binary, so this one passes before and after; it guards the half-up rule.
2. `backend/src/main/kotlin/com/munserv/admin/domain/ResolutionTime.kt`: in `averageDays`, replace `BigDecimal(days.average())` with `BigDecimal.valueOf(days.average())`. Keep `.setScale(DECIMAL_PLACES, RoundingMode.HALF_UP).toDouble()`. `BigDecimal(Double)` keeps the exact binary value (0.1499999…), while `valueOf` goes through the shortest decimal string (`"0.15"`). Test: both tests from step 1 and every existing `ResolutionTimeTest` case pass.

## Do not
- Do not use multi-issue fixtures for the new tests: averaging two doubles can add a binary error and hide the case under test.
- Do not switch to `Math.round`, `String.format` or `RoundingMode.HALF_EVEN`, and do not change `MILLIS_PER_DAY` or the millisecond duration.
- Do not touch `DashboardService`, the API layer, `specs/contracts/openapi.json`, `web/` or `mobile/`.

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end, not after every step
cd backend && ./gradlew ktlintCheck test
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a summary of changes. If you cannot finish, set `status: blocked` and end your message with `BLOCKED: <reason>`.

## Eyeball

```yaml
- id: E1
  title: A mean of 0.15 days rounds up to 0.2
  as: none
  services: []
  url: http://localhost:8080/swagger-ui/index.html#/Admin/getAdminDashboard
  steps:
    - "`cd backend && ./gradlew test --tests 'com.munserv.admin.domain.ResolutionTimeTest'`"
    - Read the result of the test run.
  expect: The run ends with BUILD SUCCESSFUL, including the 0.15-day and 0.25-day rounding tests.
  covers: [AC1]
- id: E2
  title: The sector dashboard still answers with its stats
  as: sector_admin
  auto: true
  services: [db, backend]
  url: http://localhost:8080/swagger-ui/index.html#/Admin/getAdminDashboard
  probe:
    method: GET
    path: /api/v1/admin/dashboard?sectorId=550e8400-e29b-41d4-a716-446655440001
    expect_status: 200
    expect_body: stats
  steps:
    - Open http://localhost:8080/swagger-ui/index.html#/Authentication/adminLogin and press Try it out.
    - 'Send {"email": "admin@ward42.example.com", "password": "admin123"} and copy the accessToken.'
    - Press Authorize, paste the token, then press Authorize again.
    - Open getAdminDashboard, enter sector 550e8400-e29b-41d4-a716-446655440001, then press Execute.
  expect: The answer is 200 with a stats block, and any average resolution time has one decimal.
  covers: [AC1]
```
