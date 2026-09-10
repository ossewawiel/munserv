---
issue: 152
story: B12
title: "Sorting, search and filters on GET /pod/administrators"
platform: backend
status: completed
depends_on: []
touches:
  - backend/src/main/kotlin/com/munserv/admin
  - backend/src/main/kotlin/com/munserv/pod
  - specs/contracts
ui: false
design_canvas: ""
design_artboards: []
design_approved: false
created_by: feature-planner
created_at: "2026-09-10"
files_changed:
  - backend/src/main/kotlin/com/munserv/admin/domain/AdminListQuery.kt
  - backend/src/main/kotlin/com/munserv/admin/domain/Admin.kt
  - backend/src/main/kotlin/com/munserv/admin/repository/JpaAdminRepository.kt
  - backend/src/main/kotlin/com/munserv/admin/service/AdminManagementService.kt
  - backend/src/main/kotlin/com/munserv/pod/api/PodAdministratorQueryParams.kt
  - backend/src/main/kotlin/com/munserv/pod/api/PodAdministratorController.kt
tests_added:
  - backend/src/test/kotlin/com/munserv/admin/domain/AdminListQueryTest.kt
  - backend/src/test/kotlin/com/munserv/admin/domain/AdminRoleTest.kt
  - backend/src/test/kotlin/com/munserv/admin/repository/JpaAdminRepositoryTest.kt
  - backend/src/test/kotlin/com/munserv/admin/service/AdminManagementServiceTest.kt
  - backend/src/test/kotlin/com/munserv/pod/api/PodAdministratorQueryParamsTest.kt
  - backend/src/test/kotlin/com/munserv/pod/api/PodAdministratorControllerTest.kt
---

# B12 · Pod administrator query: sort, search, filters (Backend)

Read `domain/README.md` and `domain/admin-role.md` for every term used below. This handoff is
complete on its own; do not read the feature spec or other stories' handoffs.

## Outcome
`GET /api/v1/pod/administrators` answers a sorted, searched and filtered list, so the web Pod
Administrators page (W21b, #149) can drive its sort labels, search field and filter drawer from the
server instead of rendering them inert.

## Acceptance criteria
- [ ] `sort=<column>:<asc|desc>` orders the list by `email`, `displayName`, `role` or `createdAt`; no `sort` means `createdAt` ascending
- [ ] `q` returns only administrators whose email or display name contains the term, ignoring case
- [ ] `role` (repeatable) returns only administrators with one of those roles
- [ ] `wardId` returns only administrators assigned to that ward
- [ ] The list includes ward- and sector-level administrators of the pod, not only pod-level ones
- [ ] An unknown sort column or direction, an unknown role or a malformed `wardId` answers `400 { code, message }` and never a 500
- [ ] Documented in `specs/contracts/api.md`; ktlint and tests pass

## Visual
None.

## Contract
`specs/contracts/api.md` § Pod Administrators is already written for this story — build exactly that.
The envelope does not change: `AdminListResponse { items: AdminResponse[], total: Int }`,
unpaginated, `total` counted **after** filtering (so `total == items.size`). Quoted query table:

| Param | Values | Default |
|---|---|---|
| `sort` | `<column>:<direction>`; column is `email`, `displayName`, `role` or `createdAt`, direction is `asc` or `desc` | `createdAt:asc` |
| `q` | case-insensitive substring matched against `email` **or** `displayName`; blank or whitespace is ignored | none |
| `role` | an `admin_role` wire value, repeatable (`?role=ward_chief&role=sector_admin`) | none |
| `wardId` | UUID; keeps only admins assigned to that ward | none |

Errors: `400 { code: "invalid_sort" | "invalid_role" | "invalid_ward_id", message: string }`.
Sort columns are the **response field names** (camelCase), because they name JSON fields; `role`
filter values stay snake_case `admin_role` wire values.

## Steps

1. `backend/src/main/kotlin/com/munserv/admin/domain/AdminListQuery.kt` (new): the query as pure
   domain, no Spring.
   ```kotlin
   enum class AdminSortColumn(val wireValue: String) { EMAIL("email"), DISPLAY_NAME("displayName"), ROLE("role"), CREATED_AT("createdAt") }
   enum class SortDirection(val wireValue: String) { ASC("asc"), DESC("desc") }
   data class AdminSort(val column: AdminSortColumn, val direction: SortDirection)
   data class AdminListQuery(val search: String? = null, val roles: Set<AdminRole> = emptySet(), val wardId: WardId? = null, val sort: AdminSort = DEFAULT_SORT)
   ```
   with `companion object { val DEFAULT_SORT = AdminSort(AdminSortColumn.CREATED_AT, SortDirection.ASC); val DEFAULT = AdminListQuery() }`,
   `fromWireValue(value: String): X?` companions on both enums, and
   `fun AdminListQuery.applyTo(admins: List<Admin>): List<Admin>` that filters (search over
   `email` and `displayName` with `contains(term, ignoreCase = true)`; `roles` empty means all;
   `wardId` null means all) then sorts. `EMAIL` and `DISPLAY_NAME` compare with
   `String.compareTo(other, ignoreCase = true)`; `ROLE` compares the enum (declaration order is the
   role hierarchy); `CREATED_AT` compares the `Instant`. `DESC` reverses. Blank `search` is treated
   as absent. Do not mutate the input list. Test:
   `backend/src/test/kotlin/com/munserv/admin/domain/AdminListQueryTest.kt` (new, plain JUnit +
   Kotest, no Spring) — `should return every admin when the query is default`,
   `should sort by created date ascending by default`, `should sort by display name ignoring case`,
   `should sort by role hierarchy from lowest to highest`, `should reverse the order when the direction is desc`,
   `should match the search term in the email`, `should match the search term in the display name ignoring case`,
   `should ignore a blank search term`, `should keep only the given roles`, `should keep only admins in the given ward`,
   `should combine search role and ward with and`.
2. `backend/src/main/kotlin/com/munserv/admin/domain/Admin.kt`: add
   `fun fromDbValueOrNull(value: String): AdminRole? = entries.find { it.toDbValue() == value.lowercase() }`
   to `AdminRole.companion`. Leave `fromDbValue` as it is. Test:
   `backend/src/test/kotlin/com/munserv/admin/domain/AdminRoleTest.kt` — add
   `should return null for an unknown role wire value` and `should parse every role wire value`.
3. `backend/src/main/kotlin/com/munserv/admin/repository/JpaAdminRepository.kt`: `findByPodId` must
   return the pod's whole administration, not only rows with `pod_id` set. Ward- and sector-level
   admins carry a null `pod_id` (see `V029__add_ward_references.sql` `ck_admins_role_scope` and the
   `V030` seed), so add to `SpringDataAdminRepository`:
   ```kotlin
   @Query(
       """
       SELECT a.* FROM admins a
       LEFT JOIN wards w ON w.id = a.ward_id
       LEFT JOIN sectors s ON s.id = a.sector_id
       WHERE a.deleted_at IS NULL
         AND (a.pod_id = :podId OR w.pod_id = :podId OR s.pod_id = :podId)
       """,
       nativeQuery = true,
   )
   fun findAllInPod(podId: UUID): List<AdminEntity>
   ```
   and have `JpaAdminRepository.findByPodId` call it. `wards.pod_id` and `sectors.pod_id` are both
   `NOT NULL`, so no extra null handling is needed. Test:
   `backend/src/test/kotlin/com/munserv/admin/repository/JpaAdminRepositoryTest.kt` (new) —
   `@DataJpaTest`, `@ActiveProfiles("test")`,
   `@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)`,
   `@Import(TestContainersConfig::class)`, autowire `SpringDataAdminRepository` directly (the
   `JpaAdminRepository` adapter needs a `PasswordEncoder` bean that `@DataJpaTest` does not have).
   Pod `550e8400-e29b-41d4-a716-446655440000`:
   `should return pod level admins of the pod` (contains `podchief@munserv.local`),
   `should return ward level admins whose ward belongs to the pod` (contains `wardadmin@munserv.local`),
   `should return sector level admins whose sector belongs to the pod` (contains `admin@ward42.example.com`),
   `should not return deleted admins`. Assert with `map { it.email } shouldContain ...`, never on an
   exact row count — later migrations add accounts.
4. `backend/src/main/kotlin/com/munserv/admin/service/AdminManagementService.kt`: give
   `listAdminsByPod` a third parameter `query: AdminListQuery = AdminListQuery.DEFAULT` (a default,
   so existing callers and tests keep compiling) and return
   `AdminResult.ListSuccess(query.applyTo(admins), filtered.size)` where the count is the filtered
   list's size. Leave `listAdmins` and `listAdminsByWard` alone. Test:
   `backend/src/test/kotlin/com/munserv/admin/service/AdminManagementServiceTest.kt` — add
   `should apply the query to the admins of the pod` and `should report the filtered count as total`;
   the existing scope-check cases stay green.
5. `backend/src/main/kotlin/com/munserv/pod/api/PodAdministratorQueryParams.kt` (new): parsing lives
   here, not in the controller.
   ```kotlin
   data class PodAdministratorQueryParams(val sort: String?, val q: String?, val roles: List<String>?, val wardId: String?) {
       fun toQuery(): PodAdministratorQueryResult
   }
   sealed interface PodAdministratorQueryResult {
       data class Parsed(val query: AdminListQuery) : PodAdministratorQueryResult
       data class Invalid(val code: String, val message: String) : PodAdministratorQueryResult
   }
   ```
   `sort` must be exactly `column:direction` (split on `:`, two parts); anything else, or an unknown
   column or direction, gives `Invalid("invalid_sort", "Invalid sort '<value>'. Use <column>:<asc|desc> with column one of email, displayName, role, createdAt")`.
   An unknown role gives `Invalid("invalid_role", ...)` listing the six wire values (use
   `AdminRole.fromDbValueOrNull`, never a `try`/`catch` around `fromDbValue`). A `wardId` that is not
   a UUID gives `Invalid("invalid_ward_id", ...)` — parse with `runCatching { UUID.fromString(it) }.getOrNull()`.
   Null or blank `sort`/`q`/`wardId` and an empty `roles` list mean "not set". Test:
   `backend/src/test/kotlin/com/munserv/pod/api/PodAdministratorQueryParamsTest.kt` (new, plain
   JUnit) — `should return the default query when nothing is given`,
   `should parse every sort column`, `should parse both directions`,
   `should reject a sort without a direction`, `should reject an unknown sort column`,
   `should reject an unknown direction`, `should parse repeated roles`,
   `should reject an unknown role`, `should reject a ward id that is not a uuid`,
   `should treat a blank search as absent`.
6. `backend/src/main/kotlin/com/munserv/pod/api/PodAdministratorController.kt`: add the four
   `@RequestParam(required = false)` parameters (`sort: String?`, `q: String?`,
   `role: List<String>?`, `wardId: String?`) with `@Parameter` descriptions and, for `sort` and
   `role`, `schema = Schema(allowableValues = [...])`; keep `@Operation` and `@ApiResponses` in the
   same shape and add `ApiResponse(responseCode = "400", description = "Invalid sort, role or ward id")`.
   `when` over `PodAdministratorQueryParams(sort, q, role, wardId).toQuery()`: `Invalid` returns
   `ResponseEntity.badRequest().body(ErrorResponse(code, message))`, `Parsed` passes the query to
   `adminService.listAdminsByPod(podId, actorId, query)`; the rest of the method is untouched.
   Test: `backend/src/test/kotlin/com/munserv/pod/api/PodAdministratorControllerTest.kt` — inside
   the list `@Nested` class add `should pass the parsed query to the service` (assert with a
   `slot<AdminListQuery>()` that `?sort=displayName:desc&q=khumalo&role=ward_admin&role=ward_chief&wardId=<uuid>`
   arrives as the matching `AdminListQuery`), `should return 400 for an unknown sort column`,
   `should return 400 for an unknown role`, `should return 400 for a ward id that is not a uuid`,
   and keep the existing 200 cases green (update the `every { adminService.listAdminsByPod(...) }`
   stubs to the three-argument form).

## Do not
- Do not add `page` / `limit` / `size`. The endpoint stays unpaginated and the envelope stays
  `{ items, total }`; W21b's table hides its pagination footer.
- Do not push the filtering or the ordering into SQL. Scope is the only thing the database decides
  (step 3); the pod administration is a handful of rows and the whole filtered set is returned, so
  `AdminListQuery.applyTo` is the tested authority. Pagination would change that — it is not in this
  story.
- Do not add sorting by `assignedTo`, `level`, `sectorId` or `onboardingStatus`. Four columns only;
  `assignedTo` is derived in the web layer and has nothing to sort on.
- Do not change `AdminResponse`, `AdminListResponse`, `listAdmins`, `listAdminsByWard`, or the
  create / update / delete endpoints.
- Do not throw for a bad parameter. Every rejection is an `Invalid` value mapped to 400; a 500 from
  `IllegalArgumentException` fails this story.
- Do not touch web, mobile or `web/src`.

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end, not after every step
cd backend && ./gradlew ktlintFormat && ./gradlew ktlintCheck test
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a
summary of changes. If you cannot finish, set `status: blocked` and end your message with
`BLOCKED: <reason>`.

## Eyeball
```yaml
- id: E1
  title: Pod chief sorts and searches the administrator list
  as: pod_chief
  services: [db, backend]
  url: http://localhost:8080/swagger-ui/index.html#/Authentication/adminLogin
  steps:
    - 'Open http://localhost:8080/swagger-ui/index.html#/Authentication/adminLogin, press "Try it out", send {"email": "podchief@munserv.local", "password": "podchief123"} and copy tokens.accessToken from the response.'
    - 'Press the green "Authorize" button at the top of the page, paste the token, Authorize, Close.'
    - 'Open http://localhost:8080/swagger-ui/index.html#/Pod%20Administrators/listAdministrators, press "Try it out", leave every parameter empty, Execute.'
    - 'Execute again with sort = displayName:desc, then with sort = role:asc.'
    - 'Execute again with sort empty and q = ward.'
  expect: The empty call answers 200 and lists the pod-level, ward-level and sector-level administrators (podchief@, podadmin@, wardchief@, wardadmin@, admin@ward42) oldest first by createdAt; displayName:desc reverses the names Z to A; role:asc runs sector_admin first and pod_chief last; q=ward returns only the two ward administrators and total matches the number of items.
- id: E2
  title: Role and ward filters narrow the list
  as: pod_chief
  services: [db, backend]
  url: http://localhost:8080/swagger-ui/index.html#/Pod%20Administrators/listAdministrators
  steps:
    - 'Still authorised as the pod chief, open http://localhost:8080/swagger-ui/index.html#/Pod%20Administrators/listAdministrators, press "Try it out" and Execute with role = ward_admin.'
    - 'Execute again with role = ward_admin and a second role value ward_chief (press "Add item" on the role parameter).'
    - 'Execute again with role empty and wardId = 550e8400-e29b-41d4-a716-446655440030.'
  expect: The first call returns only wardadmin@munserv.local; the two-role call returns both ward administrators; the wardId call returns the two administrators of Test Ward North and no pod-level ones.
- id: E3
  title: Bad parameters are refused, not crashed
  as: pod_chief
  services: [db, backend]
  url: http://localhost:8080/swagger-ui/index.html#/Pod%20Administrators/listAdministrators
  steps:
    - 'Still authorised as the pod chief, open http://localhost:8080/swagger-ui/index.html#/Pod%20Administrators/listAdministrators and Execute with sort = assignedTo:asc.'
    - 'Execute again with sort = displayName (no direction).'
    - 'Execute again with sort empty and role = super_user.'
    - 'Execute again with role empty and wardId = not-a-uuid.'
  expect: Each call answers 400 with a JSON body {code, message} naming what was wrong (invalid_sort, invalid_sort, invalid_role, invalid_ward_id); none answers 500.
```
