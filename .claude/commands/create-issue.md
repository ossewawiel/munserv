# Create GitHub Issue

name: "create-issue"
description: "Create GitHub issue from conversation context"
parameters:
  - name: "type"
    description: "Issue type: feature, bug, or standards"
    required: true
  - name: "title"
    description: "Issue title"
    required: true
  - name: "platform"
    description: "Affected platform(s): backend, web, mobile, database"
    required: false
  - name: "story_id"
    description: "Related story ID (M1, W5, etc.)"
    required: false

---

## Task

Create a GitHub issue based on conversation context and provided parameters.

## Context

This skill bridges Claude agent conversations with GitHub issue tracking. Use it when:
- A bug is discovered during development
- A new feature request emerges from discussion
- A standards violation is identified
- Work needs to be tracked for future sessions

## Process

### Step 1: Gather Context

From the conversation, extract:
- **Problem/Request**: What needs to be done?
- **Technical Details**: Code files, error messages, stack traces
- **Acceptance Criteria**: How do we know it's done?
- **Related Work**: Story IDs, other issues, handoff docs

### Step 2: Determine Issue Type

Based on `{{type}}`:

**Feature:**
- Use `.github/ISSUE_TEMPLATE/feature_request.yml` format
- Focus on user story and acceptance criteria
- Link to spec documents

**Bug:**
- Use `.github/ISSUE_TEMPLATE/bug_report.yml` format
- Include reproduction steps
- Note severity and environment

**Standards:**
- Use `.github/ISSUE_TEMPLATE/standards_enforcement.yml` format
- Reference CLAUDE.md rule
- Include code examples

### Step 3: Determine Labels

Build label list:
```
type:{type}
platform:{platform(s)}
status:triage
source:agent-requested
story:{story_id} (if provided)
```

### Step 4: Preview Issue

Show the user:
```markdown
## Issue Preview

**Title:** {{title}}
**Labels:** {{labels}}

**Body:**
{{formatted_body}}
```

### Step 5: Create Issue (with approval)

Ask user for approval, then execute:

```bash
gh issue create \
  --title "{{title}}" \
  --label "{{labels}}" \
  --body "$(cat <<'EOF'
{{body}}

---
*Created by Claude agent during development session.*
EOF
)"
```

### Step 6: Record Issue

Store in Memory MCP:
```
context:last-created-issue → #{{issue_number}}
```

If story_id provided, also link:
```
story:{{story_id}}:issue → #{{issue_number}}
```

## Output Format

```markdown
## Issue Created

**Issue:** #{{number}} - {{title}}
**URL:** {{issue_url}}
**Labels:** {{labels}}

### Next Steps
- [ ] Add to project board (if not automatic)
- [ ] Link to related issues
- [ ] Update handoff doc with issue reference
```

## Examples

### Feature Request
```
/create-issue type=feature title="Add password reset flow" platform=backend,web,mobile story_id=M1
```

### Bug Report
```
/create-issue type=bug title="Enum serialization mismatch in GroundAdminStatus" platform=backend
```

### Standards Violation
```
/create-issue type=standards title="Wildcard imports in AdminService.kt" platform=backend
```

## Quality Checklist

- [ ] Title is clear and actionable
- [ ] Appropriate type selected
- [ ] All relevant platforms labeled
- [ ] Acceptance criteria included (for features)
- [ ] Reproduction steps included (for bugs)
- [ ] Code examples included (for standards)
- [ ] Related issues/docs linked

## Error Handling

If `gh` command fails:
1. Check authentication: `gh auth status`
2. Check repository: `gh repo view`
3. Report error and suggest manual creation

## Integration

After creating issue:
1. If feature → suggest `/plan-feature` with issue reference
2. If bug → suggest creating handoff doc
3. If standards → suggest `/dev-cycle` fix task
