# Issue Creation - Web Phase

## Status: Verified ✅

**Verified:** January 2026

## Overview
Verify web admin portal displays newly created issues with their photos.

## Verification Summary

All display features verified working:
- ✅ New issues appear in list with thumbnails
- ✅ Issue detail page shows all metadata
- ✅ Photo gallery displays uploaded photos
- ✅ Lightbox opens for full-size viewing
- ✅ State/type filters work correctly

---

## Reference: Original Analysis

### Status: Was 95% Complete (Now Verified)

The web implementation is nearly complete for viewing issues:

| Component | Status | Notes |
|-----------|--------|-------|
| Issue list page | ✅ Working | Pagination, filtering |
| Issue detail page | ✅ Working | Full metadata display |
| Photo gallery | ✅ Working | Grid + lightbox modal |
| Thumbnail display | ✅ Working | In list table |
| State management | ✅ Working | Change state modal |

### Files Involved
| File | Purpose |
|------|---------|
| `src/features/issues/IssuesPage.tsx` | List view with filters |
| `src/features/issues/IssueDetailPage.tsx` | Detail view |
| `src/features/issues/api.ts` | API client functions |
| `src/features/issues/hooks.ts` | React Query hooks |
| `src/features/issues/types.ts` | TypeScript interfaces |
| `src/components/molecules/PhotoGallery.tsx` | Photo display |

---

## Verification Tasks

### Task 1: Verify Issue List Shows New Issues
**Purpose**: Confirm newly created issues appear in admin portal.

**Manual Test Steps**:
1. Create issue via mobile app (or curl)
2. Open web portal at http://localhost:3000
3. Navigate to Issues page
4. Verify new issue appears in list

**Checklist**:
- [ ] Issue appears in list
- [ ] Thumbnail displays (if photo uploaded)
- [ ] Type badge shows correct type
- [ ] State badge shows "Reported"
- [ ] Heat indicator shows value

---

### Task 2: Verify Issue Detail Shows Photos
**Purpose**: Confirm photo gallery displays uploaded photos.

**Manual Test Steps**:
1. Click on issue with photos in list
2. Verify detail page loads
3. Check photo gallery displays all photos
4. Click a photo to open lightbox
5. Verify full-size image loads

**Checklist**:
- [ ] Detail page loads without errors
- [ ] Photo gallery shows all photos
- [ ] Photos are correct (match what was uploaded)
- [ ] Lightbox opens on click
- [ ] Full-size image displays
- [ ] Can close lightbox

---

### Task 3: Verify Filtering Works with New Issues
**Purpose**: Confirm filters correctly show/hide new issues.

**Test Cases**:
```
1. Filter by state="reported" → Should show new issues
2. Filter by type="pothole" → Should show only potholes
3. Clear filters → Should show all issues
4. Filter by state="fixed" → Should NOT show new issues
```

**Checklist**:
- [ ] State filter works
- [ ] Type filter works
- [ ] Clear filter works
- [ ] Combined filters work

---

## Enhancement Tasks (Optional)

### Task 4: Add Auto-Refresh for New Issues
**Priority**: P2 - Medium

**Purpose**: Automatically show new issues without manual page refresh.

**File**: `src/features/issues/hooks.ts`

**Option A - Polling**:
```typescript
export function useIssues(params?: IssueFilterParams) {
  const { admin } = useAuth();
  const fullParams = { ...params, sectorId: admin?.sectorId };

  return useQuery({
    queryKey: ['issues', fullParams],
    queryFn: () => issueApi.getAll(fullParams),
    enabled: !!admin?.sectorId,
    refetchInterval: 30000,  // Refetch every 30 seconds
  });
}
```

**Option B - Manual Refresh Button**:
```typescript
// In IssuesPage.tsx
const { refetch, isFetching } = useIssues(params);

<Button
  onClick={() => refetch()}
  disabled={isFetching}
  startIcon={<RefreshIcon />}
>
  {isFetching ? 'Refreshing...' : 'Refresh'}
</Button>
```

---

### Task 5: Add "New Issues" Badge to Navigation
**Priority**: P3 - Low

**Purpose**: Show count of new (unread) issues in nav.

**Implementation Sketch**:
```typescript
// New hook in hooks.ts
export function useNewIssuesCount() {
  const { admin } = useAuth();
  const lastViewed = localStorage.getItem('issues-last-viewed');

  return useQuery({
    queryKey: ['issues-count', admin?.sectorId, lastViewed],
    queryFn: async () => {
      const response = await issueApi.getAll({
        sectorId: admin?.sectorId,
        state: 'reported',
        since: lastViewed,
      });
      return response.total;
    },
    enabled: !!admin?.sectorId,
    refetchInterval: 60000,
  });
}
```

**Note**: Requires backend to support `since` filter parameter.

---

### Task 6: Fix Tailwind Classes in IssueInfoCard
**Priority**: P2 - Medium (Code consistency)

**File**: `src/features/issues/components/IssueInfoCard.tsx`

**Problem**: Uses Tailwind CSS classes instead of MUI sx prop.

**Current**:
```tsx
<div className="bg-background border border-border rounded-lg p-6">
```

**Should Be**:
```tsx
<Box sx={{
  bgcolor: 'background.paper',
  border: 1,
  borderColor: 'divider',
  borderRadius: 2,
  p: 3,
}}>
```

---

## Testing Strategy

### Manual E2E Test Script
```
1. Start backend: cd backend && ./gradlew bootRun
2. Start web: cd web && pnpm dev
3. Login as admin: admin@ward42.example.com / admin123
4. Navigate to Issues page
5. Note current issue count
6. Create issue via curl or mobile
7. Refresh Issues page
8. Verify count increased
9. Click new issue
10. Verify photos display
11. Change state to "confirmed"
12. Verify state updates in list
```

### Automated Tests (Existing)
```bash
cd web
pnpm test

# Specific tests
pnpm test -- --grep="IssuesTable"
pnpm test -- --grep="PhotoGallery"
```

### Missing Tests
- [ ] IssuesPage integration test
- [ ] IssueDetailPage integration test
- [ ] Photo loading states
- [ ] Filter state changes

---

## API Integration Details

### Endpoints Used
```typescript
GET  /api/v1/issues           → issueApi.getAll()
GET  /api/v1/issues/:id       → issueApi.getById()
PATCH /api/v1/issues/:id/state → issueApi.updateState()
```

### Photo URL Format
```
Full size:  http://localhost:8080/uploads/{photoId}.jpg
Thumbnail:  http://localhost:8080/uploads/{photoId}-thumb.jpg
```

### CORS Configuration
Backend must allow web origin:
```yaml
# backend/src/main/resources/application.yml
cors:
  allowed-origins:
    - http://localhost:3000
```

---

## Commands

```bash
# Start development server
cd web && pnpm dev

# Run tests
cd web && pnpm test

# Build for production
cd web && pnpm build

# Lint check
cd web && pnpm lint
```

---

## Definition of Done

- [ ] New issues appear in list
- [ ] Photos display in detail view
- [ ] Lightbox works for full-size photos
- [ ] Filters work correctly
- [ ] No console errors
- [ ] No broken image links

---

## Handoff Notes

**For agent execution:**
```
cd web
Read web/CLAUDE.md first for React Query patterns.

This phase is primarily VERIFICATION, not implementation.
The web portal is already working - verify it displays mobile-created issues.

Priority order:
1. Tasks 1-3 (Verification) - Manual testing
2. Task 4 (Auto-refresh) - Enhancement if time permits
3. Task 5 (Badge) - Future scope, skip for MVP
4. Task 6 (Tailwind fix) - Code cleanup
```

---

## Troubleshooting

### Photos Not Loading
```
1. Check browser Network tab for 404s
2. Verify backend uploads directory exists
3. Check CORS allows localhost:3000
4. Verify photo URLs in API response
```

### Issues Not Appearing
```
1. Check sectorId matches admin's sector
2. Verify JWT token is valid
3. Check API response in Network tab
4. Verify filtering isn't hiding new issues
```

### Stale Data
```
1. Clear React Query cache: queryClient.clear()
2. Hard refresh: Ctrl+Shift+R
3. Check refetchOnWindowFocus setting
```
