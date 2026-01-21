# Close Handoff

name: "close-handoff"
description: "Mark handoff document resolved and close linked GitHub issue"
parameters:
  - name: "handoff"
    description: "Path to handoff document or feature name"
    required: true
  - name: "resolution"
    description: "How it was resolved: completed, wontfix, duplicate"
    default: "completed"

---

## Task

Mark a handoff document as resolved and close any linked GitHub issues.

## Context

Handoff documents (`*-handoff.md`) are created during feature planning or bug investigation to pass work between sessions. This skill:
1. Archives the handoff document
2. Closes linked GitHub issues
3. Updates related specs
4. Cleans up Memory MCP context

## Process

### Step 1: Locate Handoff Document

Find the handoff document:
```bash
# If path provided
ls "{{handoff}}"

# If feature name provided
ls specs/features/{{handoff}}/*-handoff.md
ls specs/features/{{handoff}}/handoff.md
```

### Step 2: Parse Handoff Document

Extract from handoff:
- **Linked Issues**: GitHub issue numbers (`#123`)
- **Story IDs**: M1, W5, etc.
- **Files Modified**: List of changed files
- **Status**: Current completion status

### Step 3: Verify Resolution

Before closing, confirm:
- [ ] All tasks in handoff completed
- [ ] Tests passing
- [ ] No open questions/blockers

If incomplete:
```markdown
## Cannot Close Handoff

The following items are not resolved:
- [ ] Task X still pending
- [ ] Open question: Y

Please complete these items first, or use `resolution=wontfix` to close anyway.
```

### Step 4: Close GitHub Issues

For each linked issue:
```bash
gh issue close {{number}} --comment "$(cat <<'EOF'
## Resolved

This issue was resolved as part of the {{feature}} implementation.

**Resolution:** {{resolution}}
**Handoff:** {{handoff_path}}

### Summary
{{summary_from_handoff}}
EOF
)"
```

### Step 5: Update Story Status

If story IDs found in handoff:
```bash
# Update spec status to Done
sed -i 's/| {{story_id}} |\(.*\)In Progress/| {{story_id}} |\1Done/g' specs/requirements/{{platform}}.md
```

### Step 6: Archive Handoff Document

Move to archive or mark as resolved:

**Option A: Archive directory**
```bash
mkdir -p specs/features/{{feature}}/archive
mv {{handoff_path}} specs/features/{{feature}}/archive/
```

**Option B: Add resolved header**
```markdown
---
status: resolved
resolved_date: {{date}}
resolution: {{resolution}}
---

# [RESOLVED] {{original_title}}
...
```

### Step 7: Clean Up Memory MCP

Remove context keys:
```
DELETE context:current-feature (if matches)
DELETE context:blockers (if related)
```

### Step 8: Commit Changes

```bash
git add specs/
git commit -m "chore(handoff): close {{feature}} handoff

Resolution: {{resolution}}
Issues closed: {{issue_numbers}}

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

## Output Format

```markdown
## Handoff Closed

**Document:** {{handoff_path}}
**Resolution:** {{resolution}}
**Date:** {{date}}

### Issues Closed
- #{{number1}}: {{title1}}
- #{{number2}}: {{title2}}

### Stories Updated
- {{story_id}}: Pending → Done

### Files Archived
- {{handoff_path}} → archive/

### Commit
`abc1234` - chore(handoff): close {{feature}} handoff

### Next Steps
- Review any follow-up items noted in handoff
- Update project board if needed
```

## Resolution Types

| Resolution | Action | Use When |
|------------|--------|----------|
| `completed` | Close issues, mark Done | Work finished successfully |
| `wontfix` | Close issues as "not planned" | Decided not to implement |
| `duplicate` | Close issues, link to duplicate | Covered by another issue |
| `deferred` | Keep issues open, archive handoff | Postponed to future |

## Quality Checklist

- [ ] All handoff tasks verified complete
- [ ] GitHub issues closed with summary
- [ ] Spec status updated
- [ ] Handoff archived
- [ ] Memory MCP cleaned
- [ ] Commit created

## Error Handling

**Handoff not found:**
```
Error: Handoff document not found at {{path}}
Searched:
- specs/features/{{feature}}/*-handoff.md
- specs/features/{{feature}}/handoff.md

Please provide the full path.
```

**Issue close fails:**
```
Warning: Could not close issue #{{number}}
Reason: {{error}}

Please close manually: gh issue close {{number}}
```

## Integration

Related skills:
- `/plan-feature` - Creates handoff documents
- `/create-issue` - Links issues to handoffs
- `/sync-github` - Keeps status in sync
