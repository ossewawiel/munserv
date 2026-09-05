# Close Handoff

name: "close-handoff"
description: "Aggregate platform handoffs, commit changes, update GitHub issue, and create PR"
parameters:
  - name: "issue"
    description: "Issue number (e.g., '8')"
    required: true
  - name: "resolution"
    description: "How it was resolved: completed, wontfix, duplicate, deferred"
    default: "completed"

---

## Task

Aggregate changes from all platform handoff documents, create a unified commit, update the GitHub issue, create a PR, and archive the handoff documents.

## Prerequisites

- All platform agents have completed their `/fix-issue` runs
- All platform handoff docs show `status: completed`
- Changes are staged but not committed

## Process

### Step 1: Find All Platform Handoffs

All handoffs live centrally under `specs/features/{feature}/`:

```bash
find specs/features -name "{{number}}-*-backend.md" -o -name "{{number}}-*-web.md" -o -name "{{number}}-*-mobile.md" -o -name "{{number}}-*-database.md" | grep -v /completed/
```

### Step 2: Parse and Verify All Handoffs

For each handoff found, parse YAML frontmatter and verify:

```yaml
status: completed  # Must be completed
files_changed: [...]  # Should have entries
tests_added: [...]  # Should have entries (for bugs)
```

**If any handoff is NOT completed:**
```markdown
## Cannot Close Handoff

The following platforms are not complete:

| Platform | Status | Blockers |
|----------|--------|----------|
| Backend | completed | - |
| Web | in_progress | - |

Please complete all platform fixes before closing.

**To check status:**
- Backend: `cat specs/features/*/{{number}}-*-backend.md`
- Web: `cat specs/features/*/{{number}}-*-web.md`
```

### Step 3: Aggregate Changes

Collect from all platform handoffs:
- All `files_changed`
- All `tests_added`
- All implementation notes

### Step 4: Find Central Investigation Doc

```bash
ls specs/features/*/{{slug}}-investigation.md 2>/dev/null
# or
ls specs/features/{{feature}}/*-investigation.md
```

### Step 5: Create Unified Commit

```bash
# Ensure all changes are staged
git add backend/ web/ mobile/ specs/

# Create commit with details from all platforms
git commit -m "$(cat <<'EOF'
fix(#{{number}}): {{title}}

{{Brief description of fix}}

## Changes

### Backend
{{files_changed from backend handoff}}

### Web
{{files_changed from web handoff if applicable}}

### Mobile
{{files_changed from mobile handoff if applicable}}

## Tests Added
{{aggregated tests_added}}

Closes #{{number}}

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### Step 6: Update GitHub Issue

Add a summary comment to the issue:

```bash
gh issue comment {{number}} --body "$(cat <<'EOF'
## Implementation Complete ✅

### Summary
{{Brief description of what was fixed}}

### Root Cause
{{From investigation doc}}

### Changes by Platform

#### Backend
**Files Modified:**
{{list files_changed}}

**Tests Added:**
{{list tests_added}}

#### Web
{{if applicable}}

#### Mobile
{{if applicable}}

### Verification
- [ ] Backend tests passing
- [ ] Web tests passing
- [ ] Manual verification complete

### PR
{{PR link will be added after creation}}
EOF
)"
```

### Step 7: Create Feature Branch and PR

```bash
# Create branch if not already on one
git checkout -b fix/{{number}}-{{slug}} 2>/dev/null || true

# Push branch
git push -u origin fix/{{number}}-{{slug}}

# Create PR
gh pr create --title "fix(#{{number}}): {{title}}" --body "$(cat <<'EOF'
## Summary
{{Brief description}}

Fixes #{{number}}

## Root Cause
{{From investigation}}

## Changes

### Backend
{{files and description}}

### Web
{{if applicable}}

### Mobile
{{if applicable}}

## Test Plan
- [ ] Backend unit tests pass
- [ ] Web tests pass
- [ ] Manual verification of Ground Admin acceptance flow

## Screenshots/Evidence
{{if applicable}}

---
🤖 Generated with [Claude Code](https://claude.ai/code)
EOF
)"
```

### Step 8: Archive Handoff Documents

Move all handoff docs to completed directories:

```bash
# Archive platform handoffs and the investigation together
mkdir -p specs/features/{{feature}}/completed
mv specs/features/{{feature}}/{{number}}-*.md specs/features/{{feature}}/completed/ 2>/dev/null || true
```

### Step 9: Clean Up

```bash
# Commit archive moves
git add .
git commit -m "chore: archive handoffs for #{{number}}"
git push
```

### Step 10: Final Output

```markdown
## Issue #{{number}} Closed Successfully

### PR Created
{{PR URL}}

### Commit
`{{commit_sha}}` - fix(#{{number}}): {{title}}

### Changes Aggregated

| Platform | Files Changed | Tests Added |
|----------|---------------|-------------|
| Backend | {{count}} | {{count}} |
| Web | {{count}} | {{count}} |
| Mobile | {{count}} | {{count}} |

### Handoffs Archived
- `specs/features/{{feature}}/completed/{{number}}-*.md` (handoffs and investigation)

### GitHub Issue
#{{number}} - Comment added with implementation summary

### Next Steps
1. Review PR: {{PR URL}}
2. Merge when CI passes
3. Verify in staging environment
```

## Resolution Types

| Resolution | Action | Use When |
|------------|--------|----------|
| `completed` | Close issue, create PR, archive | Work finished successfully |
| `wontfix` | Close issue as "not planned", archive | Decided not to implement |
| `duplicate` | Close issue, link duplicate, archive | Covered by another issue |
| `deferred` | Keep issue open, archive handoffs | Postponed to future |

## Error Handling

**No handoffs found:**
```
Error: No platform handoffs found for issue #{{number}}

Searched:
- specs/features/*/{{number}}-*-{backend,web,mobile,database}.md

Run `/work-issue {{number}}` first to create handoffs.
```

**Incomplete handoffs:**
```
Warning: Not all platforms are complete

| Platform | Status |
|----------|--------|
| Backend | completed ✅ |
| Web | in_progress ⏳ |

Options:
1. Wait for Web to complete: `cd web && claude` then `/fix-issue {{number}}`
2. Force close anyway: `/close-handoff {{number}} --force`
```

**Git conflicts:**
```
Error: Git conflicts detected

Please resolve conflicts manually:
1. `git status` to see conflicts
2. Resolve each file
3. `git add .`
4. Re-run `/close-handoff {{number}}`
```

## Integration

This skill completes the multi-agent workflow:
1. `/work-issue` → Creates investigation and platform handoffs
2. Platform `/fix-issue` → Implements fixes
3. **This skill** → Aggregates, commits, creates PR, archives

## Example

**Input:** `/close-handoff 8`

**Output:**
```markdown
## Issue #8 Closed Successfully

### PR Created
https://github.com/ossewawiel/munserv/pull/9

### Commit
`a1b2c3d` - fix(#8): Ground Admin Acceptance not working

### Changes Aggregated

| Platform | Files Changed | Tests Added |
|----------|---------------|-------------|
| Backend | 2 | 1 |
| Web | 0 | 0 |
| Mobile | 0 | 0 |

### Handoffs Archived
- `specs/features/ground-admin/completed/008-ground-admin-acceptance-backend.md`
- `specs/features/ground-admin/completed/008-acceptance-investigation.md`

### GitHub Issue
#8 - Comment added with implementation summary

### Next Steps
1. Review PR: https://github.com/ossewawiel/munserv/pull/9
2. Merge when CI passes
3. Verify Ground Admin acceptance flow works
```
