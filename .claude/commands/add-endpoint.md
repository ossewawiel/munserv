# Add API Endpoint

name: "add-endpoint"
description: "Add endpoint to API contract"
parameters:
  - name: "method"
    description: "HTTP method: GET, POST, PUT, DELETE, PATCH"
    required: true
  - name: "path"
    description: "Endpoint path (e.g., '/auth/reset-pin')"
    required: true
  - name: "description"
    description: "What this endpoint does (1 sentence)"
    required: true
  - name: "request"
    description: "Request body fields (or 'none')"
    required: false
  - name: "response"
    description: "Response body fields"
    required: true
  - name: "errors"
    description: "Error codes (pipe-separated)"
    required: false

---

## Task

Add endpoint `{{method}} {{path}}` to `specs/contracts/api.md`.

## Context

Read first:
1. `specs/contracts/api.md` - Current API contract
2. `specs/contracts/types.md` - Shared data types

## Process

### Step 1: Find Section

Determine which section the endpoint belongs to based on path:
- `/auth/*` → Auth section
- `/issues/*` → Issues section
- `/members/*` → Members section
- `/admin/*` → Admin section
- `/sectors/*` → Sectors section

### Step 2: Format Endpoint

Use OpenAPI-lite format:

```markdown
### {{method}} {{path}}
{{description}}

**Request:** `{ {{request}} }`
**Response:** `{ {{response}} }`
**Errors:** {{errors}}
```

### Step 3: Add to Contract

Insert endpoint in appropriate section of `specs/contracts/api.md`.

### Step 4: Update Types

If new types are needed, prompt to run `/add-type`.

## Output Format (OpenAPI-lite)

```markdown
### POST /auth/reset-pin
Request OTP to reset PIN.

**Request:** `{ phone: string }`
**Response:** `{ otpSent: boolean, expiresIn: number }`
**Errors:** 404 Not Found | 429 Rate Limited
```

For query parameters:
```markdown
### GET /issues
List issues with optional filters.

**Query:** `?sector={sectorId}&state={state}&page={n}`
**Response:** `{ items: Issue[], total: number, page: number }`
**Errors:** 400 Invalid query
```

## Common Error Codes

| Code | Meaning |
|------|---------|
| 400 | Bad Request - Invalid input |
| 401 | Unauthorized - Not authenticated |
| 403 | Forbidden - Not authorized |
| 404 | Not Found - Resource missing |
| 409 | Conflict - Already exists |
| 422 | Unprocessable - Validation failed |
| 429 | Rate Limited - Too many requests |

## Quality Checklist

- [ ] Path follows REST conventions
- [ ] Request/response types are defined
- [ ] Error codes cover failure cases
- [ ] Endpoint is in correct section

## Next Steps

After adding endpoint:
1. If new types needed: `/add-type`
2. To implement in backend: `/backend/dev-cycle`
3. To update feature spec: Edit `specs/features/{name}/api.md`
