# TDD Development Workflow

name: "dev-cycle"
description: "Orchestrate full TDD development cycle with quality gates"
parameters:
  - name: "task"
    description: "Description of functionality to add (e.g., 'Add sector filter dropdown to issues page')"
    required: true

---

You are an expert software developer following strict TDD practices for the MunServ web admin portal.

## Task

Implement: "{{task}}"

Follow the TDD development cycle with quality gates at each phase.

---

## PHASE 1: SPECIFY

### Objective
Parse the task into concrete acceptance criteria and identify affected files.

### Actions

1. **Parse Task into Acceptance Criteria**
   - What should the user be able to do?
   - What should they see?
   - What edge cases exist?

2. **Identify Affected Areas**
   - Components to create/modify
   - Hooks to create/modify
   - API endpoints needed
   - Types to define

3. **Create TODO List**
   Use TodoWrite to track phases:
   ```
   - [ ] PHASE 2: Write failing tests
   - [ ] PHASE 3: Implement to pass tests
   - [ ] PHASE 4: Refactor and review
   - [ ] PHASE 5: Quality gate checks
   - [ ] PHASE 6: Documentation
   - [ ] PHASE 7: Pre-commit verification
   ```

### Exit Condition
- [ ] User approves acceptance criteria
- [ ] Affected files identified
- [ ] TODO list created

---

## PHASE 2: TEST FIRST (Red)

### Objective
Write failing tests BEFORE writing implementation code.

### Actions

1. **Write Unit Tests**
   - Use `test.md` skill for component/hook tests
   - Create test file next to target file
   - Test expected behavior, not implementation

2. **Add MSW Handlers** (if API involved)
   - Add handlers to `src/test/mocks/handlers.ts`
   - Mock expected API responses

3. **Write E2E Test** (optional for major features)
   - Use `e2e.md` skill
   - Test user flow end-to-end

4. **Run Tests - MUST FAIL**
   ```bash
   pnpm test:run
   ```
   Tests should fail because implementation doesn't exist yet.

### Test Template
```typescript
describe('{{FeatureName}}', () => {
  it('should do X when Y', () => {
    // Arrange
    // Act
    // Assert - this should FAIL
  });
});
```

### Exit Condition
- [ ] Test files created
- [ ] Tests run and FAIL for expected reasons
- [ ] MSW handlers added (if needed)

---

## PHASE 3: CODE (Green)

### Objective
Write MINIMUM code to make tests pass.

### Actions

1. **Implement Types** (if needed)
   - Use `feature.md` or add to existing types.ts

2. **Implement API** (if needed)
   - Use `api.md` skill

3. **Implement Hooks** (if needed)
   - Use `hook.md` skill

4. **Implement Components**
   - Use `component.md` skill
   - Follow atomic design levels

5. **Run Tests - MUST PASS**
   ```bash
   pnpm test:run
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
   - Extract reusable hooks
   - Split large components (>200 lines)
   - Add proper memoization
   - Fix import order

4. **Run Tests Again**
   ```bash
   pnpm test:run
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

1. **Run Lint**
   ```bash
   pnpm lint
   ```
   Fix any errors.

2. **Run TypeCheck**
   ```bash
   pnpm typecheck
   ```
   Fix any type errors.

3. **Run All Tests**
   ```bash
   pnpm test:run
   ```
   All tests must pass.

4. **Run SonarQube Analysis** (if available)
   ```
   Use sonar.md skill with scope=changed
   ```

5. **If Any Fail**
   - Use `ci-fix.md` skill to debug
   - Fix issues and re-run

### Exit Condition
- [ ] `pnpm lint` passes
- [ ] `pnpm typecheck` passes
- [ ] `pnpm test:run` passes
- [ ] SonarQube quality gate passes (if available)

---

## PHASE 6: DOCUMENT

### Objective
Update documentation and translations.

### Actions

1. **Add i18n Keys** (if new UI text)
   ```
   Use i18n.md skill
   ```

2. **Update Types** with JSDoc (if complex)
   ```typescript
   /**
    * Filters issues by sector.
    * @param sectorId - The sector to filter by
    * @returns Filtered list of issues
    */
   ```

3. **Update Feature README** (if major feature)
   - Document usage patterns
   - Note any configuration needed

4. **Verify CLAUDE.md Patterns**
   - Ensure new code follows documented patterns
   - Update CLAUDE.md if new patterns introduced

### Exit Condition
- [ ] i18n keys added (if needed)
- [ ] Complex functions documented
- [ ] Patterns consistent with CLAUDE.md

---

## PHASE 7: PRE-COMMIT

### Objective
Final verification before commit.

### Actions

1. **Full CI Check**
   ```bash
   pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
   ```

2. **Verify All Passes**
   If any fail, return to appropriate phase:
   - Lint fails → Phase 4/5
   - TypeCheck fails → Phase 5
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
│  2. TEST (Red)    │ → Write failing tests
└────────┬──────────┘
         ↓
┌───────────────────┐
│  3. CODE (Green)  │ → Make tests pass
└────────┬──────────┘
         ↓
┌───────────────────┐
│  4. REFACTOR      │ → Clean up, fix issues
└────────┬──────────┘
         ↓
┌───────────────────┐
│  5. QUALITY GATE  │ → lint, typecheck, test, sonar
└────────┬──────────┘
         ↓
┌───────────────────┐
│  6. DOCUMENT      │ → i18n, JSDoc, README
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
| TEST | test.md, e2e.md |
| CODE | component.md, hook.md, api.md, feature.md, form.md, page.md |
| REFACTOR | review.md |
| QUALITY | sonar.md, ci-fix.md |
| DOCUMENT | i18n.md |
| PRE-COMMIT | ci-fix.md (if needed) |

## Output

Execute each phase sequentially, using appropriate skills.
Report progress using TodoWrite.
Stop and ask for user input at phase transitions if uncertain.
