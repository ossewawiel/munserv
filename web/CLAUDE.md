# Web Admin Context - React + TypeScript + MUI + React Query

## Related Specs
- **Web Theming Guide** (`/specs/Web_Theming_Guide.md`): MUI v7 theming, colors, pod configuration
- **DevOps Strategy** (`/specs/DevOps_Strategy.md`): Git workflow, commit format, CI/CD
- **Testing Strategy** (`/specs/Testing_Strategy.md`): Test patterns, component tests

## Reference Implementation
- **Berry Dashboard** (`/mnt/d/SourceCode/pocs/berry-material-react-3.7.0/full-version`): MUI React admin template for component patterns (breadcrumbs, layouts, navigation)

## Styling (MUI v7)

| Pattern | Usage |
|---------|-------|
| `sx` prop | Inline styles with theme access |
| Theme colors | `bgcolor: 'primary.main'` |
| CSS variables | `var(--munserv-palette-*)` |
| Responsive | `{ xs: 2, sm: 3, md: 4 }` |

### DO: Use MUI's sx prop
```typescript
<Box sx={{ p: 2, bgcolor: 'background.paper', borderRadius: 1 }}>
<Button variant="contained" color="primary">
<Typography variant="body2" color="text.secondary">
```

### DON'T: Use inline styles or raw CSS classes
```typescript
// BAD - inline styles
<div style={{ padding: '16px', backgroundColor: 'white' }}>

// BAD - Tailwind/CSS classes
<div className="p-4 bg-white rounded">
```

## Layer Architecture

```
Pages → Organisms → Molecules → Atoms
         ↓
      Hooks (React Query) → API
```

| Layer | Responsibility | Data Fetching |
|-------|----------------|---------------|
| Pages | Route entry, compose organisms | Yes (via hooks) |
| Organisms | Complex UI sections | Sometimes |
| Molecules | Combined atoms | No |
| Atoms | Single UI elements (MUI wrappers) | No |

## Folder Structure

```
src/
├── main.tsx
├── App.tsx
├── theme/                  ← MUI theme configuration
│   ├── index.ts
│   ├── colors.ts
│   ├── types.ts
│   ├── createPodTheme.ts
│   ├── defaultTheme.ts
│   └── ThemeContext.tsx
├── components/
│   ├── atoms/             ← Thin wrappers around MUI
│   │   ├── ActionButton.tsx  ← Berry-style soft bg button
│   │   ├── Button.tsx
│   │   ├── Input.tsx
│   │   ├── Badge.tsx
│   │   └── Spinner.tsx
│   ├── molecules/
│   │   ├── Breadcrumbs.tsx   ← Page header with breadcrumb trail
│   │   ├── LoginForm.tsx
│   │   ├── HeatIndicator.tsx
│   │   └── IssueCard.tsx
│   ├── organisms/
│   │   ├── DataTable.tsx       ← Base table component
│   │   ├── DataTableCard.tsx   ← Reusable table card with tabs + toolbar + pagination
│   │   ├── IssueList.tsx
│   │   └── Navbar.tsx
│   └── templates/
│       ├── DashboardLayout.tsx
│       └── AuthLayout.tsx
├── features/
│   ├── issues/
│   │   ├── api.ts
│   │   ├── hooks.ts
│   │   ├── types.ts
│   │   └── components/
│   ├── members/
│   │   └── [same structure]
│   └── dashboard/
│       └── [same structure]
├── shared/
│   ├── hooks/
│   ├── utils/
│   └── types/
└── lib/
    ├── api-client.ts
    └── query-client.ts
```

## DataTableCard with Tabs

Use `DataTableCard` for tabbed data tables where:
- Tabs filter data by category (status, type, etc.)
- Each tab can have its own toolbar (filterSlot, actionSlot)
- Tab state syncs with URL for bookmarkability

### Basic Usage (No Tabs)
```typescript
<DataTableCard
  columns={columns}
  data={data?.items ?? []}
  keyExtractor={(item) => item.id}
  totalItems={data?.pagination.totalItems ?? 0}
  currentPage={currentPage}
  pageSize={pageSize}
  onPageChange={handlePageChange}
  onPageSizeChange={handlePageSizeChange}
  filterSlot={<Filters />}
  actionSlot={<Button>Export</Button>}
  emptyMessage={<EmptyState ... />}
/>
```

### With Tabs (Status Filtering)
```typescript
import { DataTableCard, type DataTableTab } from '@/components/organisms/DataTableCard';

type StatusFilter = 'all' | 'pending' | 'active' | 'suspended';

// Tab configuration with optional badge
const tabs = useMemo<DataTableTab<StatusFilter>[]>(() => [
  { value: 'all', label: t('common.all') },
  {
    value: 'pending',
    label: t('common.pending'),
    badge: pendingCount,       // Shows count badge
    badgeColor: 'warning',     // Badge color variant
  },
  { value: 'active', label: t('common.active') },
  { value: 'suspended', label: t('common.suspended') },
], [t, pendingCount]);

// URL-synced tab state
const statusFilter = (searchParams.get('status') as StatusFilter) || 'all';

const handleTabChange = useCallback((newValue: StatusFilter) => {
  setSearchParams((prev) => {
    prev.set('page', '1');
    if (newValue === 'all') {
      prev.delete('status');
    } else {
      prev.set('status', newValue);
    }
    return prev;
  });
}, [setSearchParams]);

// Usage
<DataTableCard
  columns={columns}
  data={data?.items ?? []}
  keyExtractor={(item) => item.id}
  totalItems={data?.pagination.totalItems ?? 0}
  currentPage={currentPage}
  pageSize={pageSize}
  onPageChange={handlePageChange}
  onPageSizeChange={handlePageSizeChange}
  isLoading={isLoading}
  hideToolbarWhenEmpty
  tabs={{
    tabs,
    value: statusFilter,        // Controlled mode
    onChange: handleTabChange,
    ariaLabel: t('common.filterByStatus'),
  }}
  emptyMessage={<EmptyState ... />}
/>
```

### Per-Tab Toolbar Content
Each tab can have its own filterSlot and actionSlot:
```typescript
const tabs = useMemo<DataTableTab<StatusFilter>[]>(() => [
  {
    value: 'all',
    label: 'All',
    filterSlot: <AllFilters />,   // Shown when "All" tab active
  },
  {
    value: 'pending',
    label: 'Pending',
    badge: pendingCount,
    actionSlot: <ApproveAllButton />, // Shown when "Pending" tab active
  },
], [pendingCount]);
```

### Tab Props Reference
| Prop | Type | Description |
|------|------|-------------|
| `value` | `string` | Unique tab identifier |
| `label` | `ReactNode` | Tab display text |
| `badge` | `number \| string` | Optional badge content |
| `badgeColor` | `'primary' \| 'warning' \| ...` | Badge color variant |
| `filterSlot` | `ReactNode` | Tab-specific filters |
| `actionSlot` | `ReactNode` | Tab-specific actions |
| `disabled` | `boolean` | Whether tab is disabled |

## Internationalization (i18next)

### Translation Usage
```typescript
import { useTranslation } from 'react-i18next';

const { t } = useTranslation();
return <Typography>{t('issues.states.reported')}</Typography>;
```

### Translation File
Location: `src/locales/en/translation.json`

### Key Naming Convention
```
{feature}.{context}.{key}

issues.title              → "Issues"
issues.states.reported    → "Reported"
issues.actions.create     → "Create Issue"
common.buttons.save       → "Save"
errors.generic            → "Something went wrong"
```

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
          <Grid item xs={12} sm={6} md={4} key={issue.id}>
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

## Forbidden
- `any` type (use `unknown` if truly unknown)
- Class components (use functional + hooks)
- `useEffect` for data fetching (use React Query)
- `useState` for server state (use React Query)
- Prop drilling beyond 2 levels (use context or composition)
- Index as key in dynamic lists (use stable IDs)
- Inline object/function creation in JSX within loops
- Business logic in components (extract to hooks/utils)
- **CSS class names or Tailwind** (use MUI `sx` prop)
- **clsx or classnames** (removed from project)
- **Direct color values** (use theme tokens: `'primary.main'`)
- **Inline styles** (use `sx` prop instead)

## Build Commands (WSL2)
```bash
pnpm install             # Install dependencies
pnpm dev                 # Start dev server (port 3000)
pnpm build               # Production build
pnpm lint                # ESLint check
pnpm typecheck           # TypeScript check
pnpm test                # Run tests (watch)
pnpm test:run            # Run tests (single run)
pnpm test:coverage       # Run tests with coverage
```

## Available Skills

Skills are located in `.claude/commands/`. Use `/skill-name` to invoke.

### Code Generation
| Skill | Purpose |
|-------|---------|
| `/component` | Generate MUI component (atom/molecule/organism/page) |
| `/feature` | Scaffold new feature module |
| `/hook` | Create React Query hook |
| `/api` | Add API endpoint function |
| `/form` | Create form with React Hook Form + Zod |
| `/page` | Generate page with routing |
| `/i18n` | Add translation keys |

### Quality & Testing
| Skill | Purpose |
|-------|---------|
| `/test` | Generate Vitest test |
| `/e2e` | Generate Playwright E2E test |
| `/review` | Code review for patterns |
| `/ci-fix` | Debug CI/CD failures |

### Workflow
| Skill | Purpose |
|-------|---------|
| `/dev-cycle` | Full TDD workflow: Specify → Test → Code → Refactor → Quality Gate → Document |

## TDD Development Cycle

When adding functionality, follow this workflow:

```
1. SPECIFY    → Define acceptance criteria
2. TEST       → Write failing tests first (Red)
3. CODE       → Implement to pass tests (Green)
4. REFACTOR   → Clean up, fix review issues
5. QUALITY    → Run lint, typecheck, tests
6. DOCUMENT   → Add i18n keys, JSDoc
7. PRE-COMMIT → Full CI verification
```

Use `/dev-cycle "your task description"` to orchestrate this workflow.
