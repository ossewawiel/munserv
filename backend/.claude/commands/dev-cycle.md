# TDD Development Workflow

name: "dev-cycle"
description: "Orchestrate full TDD development cycle with quality gates"
parameters:
  - name: "task"
    description: "Description of functionality to add (e.g., 'Add notification service for issue state changes')"
    required: true

---

You are an expert software developer following strict TDD practices for the MunServ backend.

## Task

Implement: "{{task}}"

Follow the TDD development cycle with quality gates at each phase.

---

## PHASE 1: SPECIFY

### Objective
Parse the task into concrete acceptance criteria and identify affected files.

### Actions

1. **Parse Task into Acceptance Criteria**
   - What should the system do?
   - What are the inputs/outputs?
   - What edge cases exist?
   - What errors should be handled?

2. **Identify Affected Layers**
   - Domain entities to create/modify
   - Services to create/modify
   - Repositories to create/modify
   - Controllers/endpoints to create/modify
   - Database migrations needed

3. **Create TODO List**
   Use TodoWrite to track phases:
   ```
   - [ ] PHASE 2: Write failing tests (domain, service)
   - [ ] PHASE 3: Implement to pass tests
   - [ ] PHASE 4: Refactor and review
   - [ ] PHASE 5: Quality gate checks
   - [ ] PHASE 6: Integration tests
   - [ ] PHASE 7: Pre-commit verification
   ```

### Exit Condition
- [ ] User approves acceptance criteria
- [ ] Affected files identified
- [ ] TODO list created

---

## PHASE 2: TEST FIRST (Red) - STRICT TDD

### Objective
Write failing tests BEFORE writing implementation code.
**This is MANDATORY for domain and service layers.**

### Actions

1. **Write Domain Tests FIRST**
   - Use `test.md` skill with type=domain
   - Test entity behavior and state transitions
   - Test value object validation
   - Run tests → MUST FAIL (no implementation yet)

2. **Write Service Tests FIRST**
   - Use `test.md` skill with type=service
   - Mock repository and dependencies
   - Test all Result cases
   - Run tests → MUST FAIL (no implementation yet)

3. **Run Tests - MUST FAIL**
   ```bash
   ./gradlew test
   ```
   Tests should fail because implementation doesn't exist yet.

### Test Template
```kotlin
@Test
fun `should do X when Y`() {
    // Arrange
    val input = createTestInput()

    // Act
    val result = service.doSomething(input)

    // Assert - this should FAIL
    result.shouldBeInstanceOf<Result.Success>()
}
```

### Exit Condition
- [ ] Domain test files created
- [ ] Service test files created
- [ ] Tests run and FAIL for expected reasons (not compile errors)

---

## PHASE 3: CODE (Green)

### Objective
Write MINIMUM code to make tests pass.

### Actions

1. **Implement Domain Layer** (if needed)
   - Use `entity.md` skill for entities/value objects
   - Pure Kotlin, no framework dependencies
   - Immutable data classes

2. **Implement Repository Layer** (if needed)
   - Use `repository.md` skill
   - JPA annotations only on Entity class
   - Domain ↔ JPA conversion

3. **Implement Service Layer**
   - Use `service.md` skill
   - Sealed Result pattern
   - Constructor injection

4. **Run Tests - MUST PASS**
   ```bash
   ./gradlew test
   ```

### Key Principles
- Write only what's needed to pass tests
- Don't add extra features
- Don't optimize prematurely

### Exit Condition
- [ ] All new tests pass
- [ ] No regressions (existing tests still pass)

---

## PHASE 4: REFACTOR (Clean)

### Objective
Improve code quality while keeping tests green.

### Actions

1. **Run Code Review**
   ```
   Use review.md skill on changed files
   ```

2. **Fix Issues by Severity**
   - CRITICAL: Fix immediately
   - HIGH: Fix before continuing
   - MEDIUM: Consider fixing
   - LOW: Optional

3. **Apply Best Practices**
   - Extract reusable code
   - Simplify complex logic (early returns)
   - Add KDoc to public APIs
   - Ensure proper error handling

4. **Run Tests Again**
   ```bash
   ./gradlew test
   ```
   Tests must still pass!

### Exit Condition
- [ ] No CRITICAL or HIGH issues remain
- [ ] All tests still pass
- [ ] Code follows project patterns

---

## PHASE 5: QUALITY GATE

### Objective
Pass all automated quality checks.

### Actions

1. **Run ktlint**
   ```bash
   ./gradlew ktlintCheck
   ```
   Fix any errors (or run `./gradlew ktlintFormat`).

2. **Run All Tests**
   ```bash
   ./gradlew test
   ```
   All tests must pass.

3. **Run SonarQube Analysis** (if available)
   ```
   Use sonar.md skill with scope=changed
   ```

4. **If Any Fail**
   - Use `ci-fix.md` skill to debug
   - Fix issues and re-run

### Exit Condition
- [ ] `./gradlew ktlintCheck` passes
- [ ] `./gradlew test` passes
- [ ] SonarQube quality gate passes (if available)

---

## PHASE 6: INTEGRATION

### Objective
Add integration and contract tests for new functionality.

### Actions

1. **Write API Contract Tests** (if new endpoints)
   - Use `contract-test.md` skill
   - Test all HTTP status codes
   - Test with/without authentication

2. **Write Repository Integration Tests** (if new repository methods)
   - Use `integration-test.md` skill with type=repository
   - Test with real database (TestContainers)

3. **Write Scenario Tests** (if major feature)
   - Use `integration-test.md` skill with type=scenario
   - Test end-to-end workflow

4. **Run Full Test Suite**
   ```bash
   ./gradlew test
   ```

### Exit Condition
- [ ] Contract tests for new endpoints
- [ ] Integration tests for new repository methods
- [ ] All tests pass

---

## PHASE 7: PRE-COMMIT

### Objective
Final verification before commit.

### Actions

1. **Full CI Check**
   ```bash
   ./gradlew ktlintCheck && ./gradlew test && ./gradlew build
   ```

2. **Verify All Passes**
   If any fail, return to appropriate phase:
   - ktlint fails → Phase 4/5
   - Tests fail → Phase 3/4
   - Build fails → Phase 5

3. **Stage Changes**
   ```bash
   git add -A
   git status
   ```

4. **Report Ready**
   ```
   ✅ Ready for commit
   - Files changed: X
   - Tests added: Y
   - Quality gate: PASSED
   ```

### Exit Condition
- [ ] Full CI check passes
- [ ] All changes staged
- [ ] Ready for commit message

---

## WORKFLOW SUMMARY

```
┌───────────────────┐
│  1. SPECIFY       │ → Define acceptance criteria
└────────┬──────────┘
         ↓
┌───────────────────┐
│  2. TEST (Red)    │ → Write failing tests FIRST
└────────┬──────────┘
         ↓
┌───────────────────┐
│  3. CODE (Green)  │ → Make tests pass
└────────┬──────────┘
         ↓
┌───────────────────┐
│  4. REFACTOR      │ → Clean up, fix review issues
└────────┬──────────┘
         ↓
┌───────────────────┐
│  5. QUALITY GATE  │ → ktlint, tests, sonar
└────────┬──────────┘
         ↓
┌───────────────────┐
│  6. INTEGRATION   │ → Contract + integration tests
└────────┬──────────┘
         ↓
┌───────────────────┐
│  7. PRE-COMMIT    │ → Final verification
└───────────────────┘
```

## Skills Used in Each Phase

| Phase | Skills Used |
|-------|-------------|
| SPECIFY | - |
| TEST | test.md |
| CODE | entity.md, service.md, repository.md, controller.md |
| REFACTOR | review.md |
| QUALITY | sonar.md, ci-fix.md |
| INTEGRATION | contract-test.md, integration-test.md |
| PRE-COMMIT | ci-fix.md (if needed) |

## Output

Execute each phase sequentially, using appropriate skills.
Report progress using TodoWrite.
Stop and ask for user input at phase transitions if uncertain.
