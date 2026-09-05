---
name: web-patterns
description: Full React 19 + TypeScript + MUI 9 + React Query patterns for the MunServ web portal - type definitions, query and mutation hooks, atom/molecule/organism/page components, the API layer, hook practices, Vitest/RTL/MSW and Playwright tests, import order and TypeScript rules. Load when writing or reviewing web code beyond what web/CLAUDE.md covers.
---

# Web patterns

The core rules live in `web/CLAUDE.md`. This skill is the worked-example catalogue.
MUI 9 note: props such as `InputProps`, `PaperProps` and `TransitionProps` are gone; use `slotProps.*`. System props (`mt={2}`) are gone; use `sx`. Grid uses `size={{ xs, sm, md }}`.

## Type Definitions

```typescript
// Domain types
interface Issue {
  id: string;
  sectorId: string;
  type: IssueType;
  state: IssueState;
  location: GeoPoint;
  heat: number;
  reportedAt: string;
}

// Union types for fixed values
type IssueState =
  | 'reported'
  | 'confirmed'
  | 'in_progress'
  | 'fixed'
  | 'rejected'
  | 'reopened';

type IssueType =
  | 'pothole'
  | 'water_leak'
  | 'sewerage_leak'
  | 'traffic_light'
  | 'street_light'
  | 'illegal_dumping'
  | 'graffiti'
  | 'other';

// Component props
interface IssueCardProps {
  issue: Issue;
  onSelect?: (issue: Issue) => void;
}

// API response types
interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
}
```

## React Query Patterns

### Query Hook
```typescript
import { useQuery } from '@tanstack/react-query';
import { issueApi } from './api';

export function useIssues(sectorId: string) {
  return useQuery({
    queryKey: ['issues', sectorId],
    queryFn: () => issueApi.getBySector(sectorId),
  });
}

export function useIssue(id: string) {
  return useQuery({
    queryKey: ['issues', id],
    queryFn: () => issueApi.getById(id),
    enabled: !!id,  // Don't fetch if no id
  });
}
```

### Mutation Hook
```typescript
import { useMutation, useQueryClient } from '@tanstack/react-query';

export function useUpdateIssueState() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, state }: { id: string; state: IssueState }) =>
      issueApi.updateState(id, state),
    onSuccess: (data, { id }) => {
      // Update cache
      queryClient.setQueryData(['issues', id], data);
      // Invalidate list
      queryClient.invalidateQueries({ queryKey: ['issues'] });
    },
  });
}
```

### Usage in Component
```typescript
function IssueDetailPage() {
  const { id } = useParams<{ id: string }>();
  const { data: issue, isLoading, error } = useIssue(id!);
  const updateState = useUpdateIssueState();

  if (isLoading) return <LoadingSpinner />;
  if (error) return <ErrorDisplay error={error} />;
  if (!issue) return <NotFound />;

  const handleStateChange = (newState: IssueState) => {
    updateState.mutate({ id: issue.id, state: newState });
  };

  return (
    <DashboardLayout>
      <IssueDetail issue={issue} onStateChange={handleStateChange} />
    </DashboardLayout>
  );
}
```

## Component Patterns

### Atom (MUI Wrapper)
```typescript
import { type FC } from 'react';
import MuiButton, { type ButtonProps as MuiButtonProps } from '@mui/material/Button';
import CircularProgress from '@mui/material/CircularProgress';

type ButtonVariant = 'primary' | 'secondary' | 'danger' | 'ghost';

interface ButtonProps extends Omit<MuiButtonProps, 'variant' | 'color'> {
  variant?: ButtonVariant;
  isLoading?: boolean;
}

export const Button: FC<ButtonProps> = ({
  variant = 'primary',
  isLoading = false,
  children,
  disabled,
  ...props
}) => {
  const muiProps = variantMap[variant];

  return (
    <MuiButton
      {...muiProps}
      disabled={disabled || isLoading}
      startIcon={isLoading ? <CircularProgress size={16} /> : undefined}
      {...props}
    >
      {isLoading ? 'Loading...' : children}
    </MuiButton>
  );
};
```

### Molecule (Combined Atoms)
```typescript
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';

interface IssueCardProps {
  issue: Issue;
  onSelect?: (issue: Issue) => void;
}

export const IssueCard: FC<IssueCardProps> = ({ issue, onSelect }) => {
  return (
    <Box
      sx={{
        p: 2,
        border: 1,
        borderColor: 'divider',
        borderRadius: 2,
        cursor: 'pointer',
        '&:hover': { bgcolor: 'action.hover' },
      }}
      onClick={() => onSelect?.(issue)}
    >
      <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
        <IssueTypeBadge type={issue.type} />
        <IssueStateBadge state={issue.state} />
      </Box>
      <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
        {issue.type}
      </Typography>
      <HeatIndicator heat={issue.heat} />
    </Box>
  );
};
```

### Organism (Complex Section)
```typescript
import Box from '@mui/material/Box';
import Grid from '@mui/material/Grid';

interface IssueListProps {
  sectorId: string;
}

export const IssueList: FC<IssueListProps> = ({ sectorId }) => {
  const { data: issues, isLoading, error } = useIssues(sectorId);
  const [filter, setFilter] = useState<IssueState | 'all'>('all');

  const filteredIssues = useMemo(() => {
    if (filter === 'all') return issues ?? [];
    return issues?.filter(i => i.state === filter) ?? [];
  }, [issues, filter]);

  if (isLoading) return <IssueListSkeleton />;
  if (error) return <ErrorDisplay error={error} />;

  return (
    <Box>
      <IssueFilters value={filter} onChange={setFilter} />
      <Grid container spacing={2} sx={{ mt: 2 }}>
        {filteredIssues.map(issue => (
          <Grid size={{ xs: 12, sm: 6, md: 4 }} key={issue.id}>
            <IssueCard issue={issue} />
          </Grid>
        ))}
      </Grid>
    </Box>
  );
};
```

### Page (Route Entry)
```typescript
export default function IssuesPage() {
  const { sectorId } = useParams<{ sectorId: string }>();

  if (!sectorId) return <Navigate to="/sectors" />;

  return (
    <DashboardLayout>
      <PageHeader title="Issues" />
      <IssueList sectorId={sectorId} />
    </DashboardLayout>
  );
}
```

## API Layer

```typescript
// lib/api-client.ts
import axios from 'axios';

export const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
  headers: { 'Content-Type': 'application/json' },
});

apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// features/issues/api.ts
export const issueApi = {
  getAll: () =>
    apiClient.get<Issue[]>('/v1/issues').then(r => r.data),

  getBySector: (sectorId: string) =>
    apiClient.get<Issue[]>(`/v1/sectors/${sectorId}/issues`).then(r => r.data),

  getById: (id: string) =>
    apiClient.get<Issue>(`/v1/issues/${id}`).then(r => r.data),

  updateState: (id: string, state: IssueState) =>
    apiClient.patch<Issue>(`/v1/issues/${id}/state`, { state }).then(r => r.data),
};
```

## Hooks Best Practices

```typescript
// ✅ useMemo for expensive computations
const sortedIssues = useMemo(
  () => [...issues].sort((a, b) => b.heat - a.heat),
  [issues]
);

// ✅ useCallback for handlers passed to children
const handleSelect = useCallback((issue: Issue) => {
  setSelectedId(issue.id);
}, []);

// ✅ Custom hooks for reusable logic
function useDebounce<T>(value: T, delay: number): T {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const timer = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(timer);
  }, [value, delay]);
  return debounced;
}

// ❌ Don't use useEffect for data fetching
// ❌ Don't use useState for server state
```

## Testing (Vitest + RTL + MSW)

### Test Setup
Tests use Vitest with JSDOM. MSW mocks API calls.
- Setup file: `src/test/setup.ts`
- Mock handlers: `src/test/mocks/handlers.ts`

### Component Test
```typescript
import { render, screen, fireEvent } from '@testing-library/react';
import { vi, describe, it, expect } from 'vitest';
import { Component } from './Component';

describe('Component', () => {
  it('should render correctly', () => {
    render(<Component prop="value" />);
    expect(screen.getByRole('button')).toBeInTheDocument();
  });

  it('should handle click', async () => {
    const onAction = vi.fn();
    render(<Component onAction={onAction} />);
    await fireEvent.click(screen.getByRole('button'));
    expect(onAction).toHaveBeenCalled();
  });
});
```

### Hook Test with MSW
```typescript
import { renderHook, waitFor } from '@testing-library/react';
import { http, HttpResponse } from 'msw';
import { server } from '@/test/mocks/server';
import { useIssues } from './hooks';

it('should fetch issues', async () => {
  server.use(
    http.get('/api/v1/issues', () =>
      HttpResponse.json({ items: [{ id: '1' }] })
    )
  );

  const { result } = renderHook(() => useIssues(), { wrapper });
  await waitFor(() => expect(result.current.isSuccess).toBe(true));
  expect(result.current.data.items).toHaveLength(1);
});
```

### Test Commands
```bash
pnpm test              # Watch mode
pnpm test:run          # Single run
pnpm test:coverage     # With coverage
```

### Query Priority (Testing Library)
1. `getByRole` - buttons, headings, textboxes
2. `getByLabelText` - form inputs
3. `getByText` - static text
4. `getByTestId` - last resort only

## E2E Testing (Playwright)

### Page Object Pattern
```typescript
// e2e/fixtures/index.ts
export class LoginPage {
  constructor(private page: Page) {}

  async login(email: string, password: string) {
    await this.page.getByLabel('Email').fill(email);
    await this.page.getByLabel('Password').fill(password);
    await this.page.getByRole('button', { name: /sign in/i }).click();
  }
}
```

### E2E Test
```typescript
import { test, expect } from '../fixtures';

test('user can login', async ({ loginPage, page }) => {
  await loginPage.goto();
  await loginPage.login('admin@ward42.example.com', 'admin123');
  await expect(page).toHaveURL('/dashboard');
});
```

### E2E Commands
```bash
npx playwright test           # Run all
npx playwright test --ui      # Interactive UI
npx playwright show-report    # View report
```

## Import Order

```typescript
// 1. React
import { useState, useCallback, useMemo, type FC } from 'react';

// 2. Third-party libraries
import { useQuery } from '@tanstack/react-query';

// 3. MUI components
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';

// 4. Project absolute imports (@/ alias)
import { Button } from '@/components/atoms/Button';
import { useAuth } from '@/shared/hooks/useAuth';

// 5. Feature-relative imports
import { useIssues } from './hooks';
import type { Issue, IssueState } from './types';
```

## TypeScript Rules

```typescript
// ✅ interface for object shapes
interface Issue { id: string; type: IssueType; }

// ✅ type for unions and aliases
type IssueState = 'reported' | 'confirmed' | 'fixed';
type IssueCallback = (issue: Issue) => void;

// ✅ Explicit return types for exports
export function useIssues(sectorId: string): UseQueryResult<Issue[]> {

// ✅ Const assertions for static data
const STATES = ['reported', 'confirmed', 'fixed'] as const;

// ❌ Never use any
// ❌ Never use non-null assertion without check
```

### TypeScript Strict Mode

Compiler options (from `tsconfig.app.json`):
- `"strict": true`
- `"noUnusedLocals": true`
- `"noUnusedParameters": true`
- `"noFallthroughCasesInSwitch": true`

Common fixes:
```typescript
// Unused parameter - prefix with underscore
function handler(_event: Event, data: Data) { ... }

// Non-null assertion - prefer optional chaining
const value = obj?.nested?.value ?? defaultValue;

// Explicit function return types for exports
export function useIssues(): UseQueryResult<Issue[]> { ... }

// No any - use unknown with type guards
function processData(data: unknown): Data {
  if (isData(data)) return data;
  throw new Error('Invalid data');
}
```
