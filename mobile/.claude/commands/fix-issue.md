# Fix Issue

name: "fix-issue"
description: "Implement a fix for a GitHub issue using the platform handoff doc"
parameters:
  - name: "issue"
    description: "Issue number (e.g., '8')"
    required: true

---

## Task

Read the mobile-specific handoff document for an issue and implement the fix following mobile coding standards.

## Prerequisites

- Handoff document exists at `mobile/docs/issues/{number}-*.md`
- Central agent has completed investigation and created this handoff
- You have read `mobile/CLAUDE.md` for coding standards

## Process

### Step 1: Locate and Parse Handoff Document

```bash
ls mobile/docs/issues/{{number}}-*.md
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

### Step 4: Read Mobile Standards

Before coding, review:
```
mobile/CLAUDE.md
```

Pay attention to:
- Riverpod provider patterns
- Freezed model patterns
- Result type for error handling
- Material Design 3 theming
- ConsumerWidget over StatefulWidget
- Test patterns (flutter_test + Mocktail)

### Step 5: Implement the Fix

Follow the TDD cycle from mobile CLAUDE.md:

1. **TEST FIRST**: Write failing tests for the fix
2. **IMPLEMENT**: Write minimal code to pass tests
3. **REFACTOR**: Clean up following patterns

For each file to modify:
1. Read the current file
2. Understand existing patterns
3. Make minimal, focused changes
4. Use Riverpod for state, Freezed for models

### Step 6: Run Quality Checks

```bash
cd mobile
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs  # if models changed
```

Fix any issues before proceeding.

### Step 7: Update Handoff Document

Update the handoff document with implementation details:

```yaml
status: completed
completed_at: {{timestamp}}
files_changed:
  - lib/features/example/presentation/page.dart
  - lib/features/example/providers/providers.dart
tests_added:
  - test/features/example/page_test.dart
```

Add implementation notes section:
```markdown
## Implementation Notes

### Changes Made
- Updated `groundAdminActionProvider` to handle message-based acceptance
- Modified invitation response flow

### Tests Added
- `ground_admin_providers_test.dart`: Added test for acceptance flow

### Decisions Made
- Kept using message action flow rather than direct GA endpoint
```

### Step 8: Stage Changes (Do NOT Commit)

```bash
git add mobile/
git add mobile/docs/issues/{{number}}-*.md
```

Do NOT commit - the central agent will handle the final commit after all platforms complete.

## Output Format

```markdown
## Mobile Fix Complete for Issue #{{number}}

### Status
✅ Implementation complete

### Files Changed
- `mobile/lib/features/ground_admin/providers/ground_admin_providers.dart`

### Tests Added
- `mobile/test/features/ground_admin/providers_test.dart`

### Quality Checks
- ✅ Flutter analyze passed
- ✅ All tests passing
- ✅ Build runner complete (if applicable)

### Handoff Updated
`mobile/docs/issues/{{number}}-*.md` → status: completed

### Next Steps
1. If other platforms need changes, run their `/fix-issue` commands
2. When all platforms complete, run `/close-handoff {{number}}` from central agent
```

## Error Handling

**Handoff not found:**
```
Error: No handoff document found at mobile/docs/issues/{{number}}-*.md

This issue may not have mobile changes, or the central agent hasn't distributed yet.
Run `/work-issue {{number}}` from the project root first.
```

**Tests failing:**
```
Warning: Tests are failing after implementation

Please fix the failing tests before marking complete.
Run: flutter test
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
2. **This skill** → implements mobile fix
3. Other platform agents run their `/fix-issue`
4. Central agent runs `/close-handoff` → aggregates and closes
