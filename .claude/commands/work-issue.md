# Work Issue

name: "work-issue"
description: "Pick up a GitHub issue, investigate, and distribute to platform agents"
parameters:
  - name: "issue"
    description: "Issue number or 'number title' (e.g., '6' or '6 Fix login redirect bug')"
    required: true

---

## Task

Pick up an existing GitHub issue, investigate the root cause, and create platform-specific handoff documents for implementation.

## Input Format

The user can provide:
- Just the number: `6`
- Number and title: `6 Fix login redirect bug`
- Full GitHub reference: `#6 Fix login redirect bug`

Extract the issue number from whatever format is provided.

## Process

### Step 1: Fetch Issue Details

```bash
gh issue view {{number}} --json number,title,body,labels,state,assignees
```

Parse the response to extract:
- Title
- Description/body
- Labels (type, platform, priority, story)
- Current state
- Assignees

### Step 2: Classify Issue Type

Based on labels, determine:
- **Bug** (`type:bug`) → Investigate and create fix handoffs
- **Feature** (`type:feature`) → Link to feature spec if exists
- **Tech Debt** (`type:tech-debt`) → Document scope
- **Standards** (`type:standards`) → Link to standards registry

### Step 3: Identify Platforms

From `platform:*` labels OR from issue body, determine affected platforms:
- `platform:backend` or "Backend" in body → Kotlin/Spring Boot
- `platform:web` or "Web" in body → React/TypeScript
- `platform:mobile` or "Mobile" in body → Flutter/Dart
- `platform:database` or "Database" in body → Migrations/SQL

### Step 4: Update Issue Status

```bash
gh issue edit {{number}} --add-label "status:in-progress" --remove-label "status:ready,status:triage"
gh issue edit {{number}} --add-assignee @me
```

### Step 5: Investigate Root Cause (For Bugs)

Before creating handoff docs, investigate:
1. Read relevant code across platforms
2. Check database state if applicable
3. Trace the data flow
4. Identify the exact root cause

Create central investigation record:
```bash
mkdir -p specs/features/{{feature}}
```

Create: `specs/features/{{feature}}/{{slug}}-investigation.md`

```markdown
# Investigation: {{title}}

**Issue:** #{{number}}
**Date:** {{date}}
**Platforms:** {{platforms}}

## Problem Statement
{{issue body summary}}

## Investigation Steps
1. {{what you checked}}
2. {{what you found}}

## Root Cause
{{detailed root cause explanation}}

## Affected Components
### Backend
- {{files/modules affected}}

### Web
- {{files/modules affected}}

### Mobile
- {{files/modules affected}}

## Fix Approach
{{high-level approach}}
```

### Step 6: Create Platform Handoff Documents

For EACH affected platform, create a handoff document.

**IMPORTANT:** Always create handoff docs in the central specs directory, NOT in platform-specific directories. When running from a platform subdirectory (e.g., `backend/`), look in the parent directory first:

**Location:** `specs/features/{{feature}}/` (or `../specs/features/{{feature}}/` when in a subdirectory)

**Backend:** `specs/features/{{feature}}/{{number}}-{{slug}}-backend.md`
**Web:** `specs/features/{{feature}}/{{number}}-{{slug}}-web.md`
**Mobile:** `specs/features/{{feature}}/{{number}}-{{slug}}-mobile.md`

Use this template with YAML frontmatter:

```markdown
---
issue: {{number}}
title: "{{title}}"
platform: {{platform}}
status: pending
created_by: central-agent
created_at: {{timestamp}}
updated_at: null
dependencies: []
files_changed: []
tests_added: []
commits: []
blockers: []
---

# Issue #{{number}}: {{title}} ({{Platform}})

## Context

{{Summary from investigation - why this fix is needed}}

## Root Cause

{{Platform-specific root cause from investigation}}

## What To Fix

{{Specific instructions for this platform}}

### Files To Modify
- `path/to/file1`
- `path/to/file2`

### Changes Required
1. {{Specific change 1}}
2. {{Specific change 2}}

## Acceptance Criteria

- [ ] {{Criterion 1}}
- [ ] {{Criterion 2}}
- [ ] Tests pass
- [ ] Quality checks pass

## Dependencies

{{If this platform must wait for another, specify here}}
- None | Depends on: backend (must complete first)

## Implementation Notes

_To be filled by platform agent_
```

### Step 7: Determine Execution Order

Based on dependencies, determine which platforms can run in parallel vs sequential:

Example for a bug that starts in backend and affects web display:
```
1. Backend (no dependencies) ← Can start immediately
2. Web (depends on backend API fix) ← Must wait for backend
```

### Step 8: Output Agent Instructions

Print clear instructions for running platform agents:

```markdown
## Issue #{{number}} Ready for Implementation

### Investigation Complete
- Central investigation: `specs/features/{{feature}}/{{slug}}-investigation.md`

### Platform Handoffs Created
{{For each platform}}
- {{Platform}}: `specs/features/{{feature}}/{{number}}-{{slug}}-{{platform}}.md`

### Execution Order

**Phase 1 (Can run in parallel):**
{{List platforms with no dependencies}}

**Phase 2 (After Phase 1):**
{{List platforms that depend on Phase 1}}

### Commands to Run

**Terminal 1 - Backend:**
```bash
cd /path/to/munserv/backend
claude
# Then run: /fix-issue {{number}}
```

**Terminal 2 - Web:** (after backend completes)
```bash
cd /path/to/munserv/web
claude
# Then run: /fix-issue {{number}}
```

### After All Platforms Complete

Run from project root:
```bash
/close-handoff {{number}}
```

This will:
1. Aggregate changes from all platforms
2. Create unified commit
3. Update GitHub issue
4. Create PR
5. Archive handoff documents
```

## Output Format

```markdown
## Working on Issue #{{number}}

**{{title}}**

### Details
- **Type:** {{type}}
- **Platform(s):** {{platforms}}
- **Priority:** {{priority}}

### Investigation Summary
{{Brief root cause}}

### Platform Handoffs

| Platform | Handoff Doc | Status | Dependencies |
|----------|-------------|--------|--------------|
| Backend | `specs/features/{{feature}}/{{number}}-*-backend.md` | pending | None |
| Web | `specs/features/{{feature}}/{{number}}-*-web.md` | pending | Backend |

### Execution Order

1. **Backend** (no dependencies)
2. **Web** (after backend)

### Next Steps

Run these commands in separate terminals:

**Backend Agent:**
```bash
cd backend && claude
/fix-issue {{number}}
```

**Web Agent:** (after backend completes)
```bash
cd web && claude
/fix-issue {{number}}
```

**After all complete:**
```bash
/close-handoff {{number}}
```
```

## Handoff Location Rules

**CRITICAL:** All handoff documents are stored centrally in `specs/features/`, NOT in platform subdirectories.

When running from a platform directory (e.g., `backend/`, `web/`, `mobile/`):
- Look in `../specs/features/{{feature}}/` for existing handoffs
- The path from project root is always `specs/features/{{feature}}/`

This ensures:
1. All platforms reference the same source of truth
2. Handoffs are easy to find regardless of current working directory
3. Investigation and handoff docs stay together

## Platform-Specific Handoff Content

### Backend Handoffs Should Include:
- Specific Kotlin files to modify
- Service/Controller/Repository layer affected
- Sealed Result patterns to follow
- Test file locations

### Web Handoffs Should Include:
- React components affected
- Hooks/API files to modify
- MUI styling requirements
- Test file locations

### Mobile Handoffs Should Include:
- Dart files affected
- Riverpod providers involved
- Widget/page changes
- Test file locations

## Integration

This skill works with:
- `/fix-issue` (per platform) - Implements the fix
- `/close-handoff` - Aggregates and closes
- `/sync-github` - Keeps status in sync

## Example

**Input:** `/work-issue 8`

**Output:**
```markdown
## Working on Issue #8

**[Bug]: Ground Admin Acceptance not working**

### Details
- **Type:** Bug
- **Platform(s):** Backend, Web
- **Priority:** High

### Investigation Summary
`MessageService.performAction()` only marks messages as actioned but never
calls `GroundAdminService.acceptInvitation()` to process the actual acceptance.

### Platform Handoffs

| Platform | Handoff Doc | Status | Dependencies |
|----------|-------------|--------|--------------|
| Backend | `specs/features/ground-admin/008-ground-admin-acceptance-backend.md` | pending | None |

### Execution Order

1. **Backend** (no dependencies) - Fix MessageService

### Next Steps

**Backend Agent:**
```bash
cd backend && claude
/fix-issue 8
```

**After backend completes:**
```bash
/close-handoff 8
```
```
