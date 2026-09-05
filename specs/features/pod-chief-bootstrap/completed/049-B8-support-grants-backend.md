---
issue: 49
story: B8
title: "Temporary super user grant tracking"
platform: backend
status: completed
depends_on: [48]        # B7 audit logging (AuditService, audit_logs, V034) must be merged
touches: [pod-chief-bootstrap]
created_by: feature-planner
created_at: "2026-09-05"
files_changed:
  - backend/src/main/resources/db/migration/V035__create_support_grants.sql
  - backend/src/main/kotlin/com/munserv/support/domain/SupportGrantStatus.kt
  - backend/src/main/kotlin/com/munserv/support/domain/SupportGrantId.kt
  - backend/src/main/kotlin/com/munserv/support/domain/SupportGrant.kt
  - backend/src/main/kotlin/com/munserv/support/repository/SupportGrantEntity.kt
  - backend/src/main/kotlin/com/munserv/support/repository/SupportGrantRepository.kt
  - backend/src/main/kotlin/com/munserv/support/repository/JpaSupportGrantRepository.kt
  - backend/src/main/kotlin/com/munserv/support/service/SupportAccessResult.kt
  - backend/src/main/kotlin/com/munserv/support/service/SupportAccessService.kt
  - backend/src/main/kotlin/com/munserv/support/service/SupportGrantExpiryJob.kt
  - backend/src/main/kotlin/com/munserv/support/api/SupportAccessDto.kt
  - backend/src/main/kotlin/com/munserv/support/api/SupportAccessController.kt
  - backend/src/main/kotlin/com/munserv/support/api/SupportGrantActivityFilter.kt
  - backend/src/main/kotlin/com/munserv/audit/service/AuditService.kt
  - backend/src/main/kotlin/com/munserv/shared/config/AppConfig.kt
  - backend/src/main/kotlin/com/munserv/shared/config/SecurityConfig.kt
  - domain/language.yaml
  - specs/requirements/backend.md
tests_added:
  - backend/src/test/kotlin/com/munserv/support/domain/SupportGrantStatusTest.kt
  - backend/src/test/kotlin/com/munserv/support/domain/SupportGrantTest.kt
  - backend/src/test/kotlin/com/munserv/support/repository/JpaSupportGrantRepositoryTest.kt
  - backend/src/test/kotlin/com/munserv/support/service/SupportAccessServiceTest.kt
  - backend/src/test/kotlin/com/munserv/support/service/SupportGrantExpiryJobTest.kt
  - backend/src/test/kotlin/com/munserv/support/api/SupportAccessControllerTest.kt
  - backend/src/test/kotlin/com/munserv/support/api/SupportGrantActivityFilterTest.kt
  - backend/src/test/kotlin/com/munserv/audit/service/AuditServiceTest.kt
---

# B8 · Temporary super user grant tracking (Backend)

Read `domain/support-grant.md`, `domain/admin-role.md` and `domain/audit.md` for every term used below.
This handoff is complete on its own; do not read other stories' handoffs.

## Outcome
A pod chief can grant, list and revoke temporary super user access to their pod through the API, and
the system expires a grant automatically after an hour without activity.

## Acceptance criteria
- [ ] Store grants with: role, purpose, granted_by, granted_at, expires_at, last_activity
- [ ] Auto-expire logic: revoke after logout OR 1 hour of inactivity
- [ ] Activity tracking updates last_activity timestamp
- [ ] API to create, query, and revoke grants
- [ ] Scheduled job for automatic expiry cleanup

## Contract
`specs/contracts/api.md` § Support Access (already written) and `specs/contracts/types.md` § SupportGrant.
All three endpoints require an authenticated admin whose role is `pod_chief`.

- `GET /api/v1/support-access/grants?status={active|expired|revoked}` → `200 { "items": SupportGrant[], "total": number }`
- `POST /api/v1/support-access/grants` ← `{ "grantedRole": "pod_admin", "purpose": "…" }` → `201 SupportGrant`;
  `400 { messages: string[] }`, `403`, `409 { code: "active_grant_exists", message }`
- `DELETE /api/v1/support-access/grants/{id}` → `204`; `403`, `404`, `409 { code: "grant_not_active", message }`
- `SupportGrant` = `{ id, grantedRole, purpose, status, grantedBy, grantedByName, grantedAt, expiresAt, lastActivity, revokedAt, expiredAt }`,
  timestamps ISO-8601 strings, `status` one of `active|expired|revoked`, nullable fields emitted as `null`.

Redis is not part of this project. Everything below is PostgreSQL. The issue's "consider Redis" note is obsolete.

## Steps
Work in `backend/`. Kotlin paths below are relative to `backend/src/main/kotlin/com/munserv/`, test paths to
`backend/src/test/kotlin/com/munserv/`. New feature package `com.munserv.support` with `api/`, `domain/`, `service/`,
`repository/`, mirroring `com.munserv.bootstrap`. Like `BootstrapService`, this module injects `AdminRepository`
directly — there is no `AdminService` in this codebase; do not invent one. The story is large for one pass:
steps 1-10 (persistence, service, expiry job) are self-contained and can be committed before steps 11-16 (API,
activity filter, docs); run the gate commands after each half.

1. `src/main/resources/db/migration/V035__create_support_grants.sql`: create `support_grants` — `id UUID PK`,
   `pod_id UUID NOT NULL REFERENCES pods(id)`, `granted_role VARCHAR(50) NOT NULL`, `purpose TEXT NOT NULL`,
   `granted_by UUID NOT NULL REFERENCES admins(id)`, `granted_at`/`expires_at TIMESTAMPTZ NOT NULL`,
   `last_activity`/`revoked_at`/`expired_at TIMESTAMPTZ`, `status VARCHAR(20) NOT NULL DEFAULT 'active'`,
   `revoked_by UUID REFERENCES admins(id)`, `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`. Indexes:
   `idx_support_grants_pod_status(pod_id, status)`, `idx_support_grants_expires(expires_at) WHERE status = 'active'`,
   unique `uq_support_grants_one_active_per_pod(pod_id) WHERE status = 'active'`. `status` is a `VARCHAR`, not a
   Postgres enum — do not add a type. Proven by step 6's test running Flyway in Testcontainers.
2. `support/domain/SupportGrantStatus.kt`: enum `ACTIVE, EXPIRED, REVOKED` with `toDbValue() = name.lowercase()`,
   `fromDbValue`, `allowedTransitions` (`ACTIVE → {EXPIRED, REVOKED}`, the other two `emptySet()`) and
   `canTransitionTo`. Test: `support/domain/SupportGrantStatusTest.kt` `should reject transition when status is terminal`.
3. `support/domain/SupportGrantId.kt` + `support/domain/SupportGrant.kt`: `@JvmInline value class SupportGrantId(val value: UUID)`,
   and `data class SupportGrant(id, podId, grantedRole: AdminRole, purpose, grantedBy: AdminId, grantedAt, expiresAt,
   lastActivity: Instant?, status, revokedAt: Instant?, revokedBy: AdminId?, expiredAt: Instant?)`. Behaviour:
   `companion object { val INACTIVITY_WINDOW: Duration = Duration.ofHours(1); fun create(...) }` with
   `expiresAt = grantedAt + INACTIVITY_WINDOW`; `isActiveAt(now)`; `withActivity(now)` (`lastActivity = now`,
   `expiresAt = now + INACTIVITY_WINDOW`); `revoked(now, by: AdminId?)`; `expired(now)`. No JPA or Spring annotations.
   Test: `support/domain/SupportGrantTest.kt` `should slide expiry one hour forward when activity is recorded`.
4. `support/repository/SupportGrantEntity.kt`: JPA entity for `support_grants` with `toDomain()`/`fromDomain()`,
   following `audit/repository/AuditLogEntity.kt`; `status` and `granted_role` stored as their `toDbValue()` strings.
   Covered by step 6's test.
5. `support/repository/SupportGrantRepository.kt`: interface with `save`, `findById`,
   `findByPodId(podId)` (newest first), `findByPodIdAndStatus(podId, status)`, `findActiveByPodId(podId)`,
   `findExpiredActive(now)` (status `active` and `expires_at <= now`).
6. `support/repository/JpaSupportGrantRepository.kt`: Spring Data interface plus the
   `@Repository` adapter, following `JpaAuditLogRepositoryImpl`. Test:
   `support/repository/JpaSupportGrantRepositoryTest.kt`, `@DataJpaTest @Import(TestContainersConfig::class, JpaSupportGrantRepositoryImpl::class)`
   `@AutoConfigureTestDatabase(replace = NONE)`, `should return only expired active grants when findExpiredActive is called`.
7. `support/service/SupportAccessResult.kt`: `sealed interface SupportAccessResult` with
   `data class Granted(val view: SupportGrantView)`, `data class Grants(val views: List<SupportGrantView>)`,
   `data object Revoked`, `data object NotFound`, `data object ActiveGrantExists`, `data object GrantNotActive`,
   `data object NotAuthorized`, `data class ValidationError(val errors: List<String>)`. Same file:
   `data class SupportGrantView(val grant: SupportGrant, val grantedByName: String)`.
8. `support/service/SupportAccessService.kt`: `@Service`, constructor
   `(supportGrantRepository, adminRepository: AdminRepository, auditService: AuditService, clock: Clock)`.
   - `grant(actor: AdminId, role: AdminRole, purpose: String)`: load actor via `adminRepository.findById`; require
     `actor.role == AdminRole.POD_CHIEF` and a non-null `podId` else `NotAuthorized`; `ValidationError` when
     `purpose` is blank or outside 10..500 chars, or when `!AdminRole.POD_CHIEF.canManage(role)`;
     `ActiveGrantExists` when `findActiveByPodId` returns non-null; otherwise save
     `SupportGrant.create(...)` and call `auditService.logSupportAccessGranted(...)`.
   - `list(actor: AdminId, status: SupportGrantStatus?)`: same authorisation, then repository query, mapped to views.
   - `revoke(actor: AdminId, id: SupportGrantId)`: `NotFound` when absent, `NotAuthorized` when the grant's `podId`
     differs from the actor's, `GrantNotActive` when the status is terminal; else save `grant.revoked(now, actor.id)`
     and `auditService.logSupportAccessRevoked(actorEmail, AuditActorType.POD_CHIEF, …, reason = "revoked_by_pod_chief")`.
   - `revokeOnLogout(id: SupportGrantId)`: same transition with `revokedBy = null`, actor type `SYSTEM`,
     reason `"logout"`. W29 calls it from the logout flow; B8 only has to provide and test it.
   - `recordActivity(id: SupportGrantId, now: Instant): Boolean`: no-op returning `false` unless the grant exists and
     is active; throttle writes with `ACTIVITY_THROTTLE = Duration.ofSeconds(60)` (skip when `lastActivity` is newer
     than that); otherwise save `grant.withActivity(now)` and return `true`.
   - `expireStaleGrants(): Int`: for every `findExpiredActive(now)` save `grant.expired(now)` and call
     `auditService.logSupportAccessExpired(...)`; return the count.
   Test: `support/service/SupportAccessServiceTest.kt` with MockK and a fixed `Clock`, one test per branch, e.g.
   `should return ActiveGrantExists when the pod already has an active grant`,
   `should skip the write when activity is recorded twice inside the throttle window`.
9. `audit/service/AuditService.kt`: add `logSupportAccessExpired(grantId: UUID, podId: PodId)`
   writing `AuditAction.SUPPORT_ACCESS_EXPIRED` with `actorType = AuditActorType.SYSTEM`, `actorEmail = "system"`,
   `targetType = "SUPPORT_GRANT"`. Test: add `should log support access expired with SYSTEM actor` to the existing
   `audit/service/AuditServiceTest.kt`.
10. `support/service/SupportGrantExpiryJob.kt`: `@Component` with
    `@Scheduled(fixedDelayString = "\${support-access.expiry-job-interval-ms:60000}")` calling `expireStaleGrants()`.
    Add `@EnableScheduling` to the existing `shared/config/AppConfig.kt` (scheduling is not enabled anywhere yet).
    Test: `support/service/SupportGrantExpiryJobTest.kt` `should delegate to expireStaleGrants when the job runs`.
11. `support/api/SupportAccessDto.kt`: `GrantSupportAccessRequest(grantedRole, purpose)`
    with `@field:Schema`, `SupportGrantResponse`, `SupportGrantListResponse(items, total)`,
    `SupportAccessErrorResponse(code, message)`, `SupportAccessValidationErrorResponse(messages)`, and a
    `fun SupportGrantView.toResponse()` extension. Timestamps are `Instant.toString()`; `grantedRole` and `status`
    use `toDbValue()`. Covered by step 12's test.
12. `support/api/SupportAccessController.kt`: `@RestController`
    `@RequestMapping("/api/v1/support-access")` `@Tag(name = "Support Access", …)` `@SecurityRequirement(name = "bearerAuth")`
    `@RequireRole(AdminRole.POD_CHIEF)`; three thin methods that `when` over `SupportAccessResult` and map
    `Granted→201`, `Grants→200`, `Revoked→204`, `ValidationError→400`, `NotAuthorized→403`, `NotFound→404`,
    `ActiveGrantExists`/`GrantNotActive`→`409`. Read the caller with a private `getCurrentAdminId()` copied from
    `admin/api/AdminManagementController.kt` (principal is the admin UUID string); return `401` when it is null.
    Annotate every method with `@Operation` and `@ApiResponses`. Test: `support/api/SupportAccessControllerTest.kt`,
    `@WebMvcTest(SupportAccessController::class) @ActiveProfiles("test")` with `@MockkBean`, one test per status code
    (`RoleAuthorizationAspect` is not loaded in a `@WebMvcTest`, so these tests cover mapping, not the role check).
13. `support/api/SupportGrantActivityFilter.kt`: `OncePerRequestFilter` that, when the
    authentication carries authority `ROLE_SUPER_USER` and the principal string parses as a UUID, calls
    `supportAccessService.recordActivity(SupportGrantId(uuid), Instant.now(clock))` and then continues the chain
    regardless of the outcome. The grant id arrives as the JWT subject; W29 makes the support login mint that token,
    so today the lookup simply misses and the filter is a no-op. Test:
    `support/api/SupportGrantActivityFilterTest.kt` `should record activity when the principal is an active grant id`
    and `should do nothing when the principal is an ordinary admin`.
14. `shared/config/SecurityConfig.kt`: add
    `.requestMatchers("/api/v1/support-access/**").authenticated()` before the `anyRequest()` rule and register the
    filter with `.addFilterAfter(supportGrantActivityFilter, JwtAuthenticationFilter::class.java)`.
15. `domain/language.yaml`: replace the placeholder comment and empty lists in the `support-grant` concept with the
    real `kotlin:` names and `db: { tables: [support_grants] }` listed there. Do this last — the validator rejects
    names that do not exist yet. Then run `python3 scripts/validate-domain-language.py` and expect `0 errors`
    (7 pre-existing warnings tracked in #61 are fine).
16. `specs/requirements/backend.md`: set the B8 row's status to 🟢 Done.

## Do not
- Do not add Redis, a cache, or an in-memory session store; `support_grants` is the only place activity lives.
- Do not write a `SUPPORT_ACCESS_ACTIVITY` audit row per request — the audit log records grant, revoke and expiry
  only; activity lives in `last_activity`.
- Do not touch `AuthService`, `JwtService` or the login endpoints: super user login under a grant is story W29.
- Do not add a `/api/v1/support-access/login` or logout endpoint, despite the older line in `implementation-plan.md`.
- Do not let the super user call these endpoints; all three are pod chief only.
- Do not extend a grant beyond one idle hour, and do not add a caller-supplied duration field.
- Do not touch web or mobile, and do not rename anything in `audit/` or `bootstrap/`.

## Done when
```bash
# every command must exit 0 before you finish
cd backend && ./gradlew ktlintFormat && ./gradlew ktlintCheck && ./gradlew test
cd /home/ossewawiel/Work/munserv && python3 scripts/validate-domain-language.py
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a summary of changes.
If you cannot finish, set `status: blocked` and end your message with `BLOCKED: <reason>`.
