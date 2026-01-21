# Work Issue

name: "work-issue"
description: "Pick up a GitHub issue and start working on it"
parameters:
  - name: "issue"
    description: "Issue number or 'number title' (e.g., '6' or '6 Fix login redirect bug')"
    required: true

---

## Task

Pick up an existing GitHub issue and set up the working context for fixing/implementing it.

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
- **Bug** (`type:bug`) → Create fix handoff doc
- **Feature** (`type:feature`) → Link to feature spec if exists
- **Tech Debt** (`type:tech-debt`) → Document scope
- **Standards** (`type:standards`) → Link to standards registry

### Step 3: Identify Platforms

From `platform:*` labels, determine affected platforms:
- `platform:backend` → Kotlin/Spring Boot
- `platform:web` → React/TypeScript
- `platform:mobile` → Flutter/Dart
- `platform:database` → Migrations/SQL

### Step 4: Create Todo List

Generate todos based on issue type:

**For Bugs:**
```
- [ ] Investigate root cause
- [ ] Identify affected files
- [ ] Implement fix
- [ ] Write/update tests
- [ ] Verify fix locally
- [ ] Create PR linked to issue
```

**For Features:**
```
- [ ] Review feature spec (if exists)
- [ ] Implement backend changes
- [ ] Implement web changes
- [ ] Implement mobile changes
- [ ] Write tests
- [ ] Update documentation
- [ ] Create PR linked to issue
```

### Step 5: Create Handoff Doc (Bugs Only)

For bugs, create: `specs/features/{{feature}}/{{slug}}-fix-handoff.md`

Template:
```markdown
# Bug Fix: {{title}}

**Issue:** #{{number}}
**Status:** In Progress
**Platform(s):** {{platforms}}

## Problem

{{issue body or summary}}

## Root Cause

_To be determined during investigation_

## Affected Files

_List files that need changes_

## Fix Approach

_Document the solution_

## Testing

- [ ] Unit tests
- [ ] Manual verification
- [ ] Regression check

## Verification

_Steps to verify the fix works_
```

### Step 6: Update Issue Status

```bash
# Add in-progress label
gh issue edit {{number}} --add-label "status:in-progress" --remove-label "status:ready,status:triage"

# Assign to current user (optional)
gh issue edit {{number}} --add-assignee @me
```

### Step 7: Display Summary

Show the user:
1. Issue details
2. Created todos
3. Relevant files to check
4. Handoff doc location (if created)
5. Next steps

## Output Format

```markdown
## Working on Issue #{{number}}

**{{title}}**

### Details
- **Type:** {{type}}
- **Platform(s):** {{platforms}}
- **Priority:** {{priority}}

### Description
{{body summary}}

### Todo List
{{generated todos}}

### Relevant Files
Based on the issue, check these locations:
- {{file suggestions based on platform/type}}

### Handoff Doc
Created: `specs/features/{{feature}}/{{slug}}-fix-handoff.md`

### Next Steps
1. Read the CLAUDE.md for affected platform(s)
2. Investigate the issue
3. Update handoff doc with findings
4. Implement fix
5. Run `/close-handoff` when done
```

## Platform-Specific Guidance

### Backend Issues
```
Read: backend/CLAUDE.md
Check: backend/src/main/kotlin/com/munserv/{{feature}}/
Tests: backend/src/test/kotlin/com/munserv/{{feature}}/
```

### Web Issues
```
Read: web/CLAUDE.md
Check: web/src/features/{{feature}}/
Tests: web/src/features/{{feature}}/*.test.ts
```

### Mobile Issues
```
Read: mobile/CLAUDE.md
Check: mobile/lib/features/{{feature}}/
Tests: mobile/test/features/{{feature}}/
```

## Example Usage

**Input:** `6 Fix login redirect after session timeout`

**Output:**
```markdown
## Working on Issue #6

**Fix login redirect after session timeout**

### Details
- **Type:** Bug
- **Platform(s):** Web
- **Priority:** High

### Description
Users are not redirected to login page when session expires...

### Todo List
- [ ] Investigate root cause
- [ ] Identify affected files
- [ ] Implement fix
- [ ] Write/update tests
- [ ] Verify fix locally
- [ ] Create PR linked to issue

### Relevant Files
Based on the issue, check these locations:
- web/src/features/auth/
- web/src/shared/api/client.ts
- web/src/routing/

### Handoff Doc
Created: `specs/features/auth/login-redirect-fix-handoff.md`

### Next Steps
1. Read web/CLAUDE.md
2. Investigate the auth flow
3. Update handoff doc with findings
4. Implement fix
5. Run `/close-handoff 6` when done
```

## Integration

This skill works with:
- `/close-handoff` - To complete the issue
- `/sync-github` - To verify sync status
- Platform `/dev-cycle` skills - For implementation guidance
