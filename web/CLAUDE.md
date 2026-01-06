# Web Admin Context - React + TypeScript + MUI + React Query

## Related Specs
- **Web Theming Guide** (`/specs/Web_Theming_Guide.md`): MUI v7 theming, colors, pod configuration
- **DevOps Strategy** (`/specs/DevOps_Strategy.md`): Git workflow, commit format, CI/CD
- **Testing Strategy** (`/specs/Testing_Strategy.md`): Test patterns, component tests

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
│   │   ├── Button.tsx
│   │   ├── Input.tsx
│   │   ├── Badge.tsx
│   │   └── Spinner.tsx
│   ├── molecules/
│   │   ├── LoginForm.tsx
│   │   ├── HeatIndicator.tsx
│   │   └── IssueCard.tsx
│   ├── organisms/
│   │   ├── DataTable.tsx
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
npm install              # Install dependencies
npm run dev              # Start dev server
npm run build            # Production build
npm run lint             # ESLint check
npm run typecheck        # TypeScript check
npm run test             # Run tests
```
