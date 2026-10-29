# Add Feature

name: "add-feature"
description: "Create feature specification folder"
parameters:
  - name: "name"
    description: "Feature name (kebab-case, e.g., 'reset-pin')"
    required: true
  - name: "goal"
    description: "What this feature achieves (1 sentence)"
    required: true
  - name: "platforms"
    description: "Affected: backend, web, mobile (comma-sep)"
    required: true
  - name: "stories"
    description: "Related story IDs (comma-sep, e.g., 'M8,W5')"
    required: false

---

## Task

Create feature specification at `specs/features/{{name}}/`.

## Context

Read first:
1. `specs/features/` - Existing features
2. `specs/requirements/` - User stories
3. `specs/contracts/api.md` - API endpoints

## Process

### Step 1: Create Directory

```bash
mkdir -p specs/features/{{name}}
```

### Step 2: Create spec.md

Create `specs/features/{{name}}/spec.md`:

```markdown
# Feature: {{name}}

**Goal:** {{goal}}
**Platforms:** {{platforms}}
**Status:** 🔴 Not Started

## Stories
{{#each stories}}
- {{this}}
{{/each}}

## Dependencies
- [List prerequisite features]

## Notes
[Constraints, decisions, or considerations]
```

### Step 3: Create api.md (if has backend)

If platforms includes backend, create `specs/features/{{name}}/api.md`:

```markdown
# {{name}} API

## Endpoints

See: specs/contracts/api.md for full contract.

### Feature-specific endpoints:
- `POST /path` - Description
```

### Step 4: Update Stories

For each story in {{stories}}, add reference in requirements file.

## Output Structure

```
specs/features/{{name}}/
├── spec.md     # Feature overview (SHORT)
└── api.md      # Feature-specific endpoints (if backend)
```

## Template: spec.md

```markdown
# Feature: reset-pin

**Goal:** Allow members to reset forgotten PIN via OTP.
**Platforms:** backend, mobile
**Status:** 🔴 Not Started

## Stories
- M8: Reset forgotten PIN

## Dependencies
- Auth feature complete
- OTP service available

## Notes
- Reuse existing OTP flow from registration
- Rate limit to 3 attempts per hour
```

## Status Indicators

- 🔴 Not Started
- 🟡 In Progress
- 🟢 Complete

## Quality Checklist

- [ ] Name is kebab-case
- [ ] Goal is one clear sentence
- [ ] Stories reference valid IDs
- [ ] Dependencies are identified

## Next Steps

After creating feature:
1. Add API endpoints: `/add-endpoint`
2. Plan implementation: `/plan-feature {{name}}`
3. Start development: Platform-specific `/dev-cycle`
