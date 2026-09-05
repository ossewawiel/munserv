# Create Feature

name: "create-feature"
description: "Decompose feature requirements into stories and create GitHub issues"
parameters:
  - name: "description"
    description: "Feature requirements - can be a paragraph explaining the feature"
    required: true
  - name: "name"
    description: "Feature name (kebab-case). If not provided, will be derived from description"
    required: false

---

## Task

Analyze feature requirements, decompose into user stories, and create GitHub issues for each story.

## Context

Read first:
0. `domain/README.md` - The vocabulary; do not introduce a term that is not defined there
1. `specs/requirements/mobile.md` - Existing mobile stories (for ID sequencing)
2. `specs/requirements/web.md` - Existing web stories (for ID sequencing)
3. `specs/contracts/api.md` - Existing API endpoints
4. `CLAUDE.md` - Domain glossary and project context

## Process

### Step 1: Analyze Feature Description

Parse the description paragraph to extract:
- **Goal**: What problem does this solve?
- **Actors**: Who uses this? (member, admin, system)
- **Platforms**: Which platforms are affected? (mobile, web, backend)
- **Key capabilities**: What can users do?
- **Data involved**: What entities/data are created or modified?
- **Constraints**: Any limitations or special requirements mentioned?

### Step 2: Derive Feature Name

If `name` not provided, derive from description:
- Extract key concept (e.g., "notification preferences" → `notification-preferences`)
- Use kebab-case
- Keep it short (2-3 words max)

### Step 3: Propose User Stories

Break down into atomic user stories following the format:
```
As a [actor], I can [action] so that [benefit]
```

**Guidelines for story decomposition:**
- Each story should be independently implementable
- Each story should be testable with clear acceptance criteria
- Group by actor (member stories, admin stories)
- Consider the CRUD operations needed
- Consider edge cases as separate stories if complex

**Example decomposition:**
```
Feature: "Members should control notifications - toggle on/off, select issue types. Admins see stats and send broadcasts."

Stories:
- M9: As a member, I can enable/disable push notifications
- M10: As a member, I can select which issue types trigger notifications
- M11: As a member, I can see my notification history
- W8: As an admin, I can view notification delivery statistics
- W9: As an admin, I can send broadcast notifications to all members
```

### Step 4: Present Stories for Approval

Display proposed stories to user:

```markdown
## Feature: {{name}}

### Summary
{{one sentence summary of the feature}}

### Proposed Stories

#### Mobile (Member)
| ID | Story | Acceptance Criteria |
|----|-------|---------------------|
| M9 | As a member, I can enable/disable push notifications | Toggle visible | Setting persists | Takes effect immediately |
| M10 | As a member, I can select which issue types trigger notifications | All types listed | Multi-select works | Default is all |

#### Web (Admin)
| ID | Story | Acceptance Criteria |
|----|-------|---------------------|
| W8 | As an admin, I can view notification delivery statistics | Shows sent/delivered/failed | Filterable by date |
| W9 | As an admin, I can send broadcast notifications | Can compose message | Preview before send | Delivery confirmation |

### Platforms Affected
- Backend: New notification preferences API
- Mobile: Settings screen additions
- Web: Admin notification management pages

---

**Options:**
1. ✅ Approve all stories
2. ✏️ Modify (tell me what to change)
3. ➕ Add more stories
4. ❌ Cancel
```

### Step 5: Get User Approval

Wait for user response:
- **Approve**: Proceed to creation
- **Modify**: Adjust stories based on feedback, re-present
- **Add more**: Add additional stories, re-present
- **Cancel**: Stop without creating anything

### Step 6: Create Stories

For each approved story, call the add-story logic:

1. Read current stories to get next ID
2. Add entry to `specs/requirements/{{platform}}.md`
3. Use format:
```markdown
| {{id}} | {{story}} | {{criteria}} | 🔴 Pending |
```

### Step 7: Create GitHub Milestone

```bash
gh api repos/:owner/:repo/milestones -X POST \
  -f title="{{name}}" \
  -f description="{{feature summary}}" \
  -f state="open"
```

Store the milestone number for issue creation.

### Step 8: Create GitHub Issues

For each story, create a GitHub issue:

```bash
gh issue create \
  --title "[{{id}}] {{short_title}}" \
  --label "type:feature,platform:{{platform}},status:ready,story:{{id}}" \
  --milestone "{{name}}" \
  --body "$(cat <<'EOF'
## User Story

{{full story text}}

## Acceptance Criteria

{{criteria as checklist}}

## Platform
{{platform}}

## Feature
Part of: {{name}} milestone

## References
- Spec: `specs/requirements/{{platform}}.md`
- Feature: `specs/features/{{name}}/spec.md`

---
*Created by /create-feature*
EOF
)"
```

### Step 9: Create Feature Spec

Create `specs/features/{{name}}/spec.md`:

```markdown
# Feature: {{name}}

**Goal:** {{goal extracted from description}}
**Platforms:** {{platforms}}
**Status:** 🔴 Not Started
**Milestone:** {{milestone_number}}

## Original Requirements

{{original description paragraph}}

## Stories

### Mobile
{{#each mobile_stories}}
- {{id}}: {{short_title}} ([#{{issue_number}}](link))
{{/each}}

### Web
{{#each web_stories}}
- {{id}}: {{short_title}} ([#{{issue_number}}](link))
{{/each}}

## Dependencies
- [Identify from description or mark TBD]

## API Endpoints Needed
- [List new endpoints identified, or mark TBD]

## Notes
- [Any constraints or decisions from the description]
```

### Step 10: Output Summary

```markdown
## Feature Created: {{name}}

### Stories Created
| ID | Title | GitHub Issue |
|----|-------|--------------|
| M9 | Enable/disable notifications | #42 |
| M10 | Select notification types | #43 |
| W8 | View notification stats | #44 |
| W9 | Send broadcasts | #45 |

### Artifacts
- Feature spec: `specs/features/{{name}}/spec.md`
- Milestone: {{name}} ({{milestone_url}})
- Stories added to: `specs/requirements/mobile.md`, `specs/requirements/web.md`

### Next Steps
1. Review created issues in GitHub
2. Add API endpoints: `/add-endpoint`
3. Plan implementation: `/plan-feature {{name}}`
4. Assign issues to developers or work with `/work-issue`
```

## Quality Checklist

- [ ] All stories follow "As X, I can Y" format
- [ ] Each story has testable acceptance criteria
- [ ] Stories are atomic (independently implementable)
- [ ] Story IDs are sequential (no gaps, no duplicates)
- [ ] GitHub issues created with correct labels
- [ ] Milestone links all related issues
- [ ] Feature spec references all stories

## Error Handling

### If GitHub commands fail:
- Report which step failed
- Stories already added to specs remain (manual cleanup if needed)
- Provide manual commands to complete setup

### If story ID conflicts:
- Re-read requirements files
- Use next available ID
- Never overwrite existing stories

## Integration

After `/create-feature`, the natural next steps are:
1. `/add-endpoint` - Define API contracts for new endpoints
2. `/plan-feature {{name}}` - Generate implementation plan and handoffs
3. `/work-issue {{number}}` - Work on individual story issues

## Example

**Input:**
```
/create-feature description="Members need to reset their PIN if forgotten. They should request a reset which sends an OTP to their phone. After entering the OTP, they set a new PIN. Rate limit to prevent abuse. Admins should see a log of reset attempts for security monitoring."
```

**Decomposition:**
```
Feature: pin-reset

Stories:
- M8: As a member, I can request a PIN reset via OTP
  Criteria: OTP sent to phone | 60 second cooldown shown

- M9: As a member, I can enter OTP and set new PIN
  Criteria: OTP validated | New PIN saved | Old PIN invalid

- W8: As an admin, I can view PIN reset attempt logs
  Criteria: Shows member, timestamp, success/fail | Filterable

Backend: Reset endpoint, OTP service integration, rate limiting, audit log
Mobile: Reset request screen, OTP entry screen, new PIN screen
Web: Reset attempts log page with filters
```
