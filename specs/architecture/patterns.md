# Code Patterns

> **Full examples**: See [Architecture_and_Design_Patterns.md](../Architecture_and_Design_Patterns.md) for comprehensive patterns with detailed code.

## Backend Patterns

### Sealed Result
**Problem:** Type-safe error handling without exceptions.

```kotlin
sealed class Result<out T, out E> {
    data class Success<T>(val value: T) : Result<T, Nothing>()
    data class Failure<E>(val error: E) : Result<Nothing, E>()
}

fun findMember(id: MemberId): Result<Member, MemberError> =
    repository.findById(id)?.let { Result.Success(it) }
        ?: Result.Failure(MemberError.NotFound(id))
```

**When:** Service methods, repository operations

### Value Objects
**Problem:** Type-safe IDs prevent mixing up identifiers.

```kotlin
@JvmInline
value class MemberId(val value: UUID)

@JvmInline
value class IssueId(val value: UUID)
```

**When:** All entity identifiers

---

## Mobile Patterns

### AsyncValue
**Problem:** Handle loading, error, and data states consistently.

```dart
ref.watch(issuesProvider).when(
  data: (issues) => IssueList(issues: issues),
  loading: () => const LoadingSpinner(),
  error: (e, _) => ErrorDisplay(error: e),
)
```

**When:** Any async data fetching

### Freezed Models
**Problem:** Immutable data classes with copy methods.

```dart
@freezed
class Issue with _$Issue {
  const factory Issue({
    required IssueId id,
    required String title,
    required IssueState state,
  }) = _Issue;
}
```

**When:** All domain models

---

## Web Patterns

### React Query Hooks
**Problem:** Server state management with caching.

```typescript
export const useIssues = (filters?: IssueFilters) => {
  return useQuery({
    queryKey: ['issues', filters],
    queryFn: () => api.getIssues(filters),
  })
}
```

**When:** All data fetching

### Optimistic Updates
**Problem:** UI feels slow waiting for server.

```typescript
const mutation = useMutation({
  onMutate: async (newData) => {
    const previous = queryClient.getQueryData(['key'])
    queryClient.setQueryData(['key'], newData)
    return { previous }
  },
  onError: (_, __, ctx) => {
    queryClient.setQueryData(['key'], ctx.previous)
  }
})
```

**When:** User-initiated actions with predictable outcomes
