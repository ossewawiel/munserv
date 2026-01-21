# Sync GitHub

name: "sync-github"
description: "Bidirectional sync between specs and GitHub issues"
parameters:
  - name: "direction"
    description: "Sync direction: spec-to-github, github-to-spec, or bidirectional"
    default: "bidirectional"
  - name: "dry_run"
    description: "Preview changes without applying"
    default: "true"

---

## Task

Synchronize story status between spec documents and GitHub issues.

## Context

This skill ensures consistency between:
- `specs/requirements/mobile.md` status indicators
- `specs/requirements/web.md` status indicators
- GitHub issue states (open/closed)
- GitHub issue labels (status:*)

## Process

### Step 1: Fetch Current State

**From Specs:**
Parse `specs/requirements/*.md` files:
```bash
# Extract story statuses
grep -E "^\| (M|W|S)[0-9]+ \|" specs/requirements/*.md
```

Build map:
```
M1: Done
M2: Done
M3: Pending
W1: Done
W2: In Progress
```

**From GitHub:**
```bash
# Get all issues with story labels
gh issue list --state all --label "story:M1" --json number,state,labels
gh issue list --state all --label "story:W1" --json number,state,labels
```

Build map:
```
M1: #5 (closed)
M2: #8 (closed)
M3: (no issue)
W1: #12 (closed)
W2: #15 (open)
```

### Step 2: Detect Drift

Compare maps and categorize:

| Story | Spec Status | GitHub State | Action Needed |
|-------|-------------|--------------|---------------|
| M1 | Done | closed | None |
| M2 | Done | closed | None |
| M3 | Pending | no issue | Create issue? |
| W1 | Done | closed | None |
| W2 | In Progress | open | None |
| W3 | Done | open | Close issue |

### Step 3: Generate Reconciliation Report

```markdown
## Sync Report

### Consistent ({{count}})
- M1: Done / #5 closed
- M2: Done / #8 closed

### Drift Detected ({{count}})

#### Spec says Done, GitHub open
- W3: Spec=Done, #20 open
  **Action:** Close issue #20

#### Spec says Pending, GitHub closed
- M5: Spec=Pending, #25 closed
  **Action:** Update spec to Done

#### No GitHub issue exists
- M3: Spec=Pending, no issue
  **Action:** Create issue (optional)

### Summary
- Total stories: {{total}}
- Consistent: {{consistent}}
- Needs update: {{drift}}
```

### Step 4: Apply Changes (if not dry_run)

**Spec → GitHub:**
```bash
# Close issues for Done stories
gh issue close {{number}} --comment "Closing: story marked Done in spec"

# Reopen issues for Pending/InProgress stories
gh issue reopen {{number}} --comment "Reopening: story not yet Done in spec"
```

**GitHub → Spec:**
Use sed to update spec files:
```bash
# Update to Done
sed -i 's/| {{story_id}} |\(.*\)Pending/| {{story_id}} |\1Done/g' specs/requirements/{{platform}}.md

# Update to In Progress
sed -i 's/| {{story_id}} |\(.*\)Done/| {{story_id}} |\1In Progress/g' specs/requirements/{{platform}}.md
```

### Step 5: Commit Changes

If spec files modified:
```bash
git add specs/requirements/*.md
git commit -m "chore(specs): sync story status from GitHub

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

## Output Format

### Dry Run (default)
```markdown
## Sync Preview (Dry Run)

### Changes to Apply

**GitHub → Spec:**
- M5: Update specs/requirements/mobile.md from Pending to Done

**Spec → GitHub:**
- W3: Close issue #20

**Missing Issues (create?):**
- M3: No issue exists for pending story

### Command to Apply
Run `/sync-github dry_run=false` to apply these changes.
```

### Applied
```markdown
## Sync Complete

### Changes Applied

- Updated M5 status in specs/requirements/mobile.md
- Closed GitHub issue #20 for W3
- Created issue #30 for M3

### Commit
`abc1234` - chore(specs): sync story status from GitHub
```

## Quality Checklist

- [ ] All spec files parsed correctly
- [ ] GitHub API calls successful
- [ ] Drift categorized correctly
- [ ] User approved changes (if not dry_run)
- [ ] Commit created with proper message

## Edge Cases

**Story in multiple issues:**
- Use most recent issue
- Note discrepancy in report

**Story with partial completion:**
- If any platform issue is open, keep story as In Progress
- Only mark Done when all platform issues closed

**No story label on issue:**
- Skip issues without `story:*` labels
- Note in report for manual review

## Integration

This skill is used by:
- `.github/workflows/sync-issue-status.yml` (automated)
- Manual runs via `/sync-github` command
- Weekly validation workflow (creates reconciliation issues)
