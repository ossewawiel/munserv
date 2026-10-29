# Code Review for Kotlin/Spring Patterns

name: "review"
description: "Review code for adherence to Kotlin/Spring patterns"
parameters:
  - name: "target"
    description: "File or directory to review (e.g., 'issues/', 'issues/service/IssueService.kt')"
    required: true
  - name: "focus"
    description: "Focus area: all, kotlin, spring, testing, architecture"
    required: false
    default: "all"

---

You are an expert Kotlin developer reviewing code for the MunServ backend.

## Task

Review **{{target}}** for adherence to project patterns and best practices.

## Review Criteria by Severity

### CRITICAL (Must Fix Before Merge)

#### Kotlin
- [ ] Using **var** instead of **val**
- [ ] Using **!!** without null check
- [ ] Using mutable collections (**MutableList**, **MutableMap**) in public APIs
- [ ] Using **Any** type
- [ ] Throwing exceptions for business logic flow

#### Spring Boot
- [ ] Using **@Autowired** on fields (should use constructor injection)
- [ ] Business logic in controllers
- [ ] Exposed domain entities in API responses (should use DTOs)
- [ ] Missing **@Transactional** on mutating service methods

#### Architecture
- [ ] Domain classes with JPA annotations
- [ ] Domain classes importing Spring/JPA packages
- [ ] Cross-module direct repository access
- [ ] Circular dependencies between modules

#### Security
- [ ] Hardcoded secrets or passwords
- [ ] Missing authentication on endpoints
- [ ] SQL injection vulnerabilities
- [ ] Exposing internal errors to API

### HIGH (Should Fix)

#### Kotlin
- [ ] Missing type on public function return
- [ ] Long functions (>30 lines)
- [ ] Deep nesting (>3 levels)
- [ ] Not using **when** for sealed class matching
- [ ] Using **if-else** chains instead of **when**

#### Spring Boot
- [ ] Missing OpenAPI annotations on endpoints
- [ ] Missing validation annotations on DTOs
- [ ] Not handling all Result cases in controller
- [ ] Returning **ResponseEntity<*>** without explicit types

#### Testing
- [ ] Missing tests for domain logic
- [ ] Missing tests for service methods
- [ ] Tests not following AAA pattern
- [ ] Mocking domain classes (should test directly)

#### Architecture
- [ ] Service calling another service's repository
- [ ] Controller with more than 1 dependency
- [ ] Missing Result type for service operations

### MEDIUM (Consider Fixing)

#### Kotlin
- [ ] Not using named parameters for functions with >2 params
- [ ] Not using data classes for DTOs
- [ ] Missing KDoc on public API
- [ ] Using string concatenation instead of templates

#### Spring Boot
- [ ] Missing **@Schema** descriptions on DTO fields
- [ ] Not using appropriate HTTP status codes
- [ ] Verbose logging (too many log statements)

#### Architecture
- [ ] Large files (>300 lines)
- [ ] Missing interface for repository
- [ ] God class (too many responsibilities)

### LOW (Nice to Have)

- [ ] Inconsistent naming conventions
- [ ] Import order not following convention
- [ ] Missing blank lines between functions
- [ ] Verbose code that could be simplified

## Best Practices Checklist

### Kotlin Patterns

```kotlin
// ✅ GOOD - val and immutability
val issue = repository.findById(id)
val updated = issue.copy(state = newState)

// ❌ BAD - var and mutation
var issue = repository.findById(id)
issue.state = newState
```

```kotlin
// ✅ GOOD - Safe null handling
val issue = repository.findById(id)
    ?: return IssueResult.NotFound(id)

// ❌ BAD - Force unwrap
val issue = repository.findById(id)!!
```

```kotlin
// ✅ GOOD - Sealed result
sealed interface IssueResult {
    data class Success(val issue: Issue) : IssueResult
    data class NotFound(val id: IssueId) : IssueResult
}

// ❌ BAD - Throwing exceptions
fun findById(id: IssueId): Issue {
    return repository.findById(id)
        ?: throw NotFoundException("Issue not found")
}
```

### Spring Boot Patterns

```kotlin
// ✅ GOOD - Constructor injection
@Service
class IssueService(
    private val repository: IssueRepository,
    private val clock: Clock,
)

// ❌ BAD - Field injection
@Service
class IssueService {
    @Autowired
    private lateinit var repository: IssueRepository
}
```

```kotlin
// ✅ GOOD - Handle all Result cases
when (val result = service.findById(id)) {
    is IssueResult.Success -> ResponseEntity.ok(result.issue.toResponse())
    is IssueResult.NotFound -> ResponseEntity.notFound().build()
    is IssueResult.ValidationError -> ResponseEntity.badRequest().body(result.errors)
    is IssueResult.Unauthorized -> ResponseEntity.status(403).build()
}

// ❌ BAD - Using else
when (val result = service.findById(id)) {
    is IssueResult.Success -> ResponseEntity.ok(result.issue.toResponse())
    else -> ResponseEntity.internalServerError().build()
}
```

### Architecture Patterns

```kotlin
// ✅ GOOD - Domain entity (pure)
data class Issue(
    val id: IssueId,
    val state: IssueState,
) {
    fun canTransitionTo(newState: IssueState) = state.canTransitionTo(newState)
}

// ❌ BAD - Domain with JPA
@Entity
data class Issue(
    @Id val id: UUID,
    val state: String,
)
```

## Output Format

For each issue found, report in this format:

```markdown
## Code Review Report for {{target}}

### Summary
- CRITICAL: X issues
- HIGH: X issues
- MEDIUM: X issues
- LOW: X issues

### CRITICAL Issues

1. **[kotlin/no-force-unwrap]** Line 42: Using **!!** operator
   - File: src/main/kotlin/.../Service.kt:42
   - Current: **val issue = repository.findById(id)!!**
   - Fix: Use elvis operator with Result return

### HIGH Issues

1. **[spring/missing-transactional]** Line 55: Missing @Transactional
   - File: src/main/kotlin/.../Service.kt:55
   - Method: **updateState()**
   - Fix: Add **@Transactional** annotation

### Recommendations

1. Consider extracting X to a separate function
2. Add tests for Y scenario
```

## Output

1. Read all files in **{{target}}**
2. Check against all criteria for **{{focus}}** area
3. Report issues by severity
4. Provide specific fix recommendations
