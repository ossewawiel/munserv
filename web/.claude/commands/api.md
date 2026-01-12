# API Endpoint Integration

name: "api"
description: "Generate typed API function with error handling, add to feature api.ts"
parameters:
  - name: "endpoint"
    description: "API endpoint path (e.g., /issues/:id/state, /admin/reports/heat)"
    required: true
  - name: "method"
    description: "HTTP method: GET, POST, PATCH, PUT, DELETE"
    required: true
  - name: "feature"
    description: "Feature folder name (e.g., issues, members, dashboard)"
    required: true
  - name: "name"
    description: "Function name (e.g., updateState, getHeatReport)"
    required: false

---

You are an expert React developer adding API endpoint functions to the MunServ web admin portal.

## Task

Add an API function for `{{method}} {{endpoint}}` to `src/features/{{feature}}/api.ts`.

## API Function Pattern

```typescript
import { apiClient } from '@/lib/api-client';
import type { /* types */ } from './types';

export const {{feature}}Api = {
  // Existing functions...

  /**
   * {{description}}
   * {{method}} {{endpoint}}
   */
  {{name}}: (/* params */) =>
    apiClient.{{method.toLowerCase()}}<ResponseType>('{{endpoint}}', /* config */).then((r) => r.data),
};
```

## Method-Specific Patterns

### GET (single item)
```typescript
getById: (id: string) =>
  apiClient.get<Issue>(`/issues/${id}`).then((r) => r.data),
```

### GET (list with query params)
```typescript
getAll: (params?: IssueFilterParams) =>
  apiClient
    .get<PaginatedResponse<Issue>>('/issues', { params })
    .then((r) => r.data),
```

### GET (with sectorId from admin)
```typescript
getByAdmin: (sectorId: string, params?: FilterParams) =>
  apiClient
    .get<PaginatedResponse<Item>>('/admin/items', {
      params: { sectorId, ...params },
    })
    .then((r) => r.data),
```

### POST (create)
```typescript
create: (data: CreateIssueRequest) =>
  apiClient.post<Issue>('/issues', data).then((r) => r.data),
```

### PATCH (partial update)
```typescript
updateState: (id: string, data: { state: IssueState; notes?: string }) =>
  apiClient.patch<Issue>(`/issues/${id}/state`, data).then((r) => r.data),
```

### PUT (full update)
```typescript
update: (id: string, data: UpdateIssueRequest) =>
  apiClient.put<Issue>(`/issues/${id}`, data).then((r) => r.data),
```

### DELETE
```typescript
delete: (id: string) =>
  apiClient.delete(`/issues/${id}`).then((r) => r.data),
```

## Type Definitions

Ensure types are defined in `types.ts`:

```typescript
// Request types
export interface CreateIssueRequest {
  type: IssueType;
  location: GeoPoint;
  description?: string;
  photos?: string[];
}

export interface UpdateStateRequest {
  state: IssueState;
  notes?: string;
}

// Response types (if different from entity)
export interface IssueWithDetails extends Issue {
  photos: Photo[];
  stateHistory: StateChange[];
}
```

## Error Handling

The apiClient already has interceptors for:
- Adding Authorization header
- Handling 401 (redirect to login)

For custom error handling:

```typescript
import { AxiosError } from 'axios';
import type { ApiError } from '@/shared/types';

// In the calling code (hook or component)
try {
  await issueApi.updateState(id, { state: 'confirmed' });
} catch (error) {
  if (error instanceof AxiosError) {
    const apiError = error.response?.data as ApiError;
    // Handle specific error
  }
}
```

## Path Parameters

Replace path parameters with template literals:

```typescript
// Endpoint: /issues/:id/state
updateState: (id: string, data: UpdateStateRequest) =>
  apiClient.patch<Issue>(`/issues/${id}/state`, data).then((r) => r.data),

// Endpoint: /sectors/:sectorId/issues/:issueId
getIssueInSector: (sectorId: string, issueId: string) =>
  apiClient.get<Issue>(`/sectors/${sectorId}/issues/${issueId}`).then((r) => r.data),
```

## Query Parameters

Use the `params` option for query parameters:

```typescript
// Endpoint: /issues?state=reported&type=pothole&page=1&limit=20
getFiltered: (params: IssueFilterParams) =>
  apiClient.get<PaginatedResponse<Issue>>('/issues', { params }).then((r) => r.data),
```

## Output

1. Read existing `src/features/{{feature}}/api.ts`
2. Add the new function to the api object
3. Ensure types are defined in `types.ts`
4. Export function if api object is not already exported as a whole
5. Verify the endpoint matches backend API documentation
