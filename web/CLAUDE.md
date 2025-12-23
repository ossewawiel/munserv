# Web Admin Context - React + TypeScript + React Query

## Related Specs
- **DevOps Strategy** (`/specs/DevOps_Strategy.md`): Git workflow, commit format, CI/CD
- **Testing Strategy** (`/specs/Testing_Strategy.md`): Test patterns, component tests

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
| Atoms | Single UI elements | No |

## Folder Structure

```
src/
├── main.tsx
├── App.tsx
├── components/
│   ├── atoms/
│   │   ├── Button.tsx
│   │   ├── Input.tsx
│   │   ├── Badge.tsx
│   │   └── Spinner.tsx
│   ├── molecules/
│   │   ├── SearchBar.tsx
│   │   ├── FormField.tsx
│   │   └── IssueCard.tsx
│   ├── organisms/
│   │   ├── IssueList.tsx
│   │   ├── IssueMap.tsx
│   │   └── Navbar.tsx
│   └── templates/
│       ├── DashboardLayout.tsx
│       └── AuthLayout.tsx
├── features/
│   ├── issues/
│   │   ├── api.ts
│   │   ├── hooks.ts
│   │   ├── types.ts
│   │   └── IssuesPage.tsx
│   ├── members/
│   │   └── [same structure]
│   └── sectors/
│       └── [same structure]
├── shared/
│   ├── hooks/
│   │   └── useAuth.ts
│   ├── utils/
│   │   └── formatters.ts
│   └── types/
│       └── common.ts
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

### Atom (Single Element)
```typescript
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  isLoading?: boolean;
}

export const Button: FC<ButtonProps> = ({
  variant = 'primary',
  size = 'md',
  isLoading = false,
  children,
  disabled,
  className,
  ...props
}) => {
  return (
    <button
      className={clsx(
        'rounded font-medium transition-colors',
        variantStyles[variant],
        sizeStyles[size],
        className
      )}
      disabled={disabled || isLoading}
      {...props}
    >
      {isLoading ? <Spinner size="sm" /> : children}
    </button>
  );
};
```

### Molecule (Combined Atoms)
```typescript
interface IssueCardProps {
  issue: Issue;
  onSelect?: (issue: Issue) => void;
}

export const IssueCard: FC<IssueCardProps> = ({ issue, onSelect }) => {
  return (
    <div 
      className="rounded-lg border p-4 hover:bg-gray-50 cursor-pointer"
      onClick={() => onSelect?.(issue)}
    >
      <div className="flex items-center justify-between">
        <IssueTypeIcon type={issue.type} />
        <Badge variant={stateVariant[issue.state]}>{issue.state}</Badge>
      </div>
      <p className="mt-2 text-sm text-gray-600">{issue.type}</p>
      <HeatIndicator heat={issue.heat} />
    </div>
  );
};
```

### Organism (Complex Section)
```typescript
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
    <div>
      <IssueFilters value={filter} onChange={setFilter} />
      <div className="grid gap-4 mt-4">
        {filteredIssues.map(issue => (
          <IssueCard key={issue.id} issue={issue} />
        ))}
      </div>
    </div>
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
import { clsx } from 'clsx';

// 3. Project absolute imports (@/ alias)
import { Button } from '@/components/atoms/Button';
import { useAuth } from '@/shared/hooks/useAuth';

// 4. Feature-relative imports
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

## Build Commands (WSL2)
```bash
npm install              # Install dependencies
npm run dev              # Start dev server
npm run build            # Production build
npm run lint             # ESLint check
npm run typecheck        # TypeScript check
npm run test             # Run tests
```
