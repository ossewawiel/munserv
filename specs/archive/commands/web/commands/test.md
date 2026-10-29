# Vitest Test Generator

name: "test"
description: "Generate Vitest test file for component, hook, or utility"
parameters:
  - name: "target"
    description: "File path to test (e.g., src/components/atoms/Button.tsx)"
    required: true
  - name: "type"
    description: "Test type: component, hook, util"
    required: true

---

You are an expert React developer creating Vitest tests for the MunServ web admin portal.

## Task

Generate a test file for `{{target}}` following testing best practices.

## Test File Location

| Target Type | Test File Location |
|-------------|-------------------|
| component | Same directory as component: `Button.test.tsx` |
| hook | Same directory as hook: `hooks.test.ts` |
| util | Same directory as util: `utils.test.ts` |

## Best Practices (ENFORCED)

### Testing Library Query Priority
1. `getByRole` - accessible roles (button, heading, textbox)
2. `getByLabelText` - form inputs with labels
3. `getByPlaceholderText` - inputs with placeholder
4. `getByText` - non-interactive text
5. `getByTestId` - LAST RESORT only

### Test Structure (AAA)
```typescript
it('should do something', () => {
  // Arrange - set up test data and render
  const onAction = vi.fn();
  render(<Component onAction={onAction} />);

  // Act - perform user action
  fireEvent.click(screen.getByRole('button', { name: /submit/i }));

  // Assert - verify outcome
  expect(onAction).toHaveBeenCalledOnce();
});
```

### Async Testing
```typescript
it('should load data', async () => {
  render(<Component />);

  // Use waitFor for async assertions
  await waitFor(() => {
    expect(screen.getByText('Loaded data')).toBeInTheDocument();
  });

  // Or use findBy queries (async by default)
  const element = await screen.findByRole('heading');
  expect(element).toHaveTextContent('Title');
});
```

## Component Test Template

```typescript
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { vi, describe, it, expect, beforeEach } from 'vitest';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { {{ComponentName}} } from './{{ComponentName}}';

// Create test query client
const createTestQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false },
    },
  });

// Wrapper with providers
const renderWithProviders = (ui: React.ReactElement) => {
  const queryClient = createTestQueryClient();
  return render(
    <QueryClientProvider client={queryClient}>
      {ui}
    </QueryClientProvider>
  );
};

describe('{{ComponentName}}', () => {
  const defaultProps = {
    // Add default props
  };

  it('should render correctly', () => {
    render(<{{ComponentName}} {...defaultProps} />);

    expect(screen.getByRole('...')).toBeInTheDocument();
  });

  it('should handle user interaction', async () => {
    const onAction = vi.fn();
    render(<{{ComponentName}} {...defaultProps} onAction={onAction} />);

    await fireEvent.click(screen.getByRole('button', { name: /action/i }));

    expect(onAction).toHaveBeenCalledWith(expect.objectContaining({
      // expected payload
    }));
  });

  it('should display loading state', () => {
    render(<{{ComponentName}} {...defaultProps} isLoading />);

    expect(screen.getByRole('progressbar')).toBeInTheDocument();
  });

  it('should display error state', () => {
    render(<{{ComponentName}} {...defaultProps} error="Something went wrong" />);

    expect(screen.getByText(/something went wrong/i)).toBeInTheDocument();
  });
});
```

## Hook Test Template

```typescript
import { renderHook, waitFor } from '@testing-library/react';
import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { http, HttpResponse } from 'msw';
import { server } from '@/test/mocks/server';
import { use{{HookName}} } from './hooks';

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
    },
  });
  return ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );
};

describe('use{{HookName}}', () => {
  it('should fetch data successfully', async () => {
    // Arrange - MSW already has default handlers
    const { result } = renderHook(() => use{{HookName}}(), {
      wrapper: createWrapper(),
    });

    // Assert initial loading state
    expect(result.current.isLoading).toBe(true);

    // Wait for success
    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true);
    });

    // Assert data
    expect(result.current.data).toBeDefined();
    expect(result.current.data).toHaveLength(1);
  });

  it('should handle error response', async () => {
    // Arrange - override handler for this test
    server.use(
      http.get('/api/v1/{{endpoint}}', () =>
        HttpResponse.json({ message: 'Server error' }, { status: 500 })
      )
    );

    const { result } = renderHook(() => use{{HookName}}(), {
      wrapper: createWrapper(),
    });

    // Wait for error
    await waitFor(() => {
      expect(result.current.isError).toBe(true);
    });

    expect(result.current.error).toBeDefined();
  });

  it('should not fetch when disabled', () => {
    const { result } = renderHook(() => use{{HookName}}(undefined), {
      wrapper: createWrapper(),
    });

    // Should not be loading when disabled
    expect(result.current.isLoading).toBe(false);
    expect(result.current.fetchStatus).toBe('idle');
  });
});
```

## Utility Test Template

```typescript
import { describe, it, expect } from 'vitest';
import { {{utilFunction}} } from './{{utilFile}}';

describe('{{utilFunction}}', () => {
  it('should handle normal input', () => {
    const result = {{utilFunction}}(normalInput);
    expect(result).toBe(expectedOutput);
  });

  it('should handle edge case: empty input', () => {
    const result = {{utilFunction}}('');
    expect(result).toBe('');
  });

  it('should handle edge case: null/undefined', () => {
    expect(() => {{utilFunction}}(null)).toThrow();
    // or
    expect({{utilFunction}}(undefined)).toBeUndefined();
  });

  it('should handle edge case: special characters', () => {
    const result = {{utilFunction}}('test<script>');
    expect(result).toBe('test&lt;script&gt;');
  });
});
```

## MSW Handler Override

For specific test scenarios:

```typescript
import { http, HttpResponse } from 'msw';
import { server } from '@/test/mocks/server';

it('should handle empty list', async () => {
  server.use(
    http.get('/api/v1/issues', () =>
      HttpResponse.json({ items: [], total: 0, page: 1, limit: 20 })
    )
  );

  render(<IssueList />);

  await waitFor(() => {
    expect(screen.getByText(/no issues found/i)).toBeInTheDocument();
  });
});
```

## Output

1. Read the target file to understand its interface
2. Generate test file in the same directory
3. Include tests for: happy path, error states, edge cases, user interactions
4. Use proper Testing Library queries (role > label > text > testid)
5. Add MSW handler overrides if needed for specific scenarios
