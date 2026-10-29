# Fix Issue

name: "fix-issue"
description: "Implement a fix for a GitHub issue using the platform handoff doc"
parameters:
  - name: "issue"
    description: "Issue number (e.g., '8')"
    required: true

---

## Task

Read the backend-specific handoff document for an issue and implement the fix following backend coding standards.

## Prerequisites

- Handoff document exists (see Step 1 for location)
- Central agent has completed investigation and created this handoff
- You have read `backend/CLAUDE.md` for coding standards

## Process

### Step 1: Locate and Parse Handoff Document

**IMPORTANT:** Always look in the central specs directory first, NOT in platform-specific directories.

**Primary location (from project root):** `specs/features/{feature}/{number}-*-backend.md`
**When running from backend directory:** `../specs/features/{feature}/{number}-*-backend.md`

```bash
# First, search in the central specs directory (parent of current dir)
find ../specs/features -name "{{number}}-*-backend.md" 2>/dev/null || find specs/features -name "{{number}}-*-backend.md" 2>/dev/null
```

If not found in specs, check legacy location as fallback:
```bash
ls docs/issues/{{number}}-*.md 2>/dev/null
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

### Step 4: Read Backend Standards

Before coding, review:
```
backend/CLAUDE.md
```

Pay attention to:
- Sealed Result pattern for error handling
- Value objects for type-safe IDs
- Service layer patterns
- Test patterns (MockK + Kotest)

### Step 5: Implement the Fix

Follow the TDD cycle from backend CLAUDE.md:

1. **TEST FIRST**: Write failing tests for the fix
2. **IMPLEMENT**: Write minimal code to pass tests
3. **REFACTOR**: Clean up following patterns

For each file to modify:
1. Read the current file
2. Understand existing patterns
3. Make minimal, focused changes
4. Ensure changes follow sealed Result pattern

### Step 6: Run Quality Checks

```bash
cd backend
./gradlew ktlintCheck
./gradlew test
./gradlew build
```

Fix any issues before proceeding.

### Step 7: Update Handoff Document

Update the handoff document with implementation details:

```yaml
status: completed
completed_at: {{timestamp}}
files_changed:
  - path/to/file1.kt
  - path/to/file2.kt
tests_added:
  - path/to/Test1.kt
  - path/to/Test2.kt
```

Add implementation notes section:
```markdown
## Implementation Notes

### Changes Made
- Modified `MessageService.performAction()` to call GroundAdminService
- Added injection of GroundAdminService dependency

### Tests Added
- `MessageServiceTest.kt`: Added test for GA invitation acceptance flow

### Decisions Made
- Used existing `GroundAdminService.acceptInvitation()` rather than duplicating logic
```

### Step 8: Stage Changes (Do NOT Commit)

```bash
git add backend/
# Stage the handoff document (in central specs directory)
git add ../specs/features/**/{{number}}-*-backend.md 2>/dev/null || git add specs/features/**/{{number}}-*-backend.md 2>/dev/null
```

Do NOT commit - the central agent will handle the final commit after all platforms complete.

## Output Format

```markdown
## Backend Fix Complete for Issue #{{number}}

### Status
✅ Implementation complete

### Files Changed
- `backend/src/main/kotlin/com/munserv/messages/service/MessageService.kt`

### Tests Added
- `backend/src/test/kotlin/com/munserv/messages/service/MessageServiceTest.kt`

### Quality Checks
- ✅ ktlintCheck passed
- ✅ All tests passing
- ✅ Build successful

### Handoff Updated
`specs/features/{feature}/{{number}}-*-backend.md` → status: completed

### Next Steps
1. If other platforms need changes, run their `/fix-issue` commands
2. When all platforms complete, run `/close-handoff {{number}}` from central agent
```

## Error Handling

**Handoff not found:**
```
Error: No handoff document found.

Searched locations:
1. ../specs/features/**/{{number}}-*-backend.md (primary - central specs directory)
2. docs/issues/{{number}}-*.md (legacy fallback)

This issue may not have backend changes, or the central agent hasn't distributed yet.
Run `/work-issue {{number}}` from the project root first.
```

**Tests failing:**
```
Warning: Tests are failing after implementation

Please fix the failing tests before marking complete.
Run: ./gradlew test --info
```

**Blocked by dependency:**
```
Blocked: This task depends on {{platform}} completing first.

Check: specs/features/**/{{number}}-*-{{platform}}.md
Current status: {{status}}

Wait for that task to complete, then re-run this command.
```

## Integration

This skill is part of the multi-agent issue workflow:
1. Central agent runs `/work-issue` → creates platform handoffs
2. **This skill** → implements backend fix
3. Other platform agents run their `/fix-issue`
4. Central agent runs `/close-handoff` → aggregates and closes
