# Fix Issue

name: "fix-issue"
description: "Implement a fix for a GitHub issue using the platform handoff doc"
parameters:
  - name: "issue"
    description: "Issue number (e.g., '8')"
    required: true

---

## Task

Read the web-specific handoff document for an issue and implement the fix following web coding standards.

## Prerequisites

- Handoff document exists at `web/docs/issues/{number}-*.md`
- Central agent has completed investigation and created this handoff
- You have read `web/CLAUDE.md` for coding standards

## Process

### Step 1: Locate and Parse Handoff Document

```bash
ls web/docs/issues/{{number}}-*.md
```

Read the handoff document and extract:
- **Context**: Why this fix is needed
- **Files to modify**: Specific files listed
- **Acceptance criteria**: What the fix must achieve
- **Dependencies**: Any tasks that must complete first (from other platforms)

Parse YAML frontmatter for:
```yaml
issue: number
status: pending | in_progress | completed | blocked
dependencies: []  # Other platform tasks that must complete first
```

### Step 2: Check Dependencies

If `dependencies` is not empty, verify those tasks are completed:
- Check other platform handoff docs
- If blocked, update status to `blocked` and report

### Step 3: Update Status to In Progress

Update the handoff document frontmatter:
```yaml
status: in_progress
started_at: {{timestamp}}
```

### Step 4: Read Web Standards

Before coding, review:
```
web/CLAUDE.md
```

Pay attention to:
- React Query patterns for data fetching
- MUI v7 sx prop styling (no CSS classes)
- Atomic design component hierarchy
- TypeScript strict mode
- Test patterns (Vitest + RTL + MSW)

### Step 5: Implement the Fix

Follow the TDD cycle from web CLAUDE.md:

1. **TEST FIRST**: Write failing tests for the fix
2. **IMPLEMENT**: Write minimal code to pass tests
3. **REFACTOR**: Clean up following patterns

For each file to modify:
1. Read the current file
2. Understand existing patterns
3. Make minimal, focused changes
4. Use MUI sx prop, no CSS classes

### Step 6: Run Quality Checks

```bash
cd web
pnpm lint
pnpm typecheck
pnpm test:run
pnpm build
```

Fix any issues before proceeding.

### Step 7: Update Handoff Document

Update the handoff document with implementation details:

```yaml
status: completed
completed_at: {{timestamp}}
files_changed:
  - src/features/example/Component.tsx
  - src/features/example/hooks.ts
tests_added:
  - src/features/example/Component.test.tsx
```

Add implementation notes section:
```markdown
## Implementation Notes

### Changes Made
- Updated `useGroundAdmins` hook to invalidate on status change
- Modified table display logic

### Tests Added
- `GroundAdminsPage.test.tsx`: Added test for status refresh

### Decisions Made
- Used React Query invalidation rather than manual refetch
```

### Step 8: Stage Changes (Do NOT Commit)

```bash
git add web/
git add web/docs/issues/{{number}}-*.md
```

Do NOT commit - the central agent will handle the final commit after all platforms complete.

## Output Format

```markdown
## Web Fix Complete for Issue #{{number}}

### Status
✅ Implementation complete

### Files Changed
- `web/src/features/ground-admins/hooks.ts`

### Tests Added
- `web/src/features/ground-admins/hooks.test.tsx`

### Quality Checks
- ✅ Lint passed
- ✅ TypeScript check passed
- ✅ All tests passing
- ✅ Build successful

### Handoff Updated
`web/docs/issues/{{number}}-*.md` → status: completed

### Next Steps
1. If other platforms need changes, run their `/fix-issue` commands
2. When all platforms complete, run `/close-handoff {{number}}` from central agent
```

## Error Handling

**Handoff not found:**
```
Error: No handoff document found at web/docs/issues/{{number}}-*.md

This issue may not have web changes, or the central agent hasn't distributed yet.
Run `/work-issue {{number}}` from the project root first.
```

**Tests failing:**
```
Warning: Tests are failing after implementation

Please fix the failing tests before marking complete.
Run: pnpm test:run
```

**Blocked by dependency:**
```
Blocked: This task depends on {{platform}} completing first.

Check: {{platform}}/docs/issues/{{number}}-*.md
Current status: {{status}}

Wait for that task to complete, then re-run this command.
```

## Integration

This skill is part of the multi-agent issue workflow:
1. Central agent runs `/work-issue` → creates platform handoffs
2. **This skill** → implements web fix
3. Other platform agents run their `/fix-issue`
4. Central agent runs `/close-handoff` → aggregates and closes
