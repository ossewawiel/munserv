# Standards Registry

This document tracks all coding standards, their locations, and enforcement mechanisms.

## Overview

Standards are defined in CLAUDE.md files and enforced through:
- PR checks (automated warnings)
- Weekly validation workflows
- Agent analysis during development

## Quick Links

- **GitHub Issues:** `label:type:standards`
- **Open Violations:** [Filter](../../.github/ISSUE_TEMPLATE/standards_enforcement.yml)
- **PR Check Workflow:** [standards-check.yml](../../.github/workflows/standards-check.yml)

---

## Standards Table

| ID | Standard | Location | Enforcement | Severity |
|----|----------|----------|-------------|----------|
| S001 | Result pattern for errors | CLAUDE.md#critical-rules | PR check | High |
| S002 | Type-safe IDs | CLAUDE.md#critical-rules | Manual review | High |
| S003 | Immutability (val/const/readonly) | CLAUDE.md#critical-rules | PR check | Medium |
| S004 | Feature folder structure | CLAUDE.md#critical-rules | Manual review | Medium |
| S005 | No dead code | CLAUDE.md#critical-rules | Manual review | Low |
| S010 | No wildcard imports | CLAUDE.md#forbidden | PR check | Medium |
| S011 | No any/dynamic types | CLAUDE.md#forbidden | PR check | High |
| S012 | No business logic in controllers | CLAUDE.md#forbidden | Manual review | High |
| S013 | No hardcoded secrets/URLs | CLAUDE.md#forbidden | PR check | Critical |
| S014 | No print/console debugging | CLAUDE.md#forbidden | PR check | Low |
| S020 | Enum snake_case serialization | backend/CLAUDE.md | Automated | High |
| S021 | @JsonValue annotation on enums | backend/CLAUDE.md | Automated | High |
| S022 | Sealed Result for service errors | backend/CLAUDE.md | Manual review | High |
| S030 | React Query for data fetching | web/CLAUDE.md | Manual review | Medium |
| S031 | Atomic design components | web/CLAUDE.md | Manual review | Low |
| S032 | i18n for all user text | web/CLAUDE.md | Manual review | Medium |
| S040 | Riverpod for state management | mobile/CLAUDE.md | Manual review | High |
| S041 | Freezed for models | mobile/CLAUDE.md | Manual review | High |
| S042 | ConsumerWidget/ConsumerStateful | mobile/CLAUDE.md | Manual review | Medium |

---

## Standard Details

### S001: Result Pattern for Errors

**Rule:** Never throw exceptions for expected failures. Use sealed Result types.

**Kotlin:**
```kotlin
sealed interface Result<out T> {
    data class Success<T>(val value: T) : Result<T>
    data class Failure(val error: DomainError) : Result<Nothing>
}
```

**TypeScript:**
```typescript
type Result<T, E> = { ok: true; value: T } | { ok: false; error: E };
```

**Dart:**
```dart
sealed class Result<T> {}
class Success<T> extends Result<T> { final T value; }
class Failure<T> extends Result<T> { final AppError error; }
```

---

### S010: No Wildcard Imports

**Rule:** Always use explicit imports.

**Bad:**
```kotlin
import com.munserv.* // Wildcard
```

**Good:**
```kotlin
import com.munserv.issues.domain.Issue
import com.munserv.issues.service.IssueService
```

**Detection:** `grep -rn "import .*\.\*" backend/src`

---

### S011: No any/dynamic Types

**Rule:** Never use `any` (TypeScript) or `dynamic` (Dart) in production code.

**Detection:**
- TypeScript: `grep -rn ": any\|as any" web/src`
- Dart: `grep -rn "\bdynamic\b" mobile/lib`

**Exceptions:** Test files, external library types

---

### S020: Enum snake_case Serialization

**Rule:** All enums must serialize to snake_case strings.

**Kotlin:**
```kotlin
enum class IssueState(@JsonValue val value: String) {
    REPORTED("reported"),
    IN_PROGRESS("in_progress"),
    FIXED("fixed")
}
```

**TypeScript:**
```typescript
export const IssueState = {
    REPORTED: 'reported',
    IN_PROGRESS: 'in_progress',
    FIXED: 'fixed'
} as const;
```

**Dart:**
```dart
enum IssueState {
    @JsonValue('reported') reported,
    @JsonValue('in_progress') inProgress,
    @JsonValue('fixed') fixed
}
```

**Detection:** `./scripts/validate-enum-sync.sh`

---

## Enforcement Mechanisms

### PR Check Workflow

`.github/workflows/standards-check.yml` runs on every PR and:
1. Scans for forbidden patterns
2. Posts comment with violations
3. Does NOT block merge (warning only)

### Weekly Validation

`.github/workflows/validate-specs.yml` runs weekly and:
1. Checks enum synchronization across platforms
2. Validates spec status vs GitHub issues
3. Creates reconciliation issue if drift detected

### Manual Review

Standards marked "Manual review" require human judgment:
- Code review during PR
- Agent analysis during `/dev-cycle`
- Architecture review for new features

---

## Tracking Violations

### Creating a Standards Issue

Use the issue template or:
```bash
gh issue create \
  --template standards_enforcement.yml \
  --title "[Standards] S020: Missing @JsonValue in MessageType" \
  --label "type:standards,platform:backend"
```

### Querying Open Violations

```bash
# All standards issues
gh issue list --label "type:standards"

# By platform
gh issue list --label "type:standards,platform:backend"

# By severity (use priority labels)
gh issue list --label "type:standards,priority:high"
```

### Compliance Dashboard

Track compliance in GitHub Project:
1. Create "Standards" view
2. Group by `platform:*` labels
3. Sort by `priority:*` labels

---

## Adding New Standards

1. **Define:** Add rule to appropriate CLAUDE.md file
2. **Register:** Add entry to this registry table
3. **Automate:** Add detection to standards-check.yml (if possible)
4. **Document:** Add detailed section with examples

### Template for New Standard

```markdown
### S0XX: Standard Name

**Rule:** Clear description of what must/must not be done.

**Example:**
```language
// Bad
bad_example

// Good
good_example
```

**Detection:** Command or workflow that detects violations

**Exceptions:** Any valid exceptions to the rule
```

---

## Version History

| Date | Change | Author |
|------|--------|--------|
| 2025-01-21 | Initial registry created | Claude Agent |
