# Work Story

name: "work-story"
description: "Work on a feature story using existing feature handoff, with automatic back-updates"
parameters:
  - name: "story"
    description: "Story ID (e.g., 'W21') or GitHub issue number (e.g., '32')"
    required: true

---

## Task

Work on a story that's part of a feature milestone, using the existing feature handoff documents. Automatically update all tracking docs and GitHub when complete.

## Process

### Step 1: Resolve Story Reference

If input is a GitHub issue number, fetch it and extract story ID from title:
```bash
gh issue view {{number}} --json number,title,body,labels,milestone
```

Extract:
- Story ID (e.g., W21 from "[W21] Generic data table component")
- Milestone name (e.g., pod-chief-mvp)
- Platform from labels (platform:web, platform:backend, etc.)

If input is a story ID (W21), find the matching GitHub issue:
```bash
gh issue list --search "W21 in:title" --json number,title,milestone --limit 1
```

### Step 2: Find Feature Handoff

Based on milestone name, locate the feature handoff:
```bash
ls specs/features/{{milestone}}/
```

Expected structure:
- `specs/features/{{milestone}}/spec.md` - Feature overview
- `specs/features/{{milestone}}/implementation-plan.md` - Full plan
- `specs/features/{{milestone}}/web-handoff.md` - Web implementation details
- `specs/features/{{milestone}}/backend-handoff.md` - Backend implementation details

### Step 3: Extract Story-Specific Context

Read the relevant handoff document for this platform.
Find the section related to this story ID.

For example, for W21 in web-handoff.md, find:
- The component/page to build
- Files to create
- Implementation steps
- Tests required

### Step 4: Update GitHub Issue Status

```bash
gh issue edit {{number}} --add-label "status:in-progress" --remove-label "status:ready,status:triage"
```

### Step 5: Present Implementation Plan

Output the story-specific implementation plan:

```markdown
## Working on Story {{story_id}}

**Issue:** #{{number}} - {{title}}
**Feature:** {{milestone}}
**Platform:** {{platform}}

### Handoff Reference
`specs/features/{{milestone}}/{{platform}}-handoff.md`

### Implementation Scope

{{Extract story-specific scope from handoff}}

### Files to Create/Modify
{{List from handoff}}

### Tests Required
{{List from handoff}}

### Acceptance Criteria
{{From GitHub issue}}

---

Ready to implement. After completion, I will:
1. Update `specs/requirements/{{platform}}.md` - Mark {{story_id}} as 🟢 Done
2. Update GitHub issue #{{number}} with implementation summary
3. Update milestone progress
```

### Step 6: Implement the Story

Follow platform CLAUDE.md patterns and implement the story.

### Step 7: After Implementation - Back Updates

Once implementation is complete and tests pass:

#### 7a. Update Requirements Spec

Read and update `specs/requirements/{{platform}}.md`:
- Find the row for {{story_id}}
- Change status from `🔴 Pending` to `🟢 Done`

#### 7b. Update GitHub Issue

```bash
# Add completion comment
gh issue comment {{number}} --body "$(cat <<'EOF'
## Implementation Complete ✅

### Summary
{{Brief description of what was implemented}}

### Files Created/Modified
{{List of files}}

### Tests Added
{{List of test files}}

### Verification
- [x] Implementation complete
- [x] Tests passing
- [x] Follows CLAUDE.md patterns

---
*Implemented as part of {{milestone}} milestone*
EOF
)"

# Update labels
gh issue edit {{number}} --add-label "status:done" --remove-label "status:in-progress"
```

#### 7c. Check Milestone Progress

```bash
# Get milestone progress
gh api repos/:owner/:repo/milestones --jq '.[] | select(.title == "{{milestone}}") | "Open: \(.open_issues), Closed: \(.closed_issues)"'
```

Report progress:
```markdown
### Milestone Progress: {{milestone}}
- Completed: {{closed_issues}} / {{total_issues}}
- Remaining: {{open_issues}}
```

#### 7d. Update Feature Spec (if all stories done)

If all stories in the milestone are complete:
- Update `specs/features/{{milestone}}/spec.md`
- Change status from `🔴 Not Started` or `🟡 In Progress` to `🟢 Complete`

### Step 8: Output Summary

```markdown
## Story {{story_id}} Complete ✅

### Implementation Summary
{{What was built}}

### Back-Updates Completed
- [x] `specs/requirements/{{platform}}.md` - {{story_id}} marked Done
- [x] GitHub issue #{{number}} - Commented and labeled
- [x] Milestone progress: {{completed}}/{{total}} stories

### Files Changed
{{List of files}}

### Next Story
Based on implementation order, consider working on:
- {{next_story_id}}: {{next_story_title}} (#{{next_issue_number}})

Run: `/work-story {{next_story_id}}`
```

## Platform Detection

| Story Prefix | Platform | Handoff File |
|--------------|----------|--------------|
| W* | Web | web-handoff.md |
| M* | Mobile | mobile-handoff.md |
| B* | Backend | backend-handoff.md |
| S* | Shared | Check all platforms |

## Error Handling

**No feature handoff found:**
```
Error: No feature handoff found for milestone "{{milestone}}"

Expected: specs/features/{{milestone}}/{{platform}}-handoff.md

Options:
1. Run `/plan-feature feature="{{milestone}}"` to create handoffs
2. Work directly from GitHub issue with `/work-issue {{number}}`
```

**Story not in handoff:**
```
Warning: Story {{story_id}} not found in handoff document.

The handoff exists but doesn't have specific instructions for this story.
Proceeding with GitHub issue description only.
```

## Example

**Input:** `/work-story W21`

**Output:**
```markdown
## Working on Story W21

**Issue:** #32 - Generic data table component
**Feature:** pod-chief-mvp
**Platform:** Web

### Handoff Reference
`specs/features/pod-chief-mvp/web-handoff.md`

### Implementation Scope

Create a reusable GenericDataTable component with:
- Column definitions support
- Pagination
- Sort (prepared, can be disabled)
- Search (prepared, can be disabled)
- Filter panel (prepared, can be disabled)
- Actions column
- Add button slot

### Files to Create
- `src/components/organisms/GenericDataTable/index.tsx`
- `src/components/organisms/GenericDataTable/TableToolbar.tsx`
- `src/components/organisms/GenericDataTable/FilterPanel.tsx`
- `src/components/organisms/GenericDataTable/ColumnHeader.tsx`
- `src/components/organisms/GenericDataTable/types.ts`

### Tests Required
- `GenericDataTable.test.tsx` - Table rendering, pagination, empty state

### Acceptance Criteria
- [ ] Supports column definitions
- [ ] Sort by columns (prepared, can be disabled)
- [ ] Search input (prepared, can be disabled)
- [ ] Filter slide-out panel (prepared, can be disabled)
- [ ] Actions column
- [ ] Add button slot

---

Ready to implement. After completion, I will:
1. Update `specs/requirements/web.md` - Mark W21 as 🟢 Done
2. Update GitHub issue #32 with implementation summary
3. Update milestone progress (1/12 → 2/12)
```

## Integration

This skill is the **execution** step in the feature workflow:

```
/create-feature    → Creates stories, issues, milestone, feature spec
       ↓
/plan-feature      → Creates implementation plan and handoffs
       ↓
/work-story        → Implements individual stories with back-updates  ← THIS SKILL
       ↓
(repeat for each story)
       ↓
Feature complete   → All stories done, feature spec updated
```
