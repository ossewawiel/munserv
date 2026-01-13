# TDD Development Workflow

name: "dev-cycle"
description: "Orchestrate full TDD development cycle with quality gates"
parameters:
  - name: "task"
    description: "Description of functionality to add (e.g., 'Add notification provider for issue updates')"
    required: true

---

You are an expert Flutter developer following TDD practices for the MunServ mobile app.

## Task

Implement: "{{task}}"

Follow the TDD development cycle with quality gates at each phase.

---

## PHASE 1: SPECIFY

### Objective
Parse the task into concrete acceptance criteria and identify affected files.

### Actions

1. **Parse Task into Acceptance Criteria**
   - What should the app do?
   - What are the user interactions?
   - What data flows are involved?
   - What edge cases exist?
   - What errors should be handled?

2. **Identify Affected Layers**
   - Domain models to create/modify
   - Providers to create/modify
   - Repositories to create/modify
   - Screens/widgets to create/modify
   - Routes to add/modify

3. **Create TODO List**
   Use TodoWrite to track phases:
   ```
   - [ ] PHASE 2: Write failing tests (provider, repository)
   - [ ] PHASE 3: Implement to pass tests
   - [ ] PHASE 4: Refactor and review
   - [ ] PHASE 5: Quality gate checks
   - [ ] PHASE 6: Widget tests
   - [ ] PHASE 7: Pre-commit verification
   ```

### Exit Condition
- [ ] User approves acceptance criteria
- [ ] Affected files identified
- [ ] TODO list created

---

## PHASE 2: TEST FIRST (Red) - TDD

### Objective
Write failing tests BEFORE writing implementation code.
**This is MANDATORY for providers and repositories.**

### Actions

1. **Write Provider Tests FIRST**
   - Use `test.md` skill with type=provider
   - Test async states (loading, success, error)
   - Test state mutations
   - Run tests → MUST FAIL (no implementation yet)

2. **Write Repository Tests FIRST**
   - Use `test.md` skill with type=repository
   - Mock API client
   - Test Result mapping
   - Run tests → MUST FAIL (no implementation yet)

3. **Run Tests - MUST FAIL**
   ```bash
   flutter test
   ```
   Tests should fail because implementation doesn't exist yet.

### Test Template
```dart
@Test
void should_return_success_when_api_succeeds() async {
  // Arrange
  when(() => mockApi.getAll()).thenAnswer((_) async => [dto]);

  // Act
  final result = await repository.getAll();

  // Assert - this should FAIL
  expect(result, isA<Success<List<Issue>>>());
}
```

### Exit Condition
- [ ] Provider test files created
- [ ] Repository test files created
- [ ] Tests run and FAIL for expected reasons (not compile errors)

---

## PHASE 3: CODE (Green)

### Objective
Write MINIMUM code to make tests pass.

### Actions

1. **Implement Domain Layer** (if needed)
   - Use `model.md` skill for Freezed models
   - Pure Dart, no Flutter dependencies
   - Immutable with copyWith

2. **Implement Repository Layer** (if needed)
   - Use `repository.md` skill
   - Result pattern for error handling
   - DTO → Domain conversion

3. **Implement Provider Layer**
   - Use `provider.md` skill
   - @riverpod annotation
   - Proper error handling

4. **Run Tests - MUST PASS**
   ```bash
   flutter test
   ```

5. **Run Code Generation**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
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
   - Simplify complex logic
   - Add documentation to public APIs
   - Ensure proper error handling

4. **Run Tests Again**
   ```bash
   flutter test
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

1. **Run Analyzer**
   ```bash
   flutter analyze
   ```
   Fix any errors (or run `dart fix --apply`).

2. **Run All Tests**
   ```bash
   flutter test
   ```
   All tests must pass.

3. **Run Formatter**
   ```bash
   dart format lib test
   ```

4. **If Any Fail**
   - Use `ci-fix.md` skill to debug
   - Fix issues and re-run

### Exit Condition
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] `dart format --set-exit-if-changed .` passes

---

## PHASE 6: WIDGET TESTS

### Objective
Add widget tests for new UI components.

### Actions

1. **Write Widget Tests** (if new screens/widgets)
   - Use `widget-test.md` skill
   - Test loading, success, error states
   - Test user interactions

2. **Run Full Test Suite**
   ```bash
   flutter test
   ```

### Exit Condition
- [ ] Widget tests for new screens
- [ ] All tests pass

---

## PHASE 7: PRE-COMMIT

### Objective
Final verification before commit.

### Actions

1. **Full CI Check**
   ```bash
   flutter analyze && flutter test && flutter build apk --debug
   ```

2. **Verify All Passes**
   If any fail, return to appropriate phase:
   - Analyzer fails → Phase 4/5
   - Tests fail → Phase 3/4
   - Build fails → Phase 5

3. **Run Build Runner (if needed)**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Stage Changes**
   ```bash
   git add -A
   git status
   ```

5. **Report Ready**
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
│  5. QUALITY GATE  │ → analyze, test, format
└────────┬──────────┘
         ↓
┌───────────────────┐
│  6. WIDGET TESTS  │ → UI component tests
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
| CODE | model.md, repository.md, provider.md, widget.md, screen.md |
| REFACTOR | review.md |
| QUALITY | ci-fix.md |
| WIDGET TESTS | widget-test.md |
| PRE-COMMIT | ci-fix.md (if needed) |

## Output

Execute each phase sequentially, using appropriate skills.
Report progress using TodoWrite.
Stop and ask for user input at phase transitions if uncertain.
