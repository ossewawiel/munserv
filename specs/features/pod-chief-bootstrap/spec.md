# Feature: pod-chief-bootstrap

**Goal:** Enable super user to bootstrap a fresh pod by creating the first Pod Chief, with automatic access revocation after Pod Chief completes onboarding. Includes temporary support access feature for ongoing maintenance.
**Platforms:** Backend, Web
**Status:** 🟢 Complete
**Milestone:** [#2 pod-chief-bootstrap](https://github.com/ossewawiel/munserv/milestone/2)

## Original Requirements

Pod Chief Bootstrap (Super User): When a fresh pod is deployed, there are no admin accounts. A 'super user' (configuration-based credentials from environment variables) can log in to create the first Pod Chief. After the Pod Chief completes onboarding (changes password, completes profile), the super user loses access. The super user credentials come from SUPER_USER_EMAIL and SUPER_USER_PASSWORD environment variables. No new database table needed for bootstrap check - access controlled by checking if Pod Chief exists AND is onboarded. Super user gets a special JWT with role 'super_user'. Pod Chief receives welcome email with temporary password. Pod Chief must change password on first login, then can optionally complete profile info (display name editable, contact/address optional), then redirects to dashboard. Rate limiting should apply to bootstrap login endpoint. All bootstrap actions should be audit logged.

Additionally, Pod Chief can grant the super user temporary access for debugging/maintenance purposes. This will also be audited. Access is revoked after logout or 1 hour of inactivity.

## Stories

### Web (9 stories)

| ID | Title | Issue | Handoff |
|----|-------|-------|---------|
| W22 | Super user login to fresh pod | [#37](https://github.com/ossewawiel/munserv/issues/37) | |
| W23 | Super user creates Pod Chief | [#38](https://github.com/ossewawiel/munserv/issues/38) | |
| W24 | Super user blocked after Pod Chief onboarded | [#39](https://github.com/ossewawiel/munserv/issues/39) | |
| W25 | Pod Chief welcome email with temp password | [#40](https://github.com/ossewawiel/munserv/issues/40) | |
| W26 | Pod Chief must change password on first login | [#41](https://github.com/ossewawiel/munserv/issues/41) | [Handoff](041-change-password-handoff.md) |
| W27 | Pod Chief completes optional profile info | [#42](https://github.com/ossewawiel/munserv/issues/42) | |
| W28 | Pod Chief grants super user temporary access | [#43](https://github.com/ossewawiel/munserv/issues/43) | [Handoff](043-W28-grant-support-access-web.md) |
| W29 | Super user uses temporary access for debugging | [#44](https://github.com/ossewawiel/munserv/issues/44) | |
| W30 | Pod Chief views/revokes super user sessions | [#45](https://github.com/ossewawiel/munserv/issues/45) | [Handoff](045-W30-support-sessions-web.md) |

### Backend (5 stories)

| ID | Title | Issue | Handoff |
|----|-------|-------|---------|
| B5 | Super user configuration via environment | [#46](https://github.com/ossewawiel/munserv/issues/46) | |
| B6 | Bootstrap eligibility check | [#47](https://github.com/ossewawiel/munserv/issues/47) | |
| B7 | Bootstrap audit logging | [#48](https://github.com/ossewawiel/munserv/issues/48) | |
| B8 | Temporary super user grant tracking | [#49](https://github.com/ossewawiel/munserv/issues/49) | [Handoff](completed/049-B8-support-grants-backend.md) |
| B9 | Super user login with a support grant | [#68](https://github.com/ossewawiel/munserv/issues/68) | [Handoff](068-B9-support-grant-login-backend.md) |

## Dependencies

- Existing Admin entity and repository
- Existing EmailService
- Existing JWT authentication infrastructure
- Existing OnboardingStatus enum

## API Endpoints Needed

### Authentication (Modified)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/v1/auth/admin/login` | Public | **Existing** - now also handles super user credentials |

**Note:** No separate bootstrap login endpoint. The existing admin login endpoint checks super user credentials first, then falls back to database admin lookup. Response includes `role: "SUPER_USER"` and `bootstrapStatus` for super user logins.

### Bootstrap Module

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/v1/bootstrap/status` | Public | Check if pod needs bootstrap |
| POST | `/api/v1/bootstrap/pod-chief` | Super User | Create Pod Chief |

### Support Access Module

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/v1/support-access/grants` | Pod Chief | List active and past grants |
| POST | `/api/v1/support-access/grants` | Pod Chief | Create temporary grant |
| DELETE | `/api/v1/support-access/grants/{id}` | Pod Chief | Revoke grant |
| GET | `/api/v1/support-access/grants/current` | Support grant | Read the caller's own grant (B9) |
| POST | `/api/v1/auth/logout` | Authenticated | Revokes a grant-scoped login, no-op otherwise (B9) |

**Note:** Super user with active grant also uses `/api/v1/auth/admin/login` - backend checks for active grant and returns the granted role (B9, #68).

## Database Changes

### New Table: `support_grants`

```sql
CREATE TABLE support_grants (
    id UUID PRIMARY KEY,
    pod_id UUID NOT NULL REFERENCES pods(id),
    granted_role VARCHAR(50) NOT NULL,
    purpose TEXT NOT NULL,
    granted_by UUID NOT NULL REFERENCES admins(id),
    granted_at TIMESTAMP WITH TIME ZONE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_activity TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    revoked_at TIMESTAMP WITH TIME ZONE,
    revoked_by UUID REFERENCES admins(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_support_grants_pod_status ON support_grants(pod_id, status);
```

### Index for Pod Chief Queries

```sql
CREATE INDEX IF NOT EXISTS idx_admins_role_pod_id
ON admins(role, pod_id) WHERE deleted_at IS NULL;
```

## Design

Support access UI (W28, W30) — design canvas, awaiting approval:
<https://claude.ai/code/artifact/e74d590c-6be1-40e5-8864-88e5e85d52c9>

Working files in `design/canvases/support-access/`, 1440x900 web frames:

| Artboard | State |
|---|---|
| `Main.dc.html` | Pod Settings, Support access section with no grants at all |
| `SupportAccessActive.dc.html` | Active grant: warning callout, Active tab, revoke action, Grant button disabled |
| `SupportGrantsHistory.dc.html` | History tab, four past grants with status badges and ended-at |
| `GrantDialog.dc.html` | Grant access dialog, default state (role select, purpose, one-hour expiry notice) |
| `GrantDialogError.dc.html` | Grant access dialog with the purpose-too-short validation error |
| `RevokeConfirm.dc.html` | ConfirmDialog (warning) over the active grant |

Components are all from `design/registry/web.md`; the canvas introduces none.
`design_approved` stays `false` in both handoffs until the pod owner signs off.

## Security Considerations

1. **Credentials**: Environment variables only, never in code/database
2. **Access revocation**: Automatic when Pod Chief onboarding completes
3. **JWT differentiation**: bootstrap gives `role: "super_user"`; a support grant login (B9) gives the granted role only, with the grant id as JWT subject
4. **Rate limiting**: Apply to bootstrap login endpoint
5. **Audit logging**: Log all bootstrap and support access actions
6. **Temporary access**: Auto-expires after logout or 1 hour inactivity

## Notes

- No mobile impact - bootstrap and support access are web-only features
- Super user cannot self-register or modify their credentials
- Pod Chief is the only role that can grant support access
- All temporary grants are time-bound and activity-tracked
