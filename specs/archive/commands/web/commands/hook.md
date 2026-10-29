# React Query Hook Generator

name: "hook"
description: "Create React Query hook (query or mutation) for a feature"
parameters:
  - name: "name"
    description: "Hook name without 'use' prefix (e.g., Sectors, CreateSector, UpdateIssueState)"
    required: true
  - name: "type"
    description: "Hook type: query, mutation, infinite"
    required: true
  - name: "feature"
    description: "Feature folder name (e.g., issues, members, sectors)"
    required: true
  - name: "endpoint"
    description: "API endpoint (e.g., GET /sectors, POST /sectors, PATCH /issues/:id/state)"
    required: false

---

You are an expert React developer creating React Query hooks for the MunServ web admin portal.

## Task

Generate a {{type}} hook named `use{{name}}` in `src/features/{{feature}}/hooks.ts`.

## Hook Patterns by Type

### Query Hook
```typescript
import { useQuery, type UseQueryResult } from '@tanstack/react-query';
import { {{feature}}Api } from './api';
import type { {{Entity}} } from './types';

/**
 * Fetch {{description}}
 */
export function use{{name}}(
  params?: {{Params}},
): UseQueryResult<{{ReturnType}}> {
  return useQuery({
    queryKey: ['{{feature}}', ...Object.values(params ?? {})],
    queryFn: () => {{feature}}Api.{{method}}(params),
    enabled: !!requiredParam, // Add if conditionally fetching
    staleTime: 5 * 60 * 1000, // Optional: 5 minutes
  });
}
```

### Mutation Hook
```typescript
import { useMutation, useQueryClient, type UseMutationResult } from '@tanstack/react-query';
import { {{feature}}Api } from './api';
import type { {{Entity}} } from './types';

/**
 * {{description}}
 */
export function use{{name}}(): UseMutationResult<
  {{ReturnType}},
  Error,
  {{InputType}}
> {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: {{InputType}}) => {{feature}}Api.{{method}}(data),
    onSuccess: (result, variables) => {
      // Update single item cache
      queryClient.setQueryData(['{{feature}}', variables.id], result);
      // Invalidate list queries
      queryClient.invalidateQueries({ queryKey: ['{{feature}}'] });
    },
    onError: (error) => {
      console.error('{{name}} failed:', error);
    },
  });
}
```

### Infinite Query Hook
```typescript
import { useInfiniteQuery, type UseInfiniteQueryResult } from '@tanstack/react-query';
import { {{feature}}Api } from './api';
import type { {{Entity}}, PaginatedResponse } from './types';

/**
 * Fetch paginated {{description}} with infinite scroll
 */
export function use{{name}}(
  params?: Omit<{{Params}}, 'page'>,
): UseInfiniteQueryResult<PaginatedResponse<{{Entity}}>> {
  return useInfiniteQuery({
    queryKey: ['{{feature}}', 'infinite', params],
    queryFn: ({ pageParam = 1 }) =>
      {{feature}}Api.{{method}}({ ...params, page: pageParam }),
    getNextPageParam: (lastPage) =>
      lastPage.page < Math.ceil(lastPage.total / lastPage.limit)
        ? lastPage.page + 1
        : undefined,
    initialPageParam: 1,
  });
}
```

## Query Key Conventions

Use hierarchical keys for cache management:

```typescript
// Key factory pattern
export const {{feature}}Keys = {
  all: ['{{feature}}'] as const,
  lists: () => [...{{feature}}Keys.all, 'list'] as const,
  list: (params?: Params) => [...{{feature}}Keys.lists(), params] as const,
  details: () => [...{{feature}}Keys.all, 'detail'] as const,
  detail: (id: string) => [...{{feature}}Keys.details(), id] as const,
};

// Usage
queryKey: {{feature}}Keys.detail(id)
```

## Cache Invalidation Patterns

### After Create
```typescript
onSuccess: () => {
  queryClient.invalidateQueries({ queryKey: {{feature}}Keys.lists() });
}
```

### After Update
```typescript
onSuccess: (result, { id }) => {
  // Update detail cache directly
  queryClient.setQueryData({{feature}}Keys.detail(id), result);
  // Invalidate lists to refetch
  queryClient.invalidateQueries({ queryKey: {{feature}}Keys.lists() });
}
```

### After Delete
```typescript
onSuccess: (_, id) => {
  // Remove from cache
  queryClient.removeQueries({ queryKey: {{feature}}Keys.detail(id) });
  // Invalidate all related queries
  queryClient.invalidateQueries({ queryKey: {{feature}}Keys.all });
}
```

## Error Handling

### With Toast Notifications
```typescript
import { useSnackbar } from 'notistack'; // or your toast library

export function use{{name}}() {
  const queryClient = useQueryClient();
  const { enqueueSnackbar } = useSnackbar();

  return useMutation({
    mutationFn: (data) => {{feature}}Api.{{method}}(data),
    onSuccess: () => {
      enqueueSnackbar('{{Success message}}', { variant: 'success' });
      queryClient.invalidateQueries({ queryKey: {{feature}}Keys.lists() });
    },
    onError: (error) => {
      enqueueSnackbar(error.message || '{{Error message}}', { variant: 'error' });
    },
  });
}
```

## Integration with useAuth

When hooks need sector context:

```typescript
import { useAuth } from '@/shared/hooks/useAuth';

export function use{{name}}(params?: Omit<Params, 'sectorId'>) {
  const { admin } = useAuth();

  return useQuery({
    queryKey: ['{{feature}}', admin?.sectorId, params],
    queryFn: () => {{feature}}Api.{{method}}({ sectorId: admin!.sectorId, ...params }),
    enabled: !!admin?.sectorId,
  });
}
```

## Output

1. Read existing `src/features/{{feature}}/hooks.ts` to understand current patterns
2. Add the new hook following the patterns above
3. Export the hook if not already exported
4. Update the API file if the endpoint function doesn't exist
5. Ensure TypeScript types are properly defined
