# Add Code Pattern

name: "add-pattern"
description: "Add code pattern with example"
parameters:
  - name: "name"
    description: "Pattern name (e.g., 'Optimistic Updates')"
    required: true
  - name: "platform"
    description: "backend, mobile, web, or all"
    required: true
  - name: "problem"
    description: "Problem it solves (1 sentence)"
    required: true
  - name: "solution"
    description: "How it solves the problem (1-2 sentences)"
    required: false

---

## Task

Add pattern "{{name}}" to `specs/architecture/patterns.md`.

## Context

Read first:
1. `specs/architecture/patterns.md` - Existing patterns
2. `{{platform}}/CLAUDE.md` - Platform conventions

## Process

### Step 1: Find Section

Locate platform section in patterns.md:
- Backend Patterns
- Mobile Patterns
- Web Patterns
- Shared Patterns (for "all")

### Step 2: Format Pattern

```markdown
## {{name}} ({{platform}})

**Problem:** {{problem}}

**Solution:** {{solution}}

```{{language}}
// Concise code example
```

**When:** [Use cases]
**Avoid:** [Anti-patterns]
```

### Step 3: Add to Document

Insert pattern in appropriate section of `specs/architecture/patterns.md`.

### Step 4: Cross-reference

If pattern introduces new rules, update platform CLAUDE.md.

## Pattern Template (CONCISE)

### Backend Example
```markdown
## Sealed Result Pattern (backend)

**Problem:** Need type-safe error handling without exceptions.

**Solution:** Return sealed Result<T, E> from service methods.

```kotlin
sealed class Result<out T, out E> {
    data class Success<T>(val value: T) : Result<T, Nothing>()
    data class Failure<E>(val error: E) : Result<Nothing, E>()
}

fun findMember(id: MemberId): Result<Member, MemberError> =
    memberRepository.findById(id)?.let { Result.Success(it) }
        ?: Result.Failure(MemberError.NotFound(id))
```

**When:** Service layer methods, API responses
**Avoid:** Internal helpers, simple CRUD
```

### Web Example
```markdown
## Optimistic Updates (web)

**Problem:** UI feels slow waiting for server.

**Solution:** Update UI immediately, rollback on error.

```typescript
const mutation = useMutation({
  onMutate: async (newData) => {
    await queryClient.cancelQueries(['key'])
    const previous = queryClient.getQueryData(['key'])
    queryClient.setQueryData(['key'], newData)
    return { previous }
  },
  onError: (err, vars, ctx) => {
    queryClient.setQueryData(['key'], ctx.previous)
  }
})
```

**When:** User-initiated actions with predictable outcomes
**Avoid:** Complex operations, critical data
```

### Mobile Example
```markdown
## AsyncValue Pattern (mobile)

**Problem:** Handle loading, error, and data states.

**Solution:** Use Riverpod's AsyncValue for all async data.

```dart
final issuesProvider = FutureProvider<List<Issue>>((ref) async {
  return ref.read(issueRepositoryProvider).getIssues();
});

// In widget
ref.watch(issuesProvider).when(
  data: (issues) => IssueList(issues: issues),
  loading: () => const LoadingSpinner(),
  error: (e, _) => ErrorDisplay(error: e),
)
```

**When:** Any async data fetching
**Avoid:** Sync-only operations
```

## Quality Checklist

- [ ] Problem is clear (1 sentence)
- [ ] Code example is minimal but complete
- [ ] When/Avoid guidance provided
- [ ] Follows platform conventions

## Next Steps

After adding pattern:
1. Create ADR if architectural decision: `/add-adr`
2. Update platform CLAUDE.md if new rules
3. Add to relevant feature specs
