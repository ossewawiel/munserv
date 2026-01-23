# Implementation Plan: pod-chief-mvp

## Summary

Complete web portal MVP for Pod Chief role affecting **backend** and **web** platforms. Includes role-based navigation, conditional dashboard, pod administrator management, messaging, and settings.

## Prerequisites

- [x] Admin role hierarchy exists (POD_CHIEF, POD_ADMIN, etc.)
- [x] Pod entity exists with config JSONB
- [x] Sectors/Wards exist
- [x] Messages module exists

## Implementation Phases

### Phase 1: Foundation (Backend)
**Stories:** None directly, but required for all

| Task | Type | Files |
|------|------|-------|
| Extend Pod entity with setup status | Migration + Domain | `V031__add_pod_setup_status.sql`, `Pod.kt` |
| Add Pod repository/service | Service | `PodRepository.kt`, `PodService.kt` |
| Pod settings endpoints | Controller | `PodSettingsController.kt` |

### Phase 2: Generic Table Component (Web)
**Stories:** W21

| Task | Type | Files |
|------|------|-------|
| Create GenericDataTable component | Organism | `components/organisms/GenericDataTable.tsx` |
| Add search input (disabled state) | Molecule | Part of GenericDataTable |
| Add filter panel (disabled state) | Molecule | Part of GenericDataTable |
| Add column sorting | Feature | Part of GenericDataTable |

### Phase 3: Navigation & Settings (Web + Backend)
**Stories:** W10, W18, W19

| Task | Type | Files |
|------|------|-------|
| Role-based navigation component | Organism | `components/organisms/RoleNavigation.tsx` |
| Pod settings API | API | `features/pod-settings/api.ts` |
| Pod settings hooks | Hooks | `features/pod-settings/hooks.ts` |
| Pod settings page | Page | `pages/pod-chief/settings/PodSettingsPage.tsx` |
| Pod name form | Component | `features/pod-settings/components/PodNameForm.tsx` |
| Logo upload component | Component | `features/pod-settings/components/LogoUpload.tsx` |
| Boundary placeholder | Component | `features/pod-settings/components/BoundaryPlaceholder.tsx` |

### Phase 4: Dashboard (Web + Backend)
**Stories:** W11, W12, W13

| Task | Type | Files |
|------|------|-------|
| Pod setup status endpoint | Controller | `PodController.kt` |
| Pod dashboard stats endpoint | Controller | `PodDashboardController.kt` |
| Ward/Sector dashboard stats endpoint | Controller | Part of existing controllers |
| Setup task banners component | Organism | `features/dashboard/components/SetupBanners.tsx` |
| Dashboard widgets component | Organism | `features/dashboard/components/PodChiefWidgets.tsx` |
| Pod Chief dashboard page | Page | `pages/pod-chief/DashboardPage.tsx` |
| Ward/Sector dashboard page | Page | `pages/pod-chief/WardDashboardPage.tsx` |

### Phase 5: Pod Administrators (Web + Backend)
**Stories:** W14, W15, W16

| Task | Type | Files |
|------|------|-------|
| Pod administrators list endpoint | Controller | `PodAdministratorController.kt` |
| Create pod administrator endpoint | Controller | `PodAdministratorController.kt` |
| Administrator onboarding endpoint | Controller | `AdminOnboardingController.kt` |
| Administrator invitation email | Service | `EmailService.kt` extension |
| Administrators list page | Page | `pages/pod-chief/administrators/AdministratorsPage.tsx` |
| Add administrator dialog | Component | `features/administrators/components/AddAdminDialog.tsx` |
| Onboarding flow pages | Pages | `pages/onboarding/*.tsx` |

### Phase 6: Messages & Reports (Web)
**Stories:** W17, W20

| Task | Type | Files |
|------|------|-------|
| Pod Chief messages page | Page | `pages/pod-chief/MessagesPage.tsx` |
| Reports menu structure | Navigation | Part of RoleNavigation |
| Report placeholder pages | Pages | `pages/pod-chief/reports/*.tsx` |

## Backend Tasks

### Domain & Entities

- [ ] **Pod setup status tracking**
  - Extend Pod entity with `setupStatus: PodSetupStatus` sealed class
  - States: `Incomplete(missingSteps: List<SetupStep>)`, `Complete`
  - Migration: `V031__add_pod_setup_fields.sql`

- [ ] **Pod settings domain**
  - `PodSettings` data class with name, logoUrl, config
  - `PodSettingsResult` sealed interface

- [ ] **Pod Administrator domain extension**
  - Add `onboardingStatus: OnboardingStatus` to Admin entity
  - States: `Pending`, `PasswordChanged`, `ProfileComplete`, `Active`

### Services

- [ ] **PodService**
  - `getSetupStatus(podId: PodId): PodSetupStatus`
  - `updateSettings(podId: PodId, settings: UpdatePodSettingsCommand): PodSettingsResult`

- [ ] **PodDashboardService**
  - `getPodStats(podId: PodId): PodDashboardStats`
  - `getWardStats(wardId: WardId): WardDashboardStats`
  - `getSectorStats(sectorId: SectorId): SectorDashboardStats`

- [ ] **PodAdministratorService**
  - `listAdministrators(podId: PodId): List<Admin>`
  - `createAdministrator(command: CreatePodAdminCommand): AdminResult`
  - `completeOnboarding(adminId: AdminId, command: CompleteOnboardingCommand): AdminResult`

### Controllers

- [ ] **PodController** (`/api/v1/pod`)
  - `GET /status` - Get pod setup status
  - `GET /settings` - Get pod settings
  - `PATCH /settings` - Update pod settings

- [ ] **PodDashboardController** (`/api/v1/pod/dashboard`)
  - `GET /` - Pod-level dashboard stats
  - `GET /wards/{wardId}` - Ward-specific stats
  - `GET /sectors/{sectorId}` - Sector-specific stats

- [ ] **PodAdministratorController** (`/api/v1/pod/administrators`)
  - `GET /` - List pod administrators
  - `POST /` - Create new administrator (sends invitation)
  - `PATCH /{id}/onboarding` - Complete onboarding step

### Migrations

- [ ] `V031__add_pod_setup_fields.sql` - Pod setup status, logo_url
- [ ] `V032__add_admin_onboarding_status.sql` - Onboarding status enum and column

## Web Tasks

### Types (`features/pod-chief/types.ts`)

```typescript
interface PodSetupStatus {
  isComplete: boolean;
  missingSteps: SetupStep[];
}

type SetupStep = 'pod_name' | 'pod_boundaries' | 'wards_sectors' | 'first_admin';

interface PodSettings {
  name: string;
  logoUrl: string | null;
  displayName: string; // "Munserv Pod {name}"
}

interface PodDashboardStats {
  totalIssues: number;
  openIssues: number;
  resolvedThisMonth: number;
  activeAdmins: number;
  // ... more
}

interface PodAdministrator {
  id: string;
  email: string;
  displayName: string;
  role: AdminRole;
  wardIds: string[];
  sectorIds: string[];
  status: 'pending' | 'active';
  createdAt: string;
}
```

### API (`features/pod-chief/api.ts`)

```typescript
export const podApi = {
  getSetupStatus: () => apiClient.get<PodSetupStatus>('/pod/status'),
  getSettings: () => apiClient.get<PodSettings>('/pod/settings'),
  updateSettings: (data: UpdatePodSettings) => apiClient.patch<PodSettings>('/pod/settings', data),
  getDashboard: () => apiClient.get<PodDashboardStats>('/pod/dashboard'),
  getWardDashboard: (wardId: string) => apiClient.get<WardDashboardStats>(`/pod/dashboard/wards/${wardId}`),
  listAdministrators: () => apiClient.get<PaginatedResponse<PodAdministrator>>('/pod/administrators'),
  createAdministrator: (data: CreateAdminRequest) => apiClient.post<PodAdministrator>('/pod/administrators', data),
};
```

### Hooks (`features/pod-chief/hooks.ts`)

- [ ] `usePodSetupStatus()` - Query pod setup status
- [ ] `usePodSettings()` - Query pod settings
- [ ] `useUpdatePodSettings()` - Mutation for settings
- [ ] `usePodDashboard()` - Query dashboard stats
- [ ] `useWardDashboard(wardId)` - Query ward stats
- [ ] `usePodAdministrators()` - Query admin list
- [ ] `useCreateAdministrator()` - Mutation for creating admin

### Components

#### Organisms

- [ ] **RoleNavigation** - Role-aware navigation menu
- [ ] **GenericDataTable** - Reusable table with search/filter/sort (W21)
- [ ] **SetupBanners** - Setup task banner list (W11)
- [ ] **PodChiefWidgets** - Dashboard widgets for Pod Chief (W12)

#### Molecules

- [ ] **SetupBanner** - Single setup task banner
- [ ] **DashboardWidget** - Single stat widget card
- [ ] **AdminTableRow** - Row in administrators table

### Pages

- [ ] `pages/pod-chief/DashboardPage.tsx` - Main Pod Chief dashboard
- [ ] `pages/pod-chief/WardDashboardPage.tsx` - Ward-specific dashboard
- [ ] `pages/pod-chief/administrators/AdministratorsPage.tsx` - Admin list
- [ ] `pages/pod-chief/administrators/AddAdminPage.tsx` - Add admin form
- [ ] `pages/pod-chief/settings/PodSettingsPage.tsx` - Pod settings
- [ ] `pages/pod-chief/messages/MessagesPage.tsx` - System messages
- [ ] `pages/pod-chief/reports/PodReportsPage.tsx` - Reports placeholder
- [ ] `pages/onboarding/ChangePasswordPage.tsx` - Admin onboarding step 1
- [ ] `pages/onboarding/CompleteProfilePage.tsx` - Admin onboarding step 2

### Routes

```typescript
// Add to router
{
  path: '/pod-chief',
  element: <RequireRole role="POD_CHIEF"><PodChiefLayout /></RequireRole>,
  children: [
    { path: 'dashboard', element: <DashboardPage /> },
    { path: 'wards/:wardId', element: <WardDashboardPage /> },
    { path: 'sectors/:sectorId', element: <SectorDashboardPage /> },
    { path: 'administrators', element: <AdministratorsPage /> },
    { path: 'administrators/add', element: <AddAdminPage /> },
    { path: 'messages', element: <MessagesPage /> },
    { path: 'reports', element: <PodReportsPage /> },
    { path: 'reports/wards/:wardId', element: <WardReportsPage /> },
    { path: 'settings', element: <PodSettingsPage /> },
  ],
}
```

### i18n Keys

```json
{
  "podChief": {
    "nav": {
      "dashboard": "Dashboard",
      "wardDashboards": "Ward Dashboards",
      "sectorDashboards": "Sector Dashboards",
      "administrators": "Pod Administrators",
      "reports": "Reports",
      "messages": "Messages",
      "settings": "Pod Settings"
    },
    "setup": {
      "podName": "Set Pod Name",
      "podBoundaries": "Configure Pod Boundaries",
      "wardsSectors": "Set Up Wards/Sectors",
      "firstAdmin": "Add First Administrator"
    },
    "dashboard": {
      "title": "Pod Dashboard",
      "totalIssues": "Total Issues",
      "openIssues": "Open Issues"
    },
    "administrators": {
      "title": "Pod Administrators",
      "addNew": "Add Administrator",
      "email": "Email",
      "name": "Name",
      "role": "Role",
      "assignedTo": "Assigned To"
    },
    "settings": {
      "title": "Pod Settings",
      "podName": "Pod Name",
      "logo": "Pod Logo",
      "boundaries": "Pod Boundaries",
      "comingSoon": "Coming Soon"
    }
  }
}
```

## Dependencies Graph

```
W21 (Generic Table) ──┬──► W14 (Admin Table)
                      └──► W20 (Reports)

W10 (Navigation) ──────► All pages

W18 (Settings) ─────────► W11 (Setup Banners)
                         W19 (Boundaries Placeholder)

Backend Pod Setup ──────► W11 (Setup Banners)
                         W12 (Dashboard Widgets)
                         W13 (Ward Dashboards)

W15 (Add Admin) ────────► W16 (Onboarding)
```

## Implementation Order

1. **Backend: Pod foundation** (V031, Pod entity, PodService)
2. **Web: W21** - Generic table component
3. **Backend: Pod settings endpoints**
4. **Web: W10** - Navigation + W18/W19 - Settings pages
5. **Backend: Dashboard endpoints**
6. **Web: W11, W12, W13** - Dashboard pages
7. **Backend: Administrator endpoints**
8. **Web: W14, W15** - Administrators pages
9. **Backend: Onboarding endpoints**
10. **Web: W16** - Onboarding flow
11. **Web: W17** - Messages (extend existing)
12. **Web: W20** - Reports structure

## Tests Required

### Backend

- [ ] `PodServiceTest` - Setup status logic, settings CRUD
- [ ] `PodDashboardServiceTest` - Stats aggregation
- [ ] `PodAdministratorServiceTest` - Admin CRUD, invitation
- [ ] `PodControllerTest` - API contract tests
- [ ] `PodDashboardControllerTest` - API contract tests
- [ ] `PodAdministratorControllerTest` - API contract tests

### Web

- [ ] `GenericDataTable.test.tsx` - Table functionality
- [ ] `usePodSettings.test.ts` - Hook tests with MSW
- [ ] `usePodDashboard.test.ts` - Hook tests
- [ ] `RoleNavigation.test.tsx` - Conditional menu items
- [ ] `SetupBanners.test.tsx` - Banner rendering
- [ ] `AdministratorsPage.test.tsx` - Page integration

## Scope Estimate

| Platform | New Files | Modified Files |
|----------|-----------|----------------|
| Backend | ~15 | ~5 |
| Web | ~25 | ~8 |
| Database | 2 migrations | - |
| Total | ~42 | ~13 |
