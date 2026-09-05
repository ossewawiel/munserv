# Add User Story

name: "add-story"
description: "Add user story to requirements"
parameters:
  - name: "platform"
    description: "mobile, web, or shared"
    required: true
  - name: "story"
    description: "User story in 'As X, I can Y' format"
    required: true
  - name: "criteria"
    description: "Acceptance criteria (pipe-separated)"
    required: false

---

## Task

Add user story "{{story}}" to `specs/requirements/{{platform}}.md`.

## Context

Read first:
0. `domain/README.md` - The vocabulary; do not introduce a term that is not defined there
1. `specs/requirements/{{platform}}.md` - Current stories
2. `CLAUDE.md` - Domain glossary

## Process

### Step 1: Determine Story ID

Read existing stories and find next ID:
- Mobile: M{next} (e.g., M8, M9)
- Web: W{next} (e.g., W10, W11)
- Shared: S{next} (e.g., S1, S2)

### Step 2: Parse Story

Extract from "{{story}}":
- **Actor**: member, admin, or system
- **Action**: what they can do
- **Outcome**: expected result

### Step 3: Format Entry

Add to table in `specs/requirements/{{platform}}.md`:

```markdown
| {{id}} | {{story}} | {{criteria}} | 🔴 Pending |
```

### Step 4: Check Feature Reference

If this story belongs to an existing feature in `specs/features/`:
- Add story ID to that feature's `spec.md`

## Output Format

**SHORT format (table row):**
```markdown
| M8 | Reset forgotten PIN | OTP sent | New PIN set | 🔴 Pending |
```

**Or expanded format (if table doesn't exist):**
```markdown
## M8: Reset PIN
**Story:** As a member, I can reset my PIN if forgotten
**Criteria:** OTP sent | New PIN set | Old PIN invalidated
**Status:** 🔴 Pending
```

## Quality Checklist

- [ ] Story ID is sequential
- [ ] Criteria are testable (verifiable outcomes)
- [ ] Story follows "As X, I can Y" format
- [ ] Related feature updated if applicable
- [ ] GitHub issue created (if approved)

## Status Indicators

- 🟢 Done - Implemented and tested
- 🟡 In Progress - Currently being worked on
- 🔴 Pending - Not started

## GitHub Integration

### Step 5: Create GitHub Issue (Optional)

Ask user:
```
Would you like me to create a GitHub issue for this story?
- Yes, create issue
- No, spec entry only
```

If yes, create issue using `/create-issue`:
```bash
gh issue create \
  --title "[{{id}}]: {{short_story_title}}" \
  --label "type:feature,platform:{{platform}},status:triage,source:spec-derived,story:{{id}}" \
  --body "$(cat <<'EOF'
## User Story

{{story}}

## Acceptance Criteria

{{criteria_as_checklist}}

## References

- Spec: `specs/requirements/{{platform}}.md`

---
*Created from spec by Claude agent.*
EOF
)"
```

### Step 6: Update Spec with Issue Link

Add issue number to spec table:
```markdown
| {{id}} | {{story}} | {{criteria}} | 🔴 Pending | [#{{issue_number}}](link) |
```

## Next Steps

After adding story:
1. If new feature needed: `/add-feature`
2. If API changes needed: `/add-endpoint`
3. To plan implementation: `/plan-feature {{id}}`
4. To track in GitHub: Issue already created (if approved)
