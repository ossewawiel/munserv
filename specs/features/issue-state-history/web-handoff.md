# Web Handoff: Issue State History

## Context

The web admin portal already has the UI components to display issue state history. The `HorizontalTimeline` component in `IssueDetailPage` is ready - it just needs the backend to start returning `stateHistory` data in the API response.

## Current State

| Component | Status | File |
|-----------|--------|------|
| TypeScript types | Done | `src/features/issues/types.ts` |
| API client | Done | `src/features/issues/api.ts` |
| Timeline component | Done | `src/features/issues/components/HorizontalTimeline.tsx` |
| Page integration | Done | `src/features/issues/IssueDetailPage.tsx` |

## Verification Tasks

Once the backend is updated to return `stateHistory`, verify:

### 1. Type Compatibility

The `StateHistoryEntry` interface should match the backend response:

```typescript
// src/features/issues/types.ts
export interface StateHistoryEntry {
  state: IssueState;      // matches backend's state field
  changedAt: string;       // ISO 8601 timestamp
  changedBy: string | null; // admin name or null
  note?: string;           // optional note
}
```

**Backend will return:**
```json
{
  "stateHistory": [
    {
      "state": "reported",
      "changedAt": "2026-01-10T08:30:00Z",
      "changedBy": null,
      "note": null
    },
    {
      "state": "confirmed",
      "changedAt": "2026-01-11T14:15:00Z",
      "changedBy": "Admin Name",
      "note": "Verified by field inspection"
    }
  ]
}
```

### 2. API Response Handling

The `Issue` interface already has optional `stateHistory`:

```typescript
// src/features/issues/types.ts
export interface Issue {
  // ... existing fields ...
  stateHistory?: StateHistoryEntry[];
}
```

The API client (`api.ts`) returns the full response, so no changes needed.

### 3. Timeline Display

`IssueDetailPage.tsx` already passes `stateHistory` to the timeline:

```tsx
{/* Card 4: Timeline - State History */}
<HorizontalTimeline history={issue.stateHistory || []} />
```

The `|| []` fallback handles the case where backend hasn't been updated yet.

### 4. State Change Modal

When admin changes state, the `StateChangeModal` captures:
- New state
- Optional note

The `useUpdateIssueState` hook sends this via `updateState`:

```typescript
issueApi.updateState(id, { state, notes: note })
```

**Note:** The API sends `notes` (plural) but backend expects `note` (singular). Verify this matches the backend request DTO.

## Potential Issues

### 1. Notes vs Note Field Name (ACTION REQUIRED)

Backend uses `note` (singular), web uses `notes` (plural). Fix required:

**Option A (Recommended): Update web types**

```typescript
// src/features/issues/types.ts
export interface UpdateIssueStateRequest {
  state: IssueState;
  note?: string;  // Changed from 'notes' to 'note'
}
```

Also update `hooks.ts`:
```typescript
// src/features/issues/hooks.ts
mutationFn: ({ id, state, note }: { id: string; state: IssueState; note?: string }) =>
  issueApi.updateState(id, { state, note }),  // Changed 'notes: note' to 'note'
```

**Option B: Map field in API layer**

```typescript
// src/features/issues/api.ts
updateState: (id: string, data: UpdateIssueStateRequest) =>
  apiClient.patch<Issue>(`/issues/${id}/state`, {
    state: data.state,
    note: data.notes,  // Map notes -> note
  }).then((r) => r.data),
```

### 2. Admin Name Display

Backend might return admin ID instead of name. If `changedBy` is a UUID:

Option A: Backend includes admin name (preferred)
Option B: Web fetches admin details (more complex)

For MVP, recommend backend returns admin name or null.

## Test Scenarios

### Manual Testing

1. **View issue with history:**
   - Navigate to issue detail page
   - Verify timeline shows all state transitions
   - Verify dates are formatted correctly
   - Verify admin names appear (or null for system changes)

2. **Change state:**
   - Click "Change State" button
   - Select new state
   - Add optional note
   - Submit and verify:
     - Issue state updates
     - New entry appears in timeline
     - Note displays in timeline (if provided)

3. **Empty history:**
   - View newly created issue
   - Verify timeline shows "No results" or single "Reported" entry

### Automated Tests

If timeline isn't already covered, add test:

```typescript
// src/features/issues/components/HorizontalTimeline.test.tsx
import { render, screen } from '@testing-library/react';
import { HorizontalTimeline } from './HorizontalTimeline';

describe('HorizontalTimeline', () => {
  it('should render state history entries', () => {
    const history = [
      { state: 'reported', changedAt: '2026-01-10T08:30:00Z', changedBy: null },
      { state: 'confirmed', changedAt: '2026-01-11T14:15:00Z', changedBy: 'John Admin' },
    ];

    render(<HorizontalTimeline history={history} />);

    expect(screen.getByText('Reported')).toBeInTheDocument();
    expect(screen.getByText('Confirmed')).toBeInTheDocument();
  });

  it('should show empty message when no history', () => {
    render(<HorizontalTimeline history={[]} />);
    expect(screen.getByText(/no results/i)).toBeInTheDocument();
  });
});
```

## Definition of Done

- [ ] Backend returns `stateHistory` array in issue detail response
- [ ] Timeline displays all state transitions
- [ ] Admin names display correctly (or null for system changes)
- [ ] Notes display when present
- [ ] State changes create new history entries
- [ ] Field name consistency verified (note vs notes)
- [ ] Manual testing complete
- [ ] Existing tests still passing
