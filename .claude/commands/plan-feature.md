# Plan Feature

name: "plan-feature"
description: "Generate implementation plan for feature"
parameters:
  - name: "feature"
    description: "Feature name or story ID (e.g., 'reset-pin', 'M8')"
    required: true
  - name: "output"
    description: "Output: plan, handoff, or both"
    default: "both"

---

## Task

Generate cross-platform implementation plan for "{{feature}}".

## Context

Read first:
1. `specs/features/{{feature}}/spec.md` - Feature specification
2. `specs/contracts/api.md` - API contract
3. `specs/requirements/` - User stories
4. Platform CLAUDE.md files for patterns

## Process

### Step 1: Gather Requirements

From feature spec, extract:
- Goal and scope
- User stories involved
- Dependencies
- API endpoints needed

### Step 2: Platform Impact Analysis

For each affected platform:

**Backend:**
- [ ] Domain models/entities
- [ ] DTOs (request/response)
- [ ] Service methods
- [ ] Repository methods
- [ ] Controller endpoints
- [ ] Database migrations

**Web:**
- [ ] TypeScript types
- [ ] API functions
- [ ] React Query hooks
- [ ] Components
- [ ] Pages/routes
- [ ] i18n keys

**Mobile:**
- [ ] Dart models (Freezed)
- [ ] API client methods
- [ ] Repository methods
- [ ] Riverpod providers
- [ ] Screens/widgets
- [ ] Routes

### Step 3: Generate Implementation Order

TDD-compliant order (tests first):

1. **Database** (if changes needed)
2. **Backend domain** → service → controller
3. **Web types** → API → hooks → components
4. **Mobile models** → repository → providers → screens

### Step 4: Create Handoff Plans

Generate platform-specific plans for handoff to `/dev-cycle`.

## Output Format

### Plan Output

```markdown
## Implementation Plan: {{feature}}

### Summary
{{goal}} affecting {{platforms}}.

### Backend Tasks
- [ ] Create ResetPinRequest DTO
- [ ] Add OtpService.sendResetOtp()
- [ ] Add AuthController.resetPin endpoint
- [ ] Write unit tests for OtpService
- [ ] Write integration tests for endpoint

### Web Tasks
- [ ] Add resetPin API function
- [ ] Create useResetPin hook
- [ ] Build ResetPinDialog component

### Mobile Tasks
- [ ] Add resetPin to AuthApi
- [ ] Create resetPinProvider
- [ ] Build ResetPinPage screen

### Dependencies
- OTP service must be available
- Auth feature must be complete

### Estimated Scope
Backend: 3 files | Web: 4 files | Mobile: 4 files
```

### Handoff Format

For each platform, generate:

```markdown
## Handoff: {{platform}}

### Context
{{feature_summary}}

### Files to Create/Modify
- path/to/file1
- path/to/file2

### Implementation Steps
1. [Step with detail]
2. [Step with detail]

### Tests Required
- [ ] Unit test for X
- [ ] Integration test for Y

### Definition of Done
- [ ] All tests passing
- [ ] No lint errors
- [ ] Follows CLAUDE.md patterns
```

## Quality Checklist

- [ ] All platforms covered
- [ ] Tests identified for each component
- [ ] Dependencies documented
- [ ] Order respects dependencies

## Integration

After generating plan:
1. Review plan with user
2. Hand off to platform `/dev-cycle`:
   - `cd backend && /dev-cycle task="[backend handoff]"`
   - `cd web && /dev-cycle task="[web handoff]"`
   - `cd mobile && /dev-cycle task="[mobile handoff]"`

## TodoWrite Integration

Create tracking items:
```
- [ ] [backend] {{feature}}: domain models
- [ ] [backend] {{feature}}: service implementation
- [ ] [backend] {{feature}}: controller endpoint
- [ ] [web] {{feature}}: API and hooks
- [ ] [web] {{feature}}: components
- [ ] [mobile] {{feature}}: providers
- [ ] [mobile] {{feature}}: screens
```
