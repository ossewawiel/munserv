# API Contract

Base URL: `/api/v1`

> **Full examples**: See [MVP_Development_Guide.md §4](../MVP_Development_Guide.md) for complete JSON request/response examples.

## Auth

### POST /auth/register
Start registration with phone.

**Request:** `{ phone: string }`
**Response:** `{ otpSent: boolean, expiresIn: number }`
**Errors:** 409 Already registered | 429 Rate limited

### POST /auth/verify
Verify OTP and complete registration.

**Request:** `{ phone: string, otp: string, pin: string, name: string }`
**Response:** `{ accessToken: string, refreshToken: string, member: Member }`
**Errors:** 400 Invalid OTP | 410 OTP expired

### POST /auth/login
Login with PIN.

**Request:** `{ phone: string, pin: string }`
**Response:** `{ accessToken: string, refreshToken: string, member: Member }`
**Errors:** 401 Invalid credentials | 423 Account locked

### POST /auth/refresh
Refresh access token.

**Request:** `{ refreshToken: string }`
**Response:** `{ accessToken: string, refreshToken: string }`
**Errors:** 401 Invalid token

---

## Issues

### GET /issues
List issues with filters.

**Query:** `?sector={id}&state={state}&page={n}&size={n}`
**Response:** `{ items: Issue[], total: number, page: number }`
**Errors:** 400 Invalid query

### GET /issues/{id}
Get issue details including state history.

**Response:** `IssueDetail` (includes `stateHistory: StateHistoryEntry[]`)
**Errors:** 404 Not found

### POST /issues
Create new issue.

**Request:** `{ title: string, description?: string, typeId: string, location: GeoPoint, photos: string[] }`
**Response:** `Issue`
**Errors:** 400 Validation failed | 401 Unauthorized

### PATCH /issues/{id}/state
Update issue state (admin only).

**Request:** `{ state: IssueState, note?: string }`
**Response:** `Issue`
**Errors:** 403 Forbidden | 404 Not found

---

## Members

### GET /members/me
Get current member profile.

**Response:** `Member`
**Errors:** 401 Unauthorized

### GET /members/{id}/issues
Get issues reported by member.

**Response:** `{ items: Issue[], total: number }`
**Errors:** 404 Member not found

---

## Admin

### GET /admin/dashboard
Get dashboard statistics.

**Response:** `{ totalIssues: number, openIssues: number, resolvedThisMonth: number, activeMembers: number }`
**Errors:** 403 Forbidden

### GET /admin/members
List members (admin only).

**Query:** `?search={term}&page={n}&size={n}`
**Response:** `{ items: Member[], total: number, page: number }`
**Errors:** 403 Forbidden

---

## Sectors

### GET /sectors
List all sectors.

**Response:** `Sector[]`

### GET /sectors/{id}
Get sector details.

**Response:** `Sector`
**Errors:** 404 Not found

---

## Sector Settings

### GET /sectors/{sectorId}/settings
Get sector settings. Creates default settings if none exist.

**Response:** `SectorSettings`
**Errors:** 404 Sector not found

### PATCH /sectors/{sectorId}/settings
Partially update sector settings. Only provided fields are updated.

**Request:**
```json
{
  "newIssueVerificationMode": "ADMIN_ASSIGNS",  // optional
  "fixVerificationMode": "NEAREST_AUTO",         // optional
  "daysFixedBeforeClosed": 14,                   // optional, 1-365
  "minimumGroundAdmins": 3                       // optional, 0-100
}
```
**Response:** `SectorSettings`
**Errors:** 400 Validation failed | 404 Sector not found
