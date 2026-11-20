---
issue: 56
story: B15
title: "Ward admins: verify target sector belongs to the actor's ward"
platform: backend
status: completed
depends_on: []
touches: [backend/src/main/kotlin/com/munserv/admin, backend/src/main/kotlin/com/munserv/sectors, domain]
ui: false
user_facing: true
eyeball_exempt: [AC3]
design_canvas: ""
design_artboards: []
design_approved: false
created_by: feature-planner
created_at: "2026-11-20"
files_changed: [backend/src/main/kotlin/com/munserv/sectors/domain/Sector.kt, backend/src/main/kotlin/com/munserv/sectors/repository/SectorEntity.kt, backend/src/main/kotlin/com/munserv/admin/service/AdminManagementService.kt, backend/src/test/kotlin/com/munserv/sectors/repository/SectorRepositoryTest.kt, backend/src/test/kotlin/com/munserv/admin/service/AdminManagementServiceTest.kt, backend/src/test/kotlin/com/munserv/admin/api/AdminManagementWardScopeTest.kt, domain/ward.md, domain/admin-role.md]
tests_added: [AdminManagementServiceTest.WardScope (5), AdminManagementWardScopeTest (3), SectorRepositoryTest ward id (2)]
---

# B15 · Ward admins: verify target sector belongs to the actor's ward (Backend)

Read `domain/README.md` for every term used below, then `domain/ward.md`, `domain/sector.md` and `domain/admin-role.md`. This handoff is complete on its own.

## Outcome
A ward-level admin (`WARD_ADMIN`, `WARD_CHIEF`) who lists, views, creates, updates or deletes admins of a sector outside their ward gets 403 `cross_ward`; today the call succeeds.

## Acceptance criteria
- [ ] AC1 Sector→ward membership resolved via the sector's `wardId`
- [ ] AC2 WARD actor targeting a sector outside their ward gets `AdminResult.CrossWardOperation`
- [ ] AC3 Unit tests for in-ward, out-of-ward, and sector-without-ward cases

## Contract
No route or DTO changes; do not regenerate `specs/contracts/openapi.json`. `/api/v1/admins` (`listAdmins`, `createAdmin`) and `/api/v1/admins/{id}` (`getAdmin`, `updateAdmin`, `deleteAdmin`) already document `403` with an object body. `AdminManagementController` already maps `AdminResult.CrossWardOperation` to 403 with `{"code": "cross_ward", "message": "..."}`. A sector with no ward is outside every ward: `CrossWardOperation(actorWardId, null)`. So is a sector id that does not exist.

## Steps
1. `backend/src/main/kotlin/com/munserv/sectors/domain/Sector.kt`: add `val wardId: WardId? = null` as the last constructor property. The column `sectors.ward_id` exists since V029.
2. `backend/src/main/kotlin/com/munserv/sectors/repository/SectorEntity.kt`: map `@Column(name = "ward_id") val wardId: UUID? = null`; carry it in `toDomain()` and `fromDomain()`. Test: `backend/src/test/kotlin/com/munserv/sectors/repository/SectorRepositoryTest.kt` `should return ward id when sector belongs to a ward` (save a new sector with ward `550e8400-e29b-41d4-a716-446655440030` from V030, mark the test `@Transactional` so it rolls back) and `should return null ward id when sector has no ward` (seed sector `…0001`).
3. `backend/src/main/kotlin/com/munserv/admin/service/AdminManagementService.kt`:
   - Inject `com.munserv.sectors.service.SectorService` (constructor, before `clock`). Cross-module access goes through the service, never `SectorRepository`.
   - Add `private fun checkSectorInWard(actor: Admin, sectorId: SectorId?): AdminResult?`. When `actor.wardId` is null, return `OutOfScope`. Resolve `sectorId?.let { sectorService.findById(it) }?.wardId`; if it differs from the actor's ward, return `CrossWardOperation(actorWard, resolved)`, else null. No `!!`.
   - Call it in `checkAdminInScope` (WARD actor, SECTOR target: `target.sectorId`), in `checkViewScope` (WARD actor, `sectorId != null`) and in `checkCreationScope` (WARD actor, `command.sectorId != null`, after the existing ward check).
   - Delete the `Tracked in #56` comment on the WARD branch. Replace the two on the POD branch with one: `// A deployment holds one pod (#58), so every ward and sector here is in the actor's pod.`
   - Update the class KDoc scope list to say a sector with no ward is outside every ward.
   Test: `backend/src/test/kotlin/com/munserv/admin/service/AdminManagementServiceTest.kt`: add `sectorService = mockk()` to `setUp`, and a `@Nested inner class WardScope` with `should return success when ward admin gets sector admin in own ward`, `should return cross ward when ward admin gets sector admin in another ward`, `should return cross ward with null target when sector has no ward`, `should return cross ward when ward admin lists admins of sector in another ward`, `should return cross ward when ward admin creates admin in sector of another ward`.
4. `backend/src/test/kotlin/com/munserv/admin/api/AdminManagementWardScopeTest.kt` (new, `@SpringBootTest`, `@AutoConfigureMockMvc`, `@Import(TestContainersConfig::class)`, `@ActiveProfiles("test")`): token per `IssueAdminEndpointsAccessTest.adminToken` for the ward admin `550e8400-e29b-41d4-a716-446655440034`. Tests: `should refuse list when sector has no ward` (GET `/api/v1/admins?sectorId=…0001`, 403, `$.code` `cross_ward`); `should refuse delete and keep admin when sector is outside ward` (DELETE `/api/v1/admins/550e8400-e29b-41d4-a716-446655440020`, 403, then that admin's `deletedAt` is still null); `should list admins when sector is in actor's ward` (`@Transactional`: save sector `…0001` with `wardId = …0030`, then GET returns 200 and contains `admin@ward42.example.com`).
5. `domain/ward.md` invariant: "Ward administrators may act only on sectors inside their ward; a sector with no ward is outside every ward." `domain/admin-role.md` invariant: drop "(ward and sector scope checks tracked in #56)"; say sector scope for issue actions is tracked in #254.

## Do not
- Do not touch issue endpoints or `IssueService`; sector scope for issues is #254.
- Do not add pod-level ward or sector checks; one pod per deployment is #58.
- Do not inject `SectorRepository` into the admin module, and do not add a `WardRepository`.
- Do not add a migration or change the seed data; `ward_id` exists and dev sectors have none.
- Do not change controller messages, HTTP codes or `AdminResult` shapes.
- Do not use `!!` in new code, including tests (`requireNotNull`).

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end, not after every step
cd backend && ./gradlew ktlintCheck test
cd .. && python3 scripts/validate-domain-language.py
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a summary of changes. If you cannot finish, set `status: blocked` and end your message with `BLOCKED: <reason>`.

## Eyeball
```yaml
- id: E1
  title: Ward admin is refused for a sector outside the ward
  as: ward_admin
  auto: true
  services: [db, backend]
  url: http://localhost:8080/swagger-ui/index.html#/Admin%20Management/getAdmin
  probe:
    - {method: GET, path: "/api/v1/admins?sectorId=550e8400-e29b-41d4-a716-446655440001", expect_status: 403, expect_body: cross_ward}
    - {method: GET, path: /api/v1/admins/550e8400-e29b-41d4-a716-446655440020, expect_status: 403, expect_body: cross_ward}
  steps:
    - Open http://localhost:8080/swagger-ui/index.html#/Authentication/adminLogin and press Try it out.
    - 'Send {"email": "wardadmin@munserv.local", "password": "wardadmin123"} and copy the accessToken.'
    - Press Authorize, paste the token, then press Authorize again.
    - Open getAdmin, enter id 550e8400-e29b-41d4-a716-446655440020, then press Execute.
    - Open listAdmins, enter sector 550e8400-e29b-41d4-a716-446655440001, then press Execute.
  expect: Both answers are 403 with the code cross_ward.
  covers: [AC2]
- id: E2
  title: Ward admin can list admins once the sector joins the ward
  as: ward_admin
  services: [db, backend]
  url: http://localhost:8080/swagger-ui/index.html#/Admin%20Management/listAdmins
  steps:
    - "`psql postgresql://munserv:munserv_dev@localhost:5435/munserv_dev -c \"UPDATE sectors SET ward_id = '550e8400-e29b-41d4-a716-446655440030' WHERE id = '550e8400-e29b-41d4-a716-446655440001'\"`"
    - Still authorized as the ward admin from E1, run listAdmins for the same sector again.
    - "`psql postgresql://munserv:munserv_dev@localhost:5435/munserv_dev -c \"UPDATE sectors SET ward_id = NULL WHERE id = '550e8400-e29b-41d4-a716-446655440001'\"`"
  expect: The answer is 200 and lists admin@ward42.example.com.
  covers: [AC1]
```
