# Web → Backend Migration: Implementation Guide

**Self-contained document for AI agent implementation**
**No external references needed except platform CLAUDE.md files**

---

## Context

- **Project**: MunServ municipal issue tracker
- **Goal**: Migrate web frontend from mock API (port 3001) to real Spring Boot backend (port 8080)
- **Web location**: `/mnt/d/sourcecode/pocs/munserv/web`
- **Backend location**: `/mnt/d/sourcecode/pocs/munserv/backend`

### Current State
- Web uses axios HTTP client configured via `VITE_API_URL` environment variable
- Currently points to mock API at `http://localhost:3001/api/v1`
- Backend runs on port 8080 with base path `/api/v1`
- Backend CORS already allows `http://localhost:3000`

---

## Phase 1: Configuration Switch

### File: `web/.env`
**Current:**
```
VITE_API_URL=http://localhost:3001/api/v1
```
**Change to:**
```
VITE_API_URL=http://localhost:8080/api/v1
```

### File: `web/vite.config.ts`
**Current proxy target:**
```typescript
proxy: {
  '/api': {
    target: 'http://localhost:3001',
    changeOrigin: true,
  },
},
```
**Change to:**
```typescript
proxy: {
  '/api': {
    target: 'http://localhost:8080',
    changeOrigin: true,
  },
},
```

### Verification
- Restart web dev server: `cd web && pnpm dev`
- Open browser devtools Network tab
- Confirm requests go to port 8080

---

## Phase 2: Authentication Testing

### Test Steps
1. Navigate to `http://localhost:3000/login`
2. Login with: `admin@ward42.example.com` / `admin123`
3. Verify token stored in localStorage (`accessToken`)
4. Verify protected routes accessible
5. Test logout clears session

### Files to Check (read-only, fix if issues)
- `web/src/features/auth/api.ts` - Login API call
- `web/src/features/auth/hooks.ts` - useLogin mutation
- `web/src/lib/api-client.ts` - Token interceptor

### Expected Behavior
- Login returns `{ tokens: { accessToken, refreshToken }, profile: { admin: { id, email, displayName, sectorId, role }, sector: { id, name, center } } }`
- Token sent as `Authorization: Bearer {accessToken}` header

---

## Phase 3: Admin Endpoints (CRITICAL FIX)

### Problem
Backend requires `sectorId` query parameter for admin endpoints.
Web frontend does NOT send it.

### Required Changes

#### File: `web/src/features/dashboard/api.ts`
**Current (line ~4-11):**
```typescript
export const dashboardApi = {
  getStats: () =>
    apiClient.get<DashboardStats>('/admin/dashboard').then((r) => r.data),

  getHeatReport: (limit?: number) =>
    apiClient
      .get<HeatReport>('/admin/reports/heat', { params: { limit } })
      .then((r) => r.data),
};
```
**Replace with:**
```typescript
export const dashboardApi = {
  getStats: (sectorId: string) =>
    apiClient.get<DashboardStats>('/admin/dashboard', { params: { sectorId } }).then((r) => r.data),

  getHeatReport: (sectorId: string, limit?: number) =>
    apiClient
      .get<HeatReport>('/admin/reports/heat', { params: { sectorId, limit } })
      .then((r) => r.data),
};
```

#### File: `web/src/features/dashboard/hooks.ts`
Find hooks that call `dashboardApi.getStats()` and `dashboardApi.getHeatReport()`.
Update to pass `sectorId` from auth context.

**Pattern:**
```typescript
import { useAuth } from '@/shared/hooks/useAuth'; // or wherever auth hook is

export function useDashboardStats() {
  const { admin } = useAuth(); // Get logged-in admin with sectorId

  return useQuery({
    queryKey: ['dashboard', 'stats', admin?.sectorId],
    queryFn: () => dashboardApi.getStats(admin!.sectorId),
    enabled: !!admin?.sectorId,
  });
}

export function useHeatReport(limit?: number) {
  const { admin } = useAuth();

  return useQuery({
    queryKey: ['dashboard', 'heat', admin?.sectorId, limit],
    queryFn: () => dashboardApi.getHeatReport(admin!.sectorId, limit),
    enabled: !!admin?.sectorId,
  });
}
```

#### File: `web/src/features/members/api.ts`
**Current (line ~6-9):**
```typescript
export const membersApi = {
  getAll: (params?: { page?: number; limit?: number }) =>
    apiClient
      .get<PaginatedResponse<MemberListItem>>('/admin/members', { params })
      .then((r) => r.data),
};
```
**Replace with:**
```typescript
export const membersApi = {
  getAll: (sectorId: string, params?: { page?: number; limit?: number }) =>
    apiClient
      .get<PaginatedResponse<MemberListItem>>('/admin/members', {
        params: { sectorId, ...params }
      })
      .then((r) => r.data),
};
```

#### File: `web/src/features/members/hooks.ts`
Update hooks to pass sectorId from auth context (same pattern as dashboard).

### Auth Context Location
Check these files to find auth context:
- `web/src/shared/hooks/useAuth.ts`
- `web/src/features/auth/hooks.ts`
- `web/src/features/auth/AuthContext.tsx`

Admin profile type (already defined in `web/src/features/auth/types.ts`):
```typescript
interface AdminUser {
  id: string;
  email: string;
  displayName: string;
  sectorId: string;  // <- Use this
  role: 'SECTOR_ADMIN' | 'COMMUNITY_ADMIN';
}
```

### Verification
- Dashboard page loads with stats
- Heat report shows ranked issues
- Members list displays with pagination

---

## Phase 4: Issues Module

### Test Steps
1. Navigate to Issues list page
2. Verify issues load with pagination
3. Test filters (state, type)
4. Click issue to view detail
5. Test state change modal
6. Verify photos display (if any exist)

### Files to Check (read-only, fix if issues)
- `web/src/features/issues/api.ts`
- `web/src/features/issues/hooks.ts`
- `web/src/features/issues/types.ts`

### Backend Endpoint Reference
```
GET  /api/v1/issues?sectorId=&state=&type=&page=1&limit=20
GET  /api/v1/issues/{id}
PATCH /api/v1/issues/{id}/state  body: { state, notes? }
```

### Photo URLs
- Backend serves photos from `/uploads/{filename}` or similar
- If photos don't display, check URL prefix in responses

---

## Phase 5: Sectors Endpoint

### Test
Verify sectors load (used in login flow / dropdowns).

### Endpoint
```
GET /api/v1/sectors → { items: [{ id, name, center }] }
```

---

## Phase 6: E2E Tests (Playwright)

### Setup
If Playwright not installed:
```bash
cd web
pnpm add -D @playwright/test
npx playwright install
```

### Create Test Files

#### File: `web/e2e/auth.spec.ts`
```typescript
import { test, expect } from '@playwright/test';

test.describe('Authentication', () => {
  test('admin can login and logout', async ({ page }) => {
    await page.goto('/login');
    await page.fill('input[name="email"]', 'admin@ward42.example.com');
    await page.fill('input[name="password"]', 'admin123');
    await page.click('button[type="submit"]');

    await expect(page).toHaveURL('/dashboard');

    // Logout
    await page.click('[data-testid="logout-button"]');
    await expect(page).toHaveURL('/login');
  });

  test('invalid credentials show error', async ({ page }) => {
    await page.goto('/login');
    await page.fill('input[name="email"]', 'wrong@example.com');
    await page.fill('input[name="password"]', 'wrongpass');
    await page.click('button[type="submit"]');

    await expect(page.locator('.MuiAlert-message')).toBeVisible();
  });
});
```

#### File: `web/e2e/dashboard.spec.ts`
```typescript
import { test, expect } from '@playwright/test';

test.describe('Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login');
    await page.fill('input[name="email"]', 'admin@ward42.example.com');
    await page.fill('input[name="password"]', 'admin123');
    await page.click('button[type="submit"]');
    await page.waitForURL('/dashboard');
  });

  test('displays stats cards', async ({ page }) => {
    await expect(page.locator('[data-testid="stats-card"]').first()).toBeVisible();
  });

  test('heat report loads', async ({ page }) => {
    await page.click('text=Heat Report');
    await expect(page.locator('table')).toBeVisible();
  });
});
```

#### File: `web/e2e/issues.spec.ts`
```typescript
import { test, expect } from '@playwright/test';

test.describe('Issues', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login');
    await page.fill('input[name="email"]', 'admin@ward42.example.com');
    await page.fill('input[name="password"]', 'admin123');
    await page.click('button[type="submit"]');
  });

  test('issues list loads with pagination', async ({ page }) => {
    await page.click('text=Issues');
    await expect(page.locator('table tbody tr').first()).toBeVisible();
  });

  test('can filter by state', async ({ page }) => {
    await page.click('text=Issues');
    await page.selectOption('[data-testid="state-filter"]', 'confirmed');
    await page.waitForResponse(/\/issues/);
  });

  test('can view issue detail', async ({ page }) => {
    await page.click('text=Issues');
    await page.click('table tbody tr:first-child');
    await expect(page.locator('[data-testid="issue-detail"]')).toBeVisible();
  });
});
```

### Run Tests
```bash
cd web
npx playwright test
```

---

## Phase 7: Cleanup

### Update Documentation

#### File: `web/README.md`
Update "Getting Started" section:
```markdown
## Getting Started

1. Start the backend:
   ```bash
   cd ../backend
   ./gradlew bootRun
   ```

2. Start the web app:
   ```bash
   cd web
   pnpm install
   pnpm dev
   ```

3. Open http://localhost:3000
```

#### File: Root `CLAUDE.md`
Update Quick Start section to reference backend instead of mock-api.

---

## Rollback

If issues arise, revert `.env`:
```
VITE_API_URL=http://localhost:3001/api/v1
```
And restart dev server.

---

## Checklist

### Phase 1: Config
- [ ] Updated `.env` to port 8080
- [ ] Updated `vite.config.ts` proxy
- [ ] Web connects to backend (Network tab)

### Phase 2: Auth
- [ ] Login works
- [ ] Token persisted
- [ ] Protected routes accessible
- [ ] Logout clears session

### Phase 3: Admin (CRITICAL)
- [ ] Dashboard API accepts sectorId
- [ ] Dashboard hooks pass sectorId
- [ ] Heat report API accepts sectorId
- [ ] Members API accepts sectorId
- [ ] Members hooks pass sectorId
- [ ] All admin pages load data

### Phase 4: Issues
- [ ] Issues list loads
- [ ] Filters work
- [ ] Detail view works
- [ ] State change works
- [ ] Photos display

### Phase 5: Sectors
- [ ] Sectors endpoint works

### Phase 6: E2E
- [ ] Auth tests pass
- [ ] Dashboard tests pass
- [ ] Issues tests pass

### Phase 7: Cleanup
- [ ] README updated
- [ ] Root CLAUDE.md updated
