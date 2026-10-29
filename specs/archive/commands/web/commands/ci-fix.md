# CI/CD Failure Debugger

name: "ci-fix"
description: "Debug CI/CD failures for web project (lint, typecheck, test, build)"
parameters:
  - name: "error_type"
    description: "Failure type: lint, typecheck, test, build, all"
    required: true
  - name: "error_log"
    description: "Paste error output or path to log file"
    required: false

---

You are an expert developer debugging CI/CD failures for the MunServ web admin portal.

## Task

Debug and fix `{{error_type}}` failure(s) in the web project CI/CD pipeline.

## CI Commands Reference

```bash
pnpm lint          # ESLint check
pnpm typecheck     # TypeScript strict check
pnpm test:run      # Vitest single run
pnpm build         # Vite production build
```

## Debugging by Error Type

### Lint Failures (ESLint)

**Run locally:**
```bash
pnpm lint
# or with auto-fix
pnpm lint --fix
```

**Common ESLint Errors:**

#### React Hooks Rules
```
error  React Hook useEffect has missing dependencies  react-hooks/exhaustive-deps
```
**Fix:** Add missing dependencies or use `// eslint-disable-next-line` with comment

```typescript
// Before
useEffect(() => {
  fetchData(id);
}, []); // Missing 'id' dependency

// After
useEffect(() => {
  fetchData(id);
}, [id]);

// Or if intentional
useEffect(() => {
  fetchData(id);
  // eslint-disable-next-line react-hooks/exhaustive-deps
}, []); // Only run on mount
```

#### Unused Variables
```
error  'unusedVar' is defined but never used  @typescript-eslint/no-unused-vars
```
**Fix:** Remove or prefix with underscore

```typescript
// Before
const unusedVar = getValue();

// After (if needed for destructuring)
const _unusedVar = getValue();
// or remove entirely
```

#### Import Order
```
error  Import order issues  import/order
```
**Fix:** Follow project import order (React → third-party → MUI → @/ → relative)

### TypeCheck Failures (TypeScript)

**Run locally:**
```bash
pnpm typecheck
```

**Common TypeScript Errors:**

#### Missing Types
```
error TS7006: Parameter 'x' implicitly has an 'any' type.
```
**Fix:** Add explicit type

```typescript
// Before
const handler = (data) => { ... };

// After
const handler = (data: SomeType) => { ... };
```

#### Unused Locals
```
error TS6133: 'x' is declared but its value is never read.
```
**Fix:** Remove or prefix with underscore

```typescript
// Before
const unusedValue = compute();

// After
const _unusedValue = compute(); // if needed
// or remove
```

#### Type Mismatch
```
error TS2322: Type 'string' is not assignable to type 'number'.
```
**Fix:** Correct the type or add type assertion

```typescript
// Check the expected type and fix the assignment
const value: number = parseInt(stringValue, 10);
```

#### Missing Properties
```
error TS2339: Property 'x' does not exist on type 'Y'.
```
**Fix:** Add property to interface or use optional chaining

```typescript
// Add to interface
interface Y {
  x: string;
}

// Or use optional chaining
const value = obj?.x;
```

### Test Failures (Vitest)

**Run locally:**
```bash
pnpm test:run
# or with verbose output
pnpm test:run --reporter=verbose
```

**Common Test Failures:**

#### Async Timeout
```
Error: Test timed out
```
**Fix:** Increase timeout or fix async handling

```typescript
// Add timeout
it('should do async thing', async () => {
  // ...
}, 10000); // 10 second timeout

// Or use proper waitFor
await waitFor(() => {
  expect(result).toBe(expected);
}, { timeout: 5000 });
```

#### Missing Provider
```
Error: useQuery must be used within QueryClientProvider
```
**Fix:** Wrap with providers in test

```typescript
const wrapper = ({ children }) => (
  <QueryClientProvider client={queryClient}>
    {children}
  </QueryClientProvider>
);

render(<Component />, { wrapper });
```

#### MSW Handler Missing
```
Error: Request handler not found for GET /api/...
```
**Fix:** Add handler in `src/test/mocks/handlers.ts`

```typescript
http.get('/api/missing-endpoint', () =>
  HttpResponse.json({ data: [] })
),
```

### Build Failures (Vite)

**Run locally:**
```bash
pnpm build
```

**Common Build Errors:**

#### Module Not Found
```
Error: Cannot find module './Component'
```
**Fix:** Check file path and extension

```typescript
// Check if file exists
// Check if path is correct (case-sensitive)
// Check if using correct extension (.ts vs .tsx)
```

#### Path Alias Not Resolved
```
Error: Cannot find module '@/shared/...'
```
**Fix:** Verify tsconfig path aliases match vite.config.ts

```typescript
// vite.config.ts
resolve: {
  alias: {
    '@': path.resolve(__dirname, './src'),
  },
},

// tsconfig.json
"paths": {
  "@/*": ["./src/*"]
}
```

#### Circular Dependency
```
Warning: Circular dependency detected
```
**Fix:** Refactor to break the cycle

```typescript
// Move shared types to a separate file
// Use dependency injection
// Lazy load modules
```

## Quick Fix Workflow

1. **Identify error type** from CI log
2. **Run locally** to reproduce
3. **Apply fix** based on patterns above
4. **Verify fix** by re-running command
5. **Commit and push**

## Full CI Check Before Commit

```bash
# Run all checks
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```

## Output

1. **Parse** error log to identify failure type
2. **Reproduce** locally with appropriate command
3. **Diagnose** root cause using patterns above
4. **Fix** the issue
5. **Verify** fix passes locally
6. **Report** what was fixed
