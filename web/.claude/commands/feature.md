# Feature Module Scaffolder

name: "feature"
description: "Scaffold new feature module with api.ts, hooks.ts, types.ts, and components folder"
parameters:
  - name: "name"
    description: "Feature name in lowercase (e.g., sectors, notifications)"
    required: true
  - name: "entities"
    description: "Comma-separated entity names (e.g., Sector,SectorSummary)"
    required: false
  - name: "endpoints"
    description: "API endpoints this feature uses (e.g., GET /sectors, POST /sectors)"
    required: false

---

You are an expert React developer scaffolding a new feature module for the MunServ web admin portal.

## Task

Create a complete feature module at `src/features/{{name}}/` with all required files following project patterns.

## Directory Structure to Create

```
src/features/{{name}}/
├── api.ts              # API functions using apiClient
├── hooks.ts            # React Query hooks (useQuery, useMutation)
├── types.ts            # TypeScript types, interfaces, and const labels
├── components/         # Feature-specific components
│   └── index.ts        # Barrel export
└── {{Name}}Page.tsx    # Main page component (optional)
```

## File Templates

### types.ts
```typescript
/**
 * {{Name}} feature types
 */

// Entity types
export interface {{Entity}} {
  id: string;
  // Add entity fields based on domain
}

export interface {{Entity}}Summary {
  id: string;
  // Add summary fields
}

// API request/response types
export interface {{Entity}}FilterParams {
  page?: number;
  limit?: number;
  // Add filter fields
}

// State types (if applicable)
export type {{Entity}}State = 'active' | 'inactive' | 'pending';

// Labels for UI display
export const {{ENTITY}}_STATE_LABELS: Record<{{Entity}}State, string> = {
  active: 'Active',
  inactive: 'Inactive',
  pending: 'Pending',
} as const;
```

### api.ts
```typescript
import { apiClient } from '@/lib/api-client';
import type { {{Entity}}, {{Entity}}FilterParams } from './types';
import type { PaginatedResponse } from '@/shared/types';

export const {{name}}Api = {
  getAll: (params?: {{Entity}}FilterParams) =>
    apiClient
      .get<PaginatedResponse<{{Entity}}>>('/{{name}}', { params })
      .then((r) => r.data),

  getById: (id: string) =>
    apiClient.get<{{Entity}}>(`/{{name}}/${id}`).then((r) => r.data),

  create: (data: Omit<{{Entity}}, 'id'>) =>
    apiClient.post<{{Entity}}>('/{{name}}', data).then((r) => r.data),

  update: (id: string, data: Partial<{{Entity}}>) =>
    apiClient.patch<{{Entity}}>(`/{{name}}/${id}`, data).then((r) => r.data),

  delete: (id: string) =>
    apiClient.delete(`/{{name}}/${id}`).then((r) => r.data),
};
```

### hooks.ts
```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { {{name}}Api } from './api';
import type { {{Entity}}, {{Entity}}FilterParams } from './types';

// Query key factory
export const {{name}}Keys = {
  all: ['{{name}}'] as const,
  lists: () => [...{{name}}Keys.all, 'list'] as const,
  list: (params?: {{Entity}}FilterParams) => [...{{name}}Keys.lists(), params] as const,
  details: () => [...{{name}}Keys.all, 'detail'] as const,
  detail: (id: string) => [...{{name}}Keys.details(), id] as const,
};

/**
 * Fetch paginated list of {{name}}
 */
export function use{{Name}}(params?: {{Entity}}FilterParams) {
  return useQuery({
    queryKey: {{name}}Keys.list(params),
    queryFn: () => {{name}}Api.getAll(params),
  });
}

/**
 * Fetch single {{entity}} by ID
 */
export function use{{Entity}}(id: string) {
  return useQuery({
    queryKey: {{name}}Keys.detail(id),
    queryFn: () => {{name}}Api.getById(id),
    enabled: !!id,
  });
}

/**
 * Create new {{entity}}
 */
export function useCreate{{Entity}}() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: Omit<{{Entity}}, 'id'>) => {{name}}Api.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: {{name}}Keys.lists() });
    },
  });
}

/**
 * Update existing {{entity}}
 */
export function useUpdate{{Entity}}() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<{{Entity}}> }) =>
      {{name}}Api.update(id, data),
    onSuccess: (updatedEntity, { id }) => {
      queryClient.setQueryData({{name}}Keys.detail(id), updatedEntity);
      queryClient.invalidateQueries({ queryKey: {{name}}Keys.lists() });
    },
  });
}

/**
 * Delete {{entity}}
 */
export function useDelete{{Entity}}() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => {{name}}Api.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: {{name}}Keys.all });
    },
  });
}
```

### components/index.ts
```typescript
// Feature-specific components
// Export components as they are created
```

### {{Name}}Page.tsx (Optional)
```typescript
import { type FC } from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { use{{Name}} } from './hooks';

const {{Name}}Page: FC = () => {
  const { data, isLoading, error } = use{{Name}}();

  if (isLoading) {
    return (
      <DashboardLayout>
        <Box sx={{ p: 3 }}>
          <Typography>Loading...</Typography>
        </Box>
      </DashboardLayout>
    );
  }

  if (error) {
    return (
      <DashboardLayout>
        <Box sx={{ p: 3 }}>
          <Typography color="error">Error loading {{name}}</Typography>
        </Box>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <Box sx={{ p: 3 }}>
        <Typography variant="h4" sx={{ mb: 3 }}>
          {{Name}}
        </Typography>
        {/* Add feature content */}
      </Box>
    </DashboardLayout>
  );
};

export default {{Name}}Page;
```

## Integration Checklist

After scaffolding, remind user to:

1. **Register Route** in `src/App.tsx`:
   ```typescript
   import {{Name}}Page from './features/{{name}}/{{Name}}Page';
   // Add route: <Route path="/{{name}}" element={<{{Name}}Page />} />
   ```

2. **Add Sidebar Link** in `src/components/templates/Sidebar.tsx`:
   ```typescript
   { label: '{{Name}}', path: '/{{name}}', icon: <IconName /> }
   ```

3. **Add i18n Keys** in `src/locales/en/translation.json`:
   ```json
   "{{name}}": {
     "title": "{{Name}}",
     "list": { "empty": "No {{name}} found" }
   }
   ```

## Output

1. Create all files with proper TypeScript types
2. Use existing patterns from `src/features/issues/` as reference
3. Replace all placeholders with actual values
4. Provide integration checklist to user
