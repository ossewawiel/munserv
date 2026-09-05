# Contributing to MunServ

This guide explains how to contribute features, fix bugs, and maintain code quality in MunServ.

## Quick Reference

| I want to... | Do this |
|--------------|---------|
| Report a bug | [Create bug issue](#reporting-bugs) |
| Request a feature | [Create feature issue](#requesting-features) |
| Fix a bug | [Bug fix workflow](#bug-fix-workflow) |
| Add a feature | [Feature workflow](#feature-workflow) |
| Check my code | [Run standards check](#code-standards) |

---

## Getting Started

### Prerequisites

1. **GitHub CLI** - Required for issue management
   ```bash
   # Install
   brew install gh  # macOS
   sudo apt install gh  # Ubuntu

   # Authenticate
   gh auth login
   ```

2. **Setup Labels** (first time only)
   ```bash
   ./scripts/setup-github-labels.sh
   ```

3. **Read the domain language** - `domain/README.md` defines every term. A story, PR or UI string that introduces a term not in `domain/` is not ready; add the concept file and the `language.yaml` entry first. CI runs `scripts/validate-domain-language.py`.

4. **Read Platform Guide** - Before working on any platform:
   - Backend: `backend/CLAUDE.md`
   - Web: `web/CLAUDE.md`
   - Mobile: `mobile/CLAUDE.md`

---

## Reporting Bugs

### Option 1: GitHub Issue (Recommended)

1. Go to **Issues** > **New Issue** > **Bug Report**
2. Fill in the template:
   - Platform affected
   - Severity (Low/Medium/High/Critical)
   - Steps to reproduce
   - Expected vs actual behavior

### Option 2: Claude Agent

```
/create-issue type=bug title="Description of the bug" platform=backend
```

The agent will gather context from the conversation and create a well-formatted issue.

---

## Requesting Features

### Option 1: GitHub Issue

1. Go to **Issues** > **New Issue** > **Feature Request**
2. Fill in:
   - User story ("As a [role], I can [action]")
   - Acceptance criteria
   - Platforms affected
   - Priority

### Option 2: Claude Agent

```
/add-story platform=web story="As an admin, I can export issues to CSV"
```

This adds the story to specs and optionally creates a GitHub issue.

---

## Bug Fix Workflow

### Step 1: Find or Create Issue

```bash
# Search for existing issue
gh issue list --label "type:bug" --search "keyword"

# Or create new issue
gh issue create --template bug_report.yml
```

### Step 2: Create Branch

```bash
git checkout -b fix/issue-123-brief-description
```

### Step 3: Investigate & Fix

Read the relevant `CLAUDE.md` for the platform, then fix the bug.

**With Claude Agent:**
```
Investigate bug #123 and propose a fix
```

### Step 4: Run Tests & Standards Check

```bash
# Backend
cd backend && ./gradlew test

# Web
cd web && pnpm test && pnpm lint

# Mobile
cd mobile && flutter test && flutter analyze
```

### Step 5: Create PR

```bash
gh pr create --title "fix: Brief description" --body "Fixes #123"
```

The PR will automatically:
- Run standards check (warnings only)
- Link to the issue
- Update spec status when merged

### Step 6: Close Handoff (if applicable)

If you created a handoff document during investigation:
```
/close-handoff handoff=specs/features/some-feature/bug-handoff.md
```

---

## Feature Workflow

### Step 1: Create or Find Story

Check if a story exists in `specs/requirements/`:
- `mobile.md` for mobile features
- `web.md` for web features

**Create new story:**
```
/add-story platform=mobile story="As a member, I can filter issues by date range"
```

### Step 2: Plan the Feature

```
/plan-feature feature=date-filter
```

This will:
1. Create/find a GitHub milestone
2. Analyze impact across platforms
3. Generate implementation plan
4. Optionally create platform-specific issues

### Step 3: Implement (Platform by Platform)

**Backend first:**
```bash
git checkout -b feat/date-filter-backend
cd backend
# Implement following backend/CLAUDE.md patterns
```

**Then Web/Mobile:**
```bash
git checkout -b feat/date-filter-web
cd web
# Implement following web/CLAUDE.md patterns
```

### Step 4: Create PRs

```bash
# Link PRs to issues and milestone
gh pr create --title "feat(backend): Add date filter API" \
  --body "Part of #45 milestone" \
  --milestone "date-filter"
```

### Step 5: Sync Status

When all platform PRs are merged:
```
/sync-github
```

Or let the automated workflow handle it.

---

## Code Standards

### Automated Checks

PRs automatically run `.github/workflows/standards-check.yml` which warns about:
- Wildcard imports
- `any`/`dynamic` types
- Hardcoded URLs
- Debug print statements

### Manual Validation

```bash
# Check enum synchronization across platforms
./scripts/validate-enum-sync.sh

# Reconcile specs with GitHub
./scripts/reconcile-specs.sh
```

### Standards Registry

See `specs/architecture/standards-registry.md` for all coding standards and their enforcement.

---

## Working with Claude Agent

### Available Skills

| Skill | Purpose |
|-------|---------|
| `/create-issue` | Create GitHub issue from conversation |
| `/sync-github` | Sync specs ↔ GitHub issues |
| `/close-handoff` | Mark handoff resolved, close issues |
| `/generate-types` | Generate types from specs |
| `/add-story` | Add user story to specs |
| `/plan-feature` | Plan cross-platform feature |
| `/add-endpoint` | Add API endpoint to contract |

### Example Workflows

**Bug investigation:**
```
I'm seeing an error when approving ground admins. The API returns 500.
Can you investigate and create an issue?
```

**Feature planning:**
```
We need to add email notifications when issues change state.
/plan-feature feature=email-notifications
```

**Type synchronization:**
```
I added a new enum value to the backend. Generate the TypeScript and Dart versions.
/generate-types type=IssueState
```

---

## Commit Convention

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation
- `style` - Formatting
- `refactor` - Code restructuring
- `test` - Adding tests
- `chore` - Maintenance

### Scopes
- `backend` - Kotlin/Spring Boot
- `web` - React/TypeScript
- `mobile` - Flutter/Dart
- `specs` - Documentation
- `ci` - GitHub Actions

### Examples
```
feat(backend): Add date range filter to issues API
fix(web): Correct enum serialization for GroundAdminStatus
docs(specs): Update API contract for messaging feature
chore(ci): Add enum validation to standards check
```

---

## Pull Request Guidelines

### Title Format
```
<type>(<scope>): Brief description
```

### Body Template
```markdown
## Summary
Brief description of changes.

## Related Issues
- Fixes #123
- Part of #45 milestone

## Test Plan
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing done

## Screenshots (if UI changes)
[Add screenshots here]
```

### Checklist Before Merging
- [ ] Tests pass
- [ ] No lint errors
- [ ] Standards check reviewed (warnings addressed or justified)
- [ ] Follows platform CLAUDE.md patterns
- [ ] API changes documented in specs/contracts/api.md
- [ ] New types added to specs/contracts/types.md

---

## Release Process

### Version Tags

```bash
git tag v1.2.0
git push origin v1.2.0
```

This triggers:
1. Changelog generation from commits
2. GitHub Release creation
3. Spec status updates

### Changelog

Generated automatically from conventional commits. See `CHANGELOG.md`.

---

## Getting Help

- **Stuck?** Ask in the issue or PR comments
- **Standards question?** Check `specs/architecture/standards-registry.md`
- **API question?** Check `specs/contracts/api.md`
- **Architecture question?** Check `specs/architecture/` directory

---

## Quick Commands Reference

```bash
# Issues
gh issue list                          # List all issues
gh issue list --label "type:bug"       # List bugs
gh issue view 123                      # View issue details
gh issue create --template bug_report.yml  # Create bug

# PRs
gh pr create                           # Create PR interactively
gh pr list                             # List open PRs
gh pr checks                           # View PR check status

# Labels
gh label list                          # List all labels

# Milestones
gh api repos/:owner/:repo/milestones   # List milestones

# Scripts
./scripts/setup-github-labels.sh       # Setup labels
./scripts/validate-enum-sync.sh        # Check enum sync
./scripts/reconcile-specs.sh           # Reconcile specs
./scripts/generate-types.sh --dry-run  # Preview type generation
```
