# Handoff: Web

**Feature:** pod-chief-mvp
**Milestone:** [pod-chief-mvp](https://github.com/ossewawiel/munserv/milestone/1)
**Related Issues:** #21-#32

## Context

Implement Pod Chief MVP web interface: role-based navigation, conditional dashboard with setup banners/widgets, pod administrator management with generic table, messages, settings, and reports placeholder.

## Prerequisites

Read first:
- `web/CLAUDE.md` - Required patterns (MUI sx prop, React Query, atomic design)
- `specs/features/pod-chief-mvp/implementation-plan.md` - Full plan
- Existing: `DataTableCard`, `DashboardLayout`, theme system

## Files to Create

### Feature Module
```
web/src/features/pod-chief/
├── api.ts                  # API functions
├── hooks.ts                # React Query hooks
├── types.ts                # TypeScript types
└── components/
    ├── SetupBanner.tsx     # Single setup task banner
    ├── SetupBanners.tsx    # Banner list organism
    ├── PodChiefWidgets.tsx # Dashboard widgets
    ├── WardSectorNav.tsx   # Dynamic ward/sector submenu
    └── AdminTableRow.tsx   # Administrator row component
```

### Generic Table Component (W21)
```
web/src/components/organisms/
└── GenericDataTable/
    ├── index.tsx           # Main component
    ├── TableToolbar.tsx    # Search + filter + actions
    ├── FilterPanel.tsx     # Slide-out filter panel
    ├── ColumnHeader.tsx    # Sortable column header
    └── types.ts            # Component types
```

### Pages
```
web/src/pages/pod-chief/
├── DashboardPage.tsx       # Main dashboard (W11, W12)
├── WardDashboardPage.tsx   # Ward-specific dashboard (W13)
├── SectorDashboardPage.tsx # Sector-specific dashboard (W13)
├── administrators/
│   ├── AdministratorsPage.tsx  # Admin list (W14)
│   └── AddAdminDialog.tsx      # Add admin form (W15)
├── messages/
│   └── MessagesPage.tsx    # System messages (W17)
├── reports/
│   ├── PodReportsPage.tsx  # Pod reports placeholder (W20)
│   └── WardReportsPage.tsx # Ward reports placeholder (W20)
└── settings/
    ├── PodSettingsPage.tsx # Settings page (W18, W19)
    ├── PodNameForm.tsx     # Name/logo form
    └── BoundaryPlaceholder.tsx # Coming soon section
```

### Onboarding Pages (W16)
```
web/src/pages/onboarding/
├── ChangePasswordPage.tsx
├── CompleteProfilePage.tsx
└── WelcomePage.tsx
```

### Navigation (W10)
```
web/src/components/organisms/
└── RoleNavigation/
    ├── index.tsx           # Main navigation
    ├── PodChiefNav.tsx     # Pod Chief specific menu
    └── NavItem.tsx         # Single nav item
```

## Files to Modify

- `web/src/App.tsx` or `router.tsx` - Add Pod Chief routes
- `web/src/locales/en/translation.json` - Add i18n keys
- `web/src/components/templates/DashboardLayout.tsx` - Support role-based nav

## Implementation Steps

### Step 1: Types (`features/pod-chief/types.ts`)

```typescript
// Setup status
export interface PodSetupStatus {
  isComplete: boolean;
  missingSteps: SetupStep[];
}

export type SetupStep = 'pod_name' | 'pod_boundaries' | 'wards_sectors' | 'first_admin';

// Settings
export interface PodSettings {
  name: string;
  displayName: string;
  logoUrl: string | null;
}

export interface UpdatePodSettingsRequest {
  name?: string;
  logoUrl?: string;
}

// Dashboard
export interface PodDashboardStats {
  totalIssues: number;
  openIssues: number;
  resolvedThisMonth: number;
  pendingIssues: number;
  activeAdministrators: number;
  totalMembers: number;
  activeGroundAdmins: number;
  wardCount: number;
  sectorCount: number;
}

export interface WardDashboardStats {
  wardId: string;
  wardName: string;
  totalIssues: number;
  openIssues: number;
  resolvedThisMonth: number;
  sectorCount: number;
  activeGroundAdmins: number;
}

// Administrators
export interface PodAdministrator {
  id: string;
  email: string;
  displayName: string;
  role: AdminRole;
  wardIds: string[];
  sectorIds: string[];
  status: 'pending' | 'active';
  createdAt: string;
}

export type AdminRole = 'POD_ADMIN' | 'WARD_ADMIN' | 'WARD_CHIEF' | 'SECTOR_ADMIN' | 'SECTOR_CHIEF';

export interface CreateAdminRequest {
  email: string;
  firstName: string;
  lastName: string;
  role: AdminRole;
  wardIds?: string[];
  sectorIds?: string[];
}
```

### Step 2: API (`features/pod-chief/api.ts`)

```typescript
import { apiClient } from '@/lib/api-client';
import type {
  PodSetupStatus,
  PodSettings,
  UpdatePodSettingsRequest,
  PodDashboardStats,
  WardDashboardStats,
  PodAdministrator,
  CreateAdminRequest,
} from './types';
import type { PaginatedResponse } from '@/shared/types';

export const podChiefApi = {
  // Setup & Settings
  getSetupStatus: () =>
    apiClient.get<PodSetupStatus>('/api/v1/pod/status').then((r) => r.data),

  getSettings: () =>
    apiClient.get<PodSettings>('/api/v1/pod/settings').then((r) => r.data),

  updateSettings: (data: UpdatePodSettingsRequest) =>
    apiClient.patch<PodSettings>('/api/v1/pod/settings', data).then((r) => r.data),

  // Dashboard
  getDashboard: () =>
    apiClient.get<PodDashboardStats>('/api/v1/pod/dashboard').then((r) => r.data),

  getWardDashboard: (wardId: string) =>
    apiClient.get<WardDashboardStats>(`/api/v1/pod/dashboard/wards/${wardId}`).then((r) => r.data),

  getSectorDashboard: (sectorId: string) =>
    apiClient.get<WardDashboardStats>(`/api/v1/pod/dashboard/sectors/${sectorId}`).then((r) => r.data),

  // Administrators
  getAdministrators: (page = 1, size = 20) =>
    apiClient
      .get<PaginatedResponse<PodAdministrator>>('/api/v1/pod/administrators', {
        params: { page, size },
      })
      .then((r) => r.data),

  createAdministrator: (data: CreateAdminRequest) =>
    apiClient.post<PodAdministrator>('/api/v1/pod/administrators', data).then((r) => r.data),
};
```

### Step 3: Hooks (`features/pod-chief/hooks.ts`)

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { podChiefApi } from './api';
import type { UpdatePodSettingsRequest, CreateAdminRequest } from './types';

// Query keys
export const podChiefKeys = {
  all: ['pod-chief'] as const,
  setupStatus: () => [...podChiefKeys.all, 'setup-status'] as const,
  settings: () => [...podChiefKeys.all, 'settings'] as const,
  dashboard: () => [...podChiefKeys.all, 'dashboard'] as const,
  wardDashboard: (wardId: string) => [...podChiefKeys.all, 'dashboard', 'ward', wardId] as const,
  administrators: (page: number) => [...podChiefKeys.all, 'administrators', page] as const,
};

// Setup status
export function usePodSetupStatus() {
  return useQuery({
    queryKey: podChiefKeys.setupStatus(),
    queryFn: podChiefApi.getSetupStatus,
  });
}

// Settings
export function usePodSettings() {
  return useQuery({
    queryKey: podChiefKeys.settings(),
    queryFn: podChiefApi.getSettings,
  });
}

export function useUpdatePodSettings() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: UpdatePodSettingsRequest) => podChiefApi.updateSettings(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: podChiefKeys.settings() });
      queryClient.invalidateQueries({ queryKey: podChiefKeys.setupStatus() });
    },
  });
}

// Dashboard
export function usePodDashboard() {
  return useQuery({
    queryKey: podChiefKeys.dashboard(),
    queryFn: podChiefApi.getDashboard,
  });
}

export function useWardDashboard(wardId: string) {
  return useQuery({
    queryKey: podChiefKeys.wardDashboard(wardId),
    queryFn: () => podChiefApi.getWardDashboard(wardId),
    enabled: !!wardId,
  });
}

// Administrators
export function usePodAdministrators(page = 1) {
  return useQuery({
    queryKey: podChiefKeys.administrators(page),
    queryFn: () => podChiefApi.getAdministrators(page),
  });
}

export function useCreateAdministrator() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreateAdminRequest) => podChiefApi.createAdministrator(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: podChiefKeys.administrators(1) });
    },
  });
}
```

### Step 4: Generic Data Table (W21)

```typescript
// components/organisms/GenericDataTable/types.ts
export interface Column<T> {
  id: string;
  label: string;
  accessor: keyof T | ((row: T) => React.ReactNode);
  sortable?: boolean;
  width?: number | string;
}

export interface GenericDataTableProps<T> {
  columns: Column<T>[];
  data: T[];
  keyExtractor: (row: T) => string;

  // Pagination
  totalItems: number;
  currentPage: number;
  pageSize: number;
  onPageChange: (page: number) => void;
  onPageSizeChange: (size: number) => void;

  // Search (prepared, can be disabled)
  searchEnabled?: boolean;
  searchPlaceholder?: string;
  onSearch?: (query: string) => void;

  // Sort (prepared, can be disabled)
  sortEnabled?: boolean;
  sortColumn?: string;
  sortDirection?: 'asc' | 'desc';
  onSort?: (column: string, direction: 'asc' | 'desc') => void;

  // Filter (prepared, can be disabled)
  filterEnabled?: boolean;
  filterSlot?: React.ReactNode;

  // Actions
  actionSlot?: React.ReactNode;
  rowActions?: (row: T) => React.ReactNode;

  // State
  isLoading?: boolean;
  emptyMessage?: React.ReactNode;
}
```

```typescript
// components/organisms/GenericDataTable/index.tsx
import { type FC, useState } from 'react';
import Box from '@mui/material/Box';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import TablePagination from '@mui/material/TablePagination';
import Paper from '@mui/material/Paper';
import { TableToolbar } from './TableToolbar';
import { ColumnHeader } from './ColumnHeader';
import type { GenericDataTableProps, Column } from './types';

export function GenericDataTable<T>({
  columns,
  data,
  keyExtractor,
  totalItems,
  currentPage,
  pageSize,
  onPageChange,
  onPageSizeChange,
  searchEnabled = false,
  searchPlaceholder = 'Search...',
  onSearch,
  sortEnabled = false,
  sortColumn,
  sortDirection,
  onSort,
  filterEnabled = false,
  filterSlot,
  actionSlot,
  rowActions,
  isLoading = false,
  emptyMessage,
}: GenericDataTableProps<T>) {
  const [filterOpen, setFilterOpen] = useState(false);

  const renderCellValue = (row: T, column: Column<T>) => {
    if (typeof column.accessor === 'function') {
      return column.accessor(row);
    }
    return row[column.accessor] as React.ReactNode;
  };

  return (
    <Paper sx={{ width: '100%', overflow: 'hidden' }}>
      <TableToolbar
        searchEnabled={searchEnabled}
        searchPlaceholder={searchPlaceholder}
        onSearch={onSearch}
        filterEnabled={filterEnabled}
        onFilterOpen={() => setFilterOpen(true)}
        actionSlot={actionSlot}
      />

      <TableContainer>
        <Table stickyHeader>
          <TableHead>
            <TableRow>
              {columns.map((column) => (
                <ColumnHeader
                  key={column.id}
                  column={column}
                  sortEnabled={sortEnabled && column.sortable}
                  sortActive={sortColumn === column.id}
                  sortDirection={sortDirection}
                  onSort={onSort}
                />
              ))}
              {rowActions && <TableCell>Actions</TableCell>}
            </TableRow>
          </TableHead>
          <TableBody>
            {data.map((row) => (
              <TableRow key={keyExtractor(row)} hover>
                {columns.map((column) => (
                  <TableCell key={column.id}>
                    {renderCellValue(row, column)}
                  </TableCell>
                ))}
                {rowActions && <TableCell>{rowActions(row)}</TableCell>}
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      {data.length === 0 && !isLoading && emptyMessage}

      <TablePagination
        component="div"
        count={totalItems}
        page={currentPage - 1}
        rowsPerPage={pageSize}
        onPageChange={(_, page) => onPageChange(page + 1)}
        onRowsPerPageChange={(e) => onPageSizeChange(parseInt(e.target.value, 10))}
      />

      {/* Filter panel - slide out drawer */}
      {filterEnabled && filterSlot && (
        <FilterPanel open={filterOpen} onClose={() => setFilterOpen(false)}>
          {filterSlot}
        </FilterPanel>
      )}
    </Paper>
  );
}
```

### Step 5: Setup Banners (W11)

```typescript
// features/pod-chief/components/SetupBanners.tsx
import { type FC } from 'react';
import { useNavigate } from 'react-router-dom';
import Box from '@mui/material/Box';
import Alert from '@mui/material/Alert';
import AlertTitle from '@mui/material/AlertTitle';
import Button from '@mui/material/Button';
import { useTranslation } from 'react-i18next';
import type { SetupStep } from '../types';

interface SetupBannersProps {
  missingSteps: SetupStep[];
}

const stepConfig: Record<SetupStep, { path: string; icon: string }> = {
  pod_name: { path: '/pod-chief/settings', icon: '🏷️' },
  pod_boundaries: { path: '/pod-chief/settings#boundaries', icon: '🗺️' },
  wards_sectors: { path: '/pod-chief/settings#wards', icon: '📍' },
  first_admin: { path: '/pod-chief/administrators/add', icon: '👤' },
};

export const SetupBanners: FC<SetupBannersProps> = ({ missingSteps }) => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mb: 3 }}>
      {missingSteps.map((step) => {
        const config = stepConfig[step];
        return (
          <Alert
            key={step}
            severity="info"
            action={
              <Button
                color="inherit"
                size="small"
                onClick={() => navigate(config.path)}
              >
                {t('common.configure')}
              </Button>
            }
          >
            <AlertTitle>
              {config.icon} {t(`podChief.setup.${step}`)}
            </AlertTitle>
            {t(`podChief.setup.${step}Description`)}
          </Alert>
        );
      })}
    </Box>
  );
};
```

### Step 6: Dashboard Page (W11, W12)

```typescript
// pages/pod-chief/DashboardPage.tsx
import { type FC } from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Grid from '@mui/material/Grid';
import { useTranslation } from 'react-i18next';
import { usePodSetupStatus, usePodDashboard } from '@/features/pod-chief/hooks';
import { SetupBanners } from '@/features/pod-chief/components/SetupBanners';
import { PodChiefWidgets } from '@/features/pod-chief/components/PodChiefWidgets';
import { Breadcrumbs } from '@/components/molecules/Breadcrumbs';
import { LoadingSpinner } from '@/components/atoms/Spinner';

export default function DashboardPage() {
  const { t } = useTranslation();
  const { data: setupStatus, isLoading: setupLoading } = usePodSetupStatus();
  const { data: dashboardStats, isLoading: statsLoading } = usePodDashboard();

  if (setupLoading) {
    return <LoadingSpinner />;
  }

  const isSetupComplete = setupStatus?.isComplete ?? false;

  return (
    <Box>
      <Breadcrumbs items={[{ label: t('podChief.nav.dashboard') }]} />

      <Typography variant="h4" sx={{ mb: 3 }}>
        {t('podChief.dashboard.title')}
      </Typography>

      {!isSetupComplete && setupStatus && (
        <SetupBanners missingSteps={setupStatus.missingSteps} />
      )}

      {isSetupComplete && (
        <PodChiefWidgets stats={dashboardStats} isLoading={statsLoading} />
      )}
    </Box>
  );
}
```

### Step 7: Administrators Page (W14)

```typescript
// pages/pod-chief/administrators/AdministratorsPage.tsx
import { type FC, useState, useCallback, useMemo } from 'react';
import { useSearchParams } from 'react-router-dom';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import AddIcon from '@mui/icons-material/Add';
import { useTranslation } from 'react-i18next';
import { usePodAdministrators } from '@/features/pod-chief/hooks';
import { GenericDataTable } from '@/components/organisms/GenericDataTable';
import { Breadcrumbs } from '@/components/molecules/Breadcrumbs';
import { AddAdminDialog } from './AddAdminDialog';
import type { PodAdministrator } from '@/features/pod-chief/types';
import type { Column } from '@/components/organisms/GenericDataTable/types';

export default function AdministratorsPage() {
  const { t } = useTranslation();
  const [searchParams, setSearchParams] = useSearchParams();
  const [addDialogOpen, setAddDialogOpen] = useState(false);

  const page = parseInt(searchParams.get('page') ?? '1', 10);
  const { data, isLoading } = usePodAdministrators(page);

  const columns = useMemo<Column<PodAdministrator>[]>(() => [
    { id: 'displayName', label: t('podChief.administrators.name'), accessor: 'displayName', sortable: true },
    { id: 'email', label: t('podChief.administrators.email'), accessor: 'email', sortable: true },
    { id: 'role', label: t('podChief.administrators.role'), accessor: (row) => t(`roles.${row.role}`) },
    {
      id: 'assignedTo',
      label: t('podChief.administrators.assignedTo'),
      accessor: (row) => row.wardIds.length > 0 ? `${row.wardIds.length} wards` : `${row.sectorIds.length} sectors`
    },
    { id: 'status', label: t('common.status'), accessor: 'status' },
  ], [t]);

  const handlePageChange = useCallback((newPage: number) => {
    setSearchParams((prev) => {
      prev.set('page', String(newPage));
      return prev;
    });
  }, [setSearchParams]);

  return (
    <Box>
      <Breadcrumbs items={[
        { label: t('podChief.nav.dashboard'), to: '/pod-chief/dashboard' },
        { label: t('podChief.nav.administrators') },
      ]} />

      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4">
          {t('podChief.administrators.title')}
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => setAddDialogOpen(true)}
        >
          {t('podChief.administrators.addNew')}
        </Button>
      </Box>

      <GenericDataTable
        columns={columns}
        data={data?.items ?? []}
        keyExtractor={(row) => row.id}
        totalItems={data?.pagination.totalItems ?? 0}
        currentPage={page}
        pageSize={20}
        onPageChange={handlePageChange}
        onPageSizeChange={() => {}}
        isLoading={isLoading}
        // Search/filter prepared but disabled for MVP
        searchEnabled={false}
        sortEnabled={false}
        filterEnabled={false}
        emptyMessage={
          <Box sx={{ p: 4, textAlign: 'center' }}>
            <Typography color="text.secondary">
              {t('podChief.administrators.empty')}
            </Typography>
          </Box>
        }
      />

      <AddAdminDialog
        open={addDialogOpen}
        onClose={() => setAddDialogOpen(false)}
      />
    </Box>
  );
}
```

### Step 8: Routes

```typescript
// Add to router configuration
import { lazy } from 'react';

const PodChiefDashboard = lazy(() => import('@/pages/pod-chief/DashboardPage'));
const WardDashboard = lazy(() => import('@/pages/pod-chief/WardDashboardPage'));
const AdministratorsPage = lazy(() => import('@/pages/pod-chief/administrators/AdministratorsPage'));
const MessagesPage = lazy(() => import('@/pages/pod-chief/messages/MessagesPage'));
const PodSettingsPage = lazy(() => import('@/pages/pod-chief/settings/PodSettingsPage'));
const PodReportsPage = lazy(() => import('@/pages/pod-chief/reports/PodReportsPage'));

// In routes array
{
  path: '/pod-chief',
  element: <RequireRole roles={['POD_CHIEF']}><PodChiefLayout /></RequireRole>,
  children: [
    { index: true, element: <Navigate to="dashboard" replace /> },
    { path: 'dashboard', element: <PodChiefDashboard /> },
    { path: 'wards/:wardId', element: <WardDashboard /> },
    { path: 'sectors/:sectorId', element: <WardDashboard /> },
    { path: 'administrators', element: <AdministratorsPage /> },
    { path: 'messages', element: <MessagesPage /> },
    { path: 'reports', element: <PodReportsPage /> },
    { path: 'reports/wards/:wardId', element: <PodReportsPage /> },
    { path: 'settings', element: <PodSettingsPage /> },
  ],
}
```

### Step 9: i18n Keys

Add to `web/src/locales/en/translation.json`:

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
      "pod_name": "Set Pod Name",
      "pod_nameDescription": "Configure your pod's display name that appears in the header.",
      "pod_boundaries": "Configure Pod Boundaries",
      "pod_boundariesDescription": "Define the geographic boundaries of your pod on the map.",
      "wards_sectors": "Set Up Wards/Sectors",
      "wards_sectorsDescription": "Create the organizational structure for your pod.",
      "first_admin": "Add First Administrator",
      "first_adminDescription": "Invite your first pod administrator to help manage the pod."
    },
    "dashboard": {
      "title": "Pod Dashboard",
      "totalIssues": "Total Issues",
      "openIssues": "Open Issues",
      "resolvedThisMonth": "Resolved This Month",
      "activeAdmins": "Active Administrators",
      "totalMembers": "Total Members"
    },
    "administrators": {
      "title": "Pod Administrators",
      "addNew": "Add Administrator",
      "email": "Email",
      "name": "Name",
      "role": "Role",
      "assignedTo": "Assigned To",
      "empty": "No administrators yet. Add your first administrator to get started.",
      "addDialog": {
        "title": "Add New Administrator",
        "firstName": "First Name",
        "lastName": "Last Name",
        "selectRole": "Select Role",
        "selectWards": "Assign to Wards",
        "selectSectors": "Assign to Sectors",
        "success": "Administrator invited successfully",
        "error": "Failed to invite administrator"
      }
    },
    "settings": {
      "title": "Pod Settings",
      "podName": "Pod Name",
      "podNameHelp": "This name appears in the header as 'Munserv Pod [name]'",
      "logo": "Pod Logo",
      "logoHelp": "Upload a logo to display alongside the pod name",
      "boundaries": "Pod Boundaries",
      "boundariesHelp": "Define the geographic boundaries of your pod",
      "wardBoundaries": "Ward/Sector Boundaries",
      "comingSoon": "Coming Soon",
      "comingSoonDescription": "This feature is under development and will be available soon.",
      "saved": "Settings saved successfully"
    },
    "reports": {
      "title": "Reports",
      "podReports": "Pod Reports",
      "wardReports": "Ward Reports",
      "empty": "Reports will be available here once implemented."
    }
  },
  "roles": {
    "POD_CHIEF": "Pod Chief",
    "POD_ADMIN": "Pod Administrator",
    "WARD_CHIEF": "Ward Chief",
    "WARD_ADMIN": "Ward Administrator",
    "SECTOR_CHIEF": "Sector Chief",
    "SECTOR_ADMIN": "Sector Administrator"
  }
}
```

## Tests Required

### Component Tests

- [ ] `GenericDataTable.test.tsx` - Table rendering, pagination, empty state
- [ ] `SetupBanners.test.tsx` - Banner rendering per step
- [ ] `PodChiefWidgets.test.tsx` - Widget cards rendering
- [ ] `RoleNavigation.test.tsx` - Conditional menu items based on role

### Hook Tests (with MSW)

- [ ] `usePodSetupStatus.test.ts`
- [ ] `usePodSettings.test.ts`
- [ ] `usePodDashboard.test.ts`
- [ ] `usePodAdministrators.test.ts`

### Page Tests

- [ ] `DashboardPage.test.tsx` - Setup vs complete state
- [ ] `AdministratorsPage.test.tsx` - List and add flow
- [ ] `PodSettingsPage.test.tsx` - Form submission

## Definition of Done

- [ ] All components follow MUI sx prop styling
- [ ] All TypeScript types defined (no `any`)
- [ ] All i18n keys added
- [ ] Component tests passing
- [ ] Hook tests passing
- [ ] No ESLint errors
- [ ] No TypeScript errors
- [ ] Follows web/CLAUDE.md patterns
- [ ] Responsive design works on mobile

## Component Summary

| Component | Type | Story |
|-----------|------|-------|
| GenericDataTable | Organism | W21 |
| RoleNavigation | Organism | W10 |
| SetupBanners | Organism | W11 |
| PodChiefWidgets | Organism | W12 |
| WardSectorNav | Molecule | W13 |
| DashboardPage | Page | W11, W12 |
| WardDashboardPage | Page | W13 |
| AdministratorsPage | Page | W14 |
| AddAdminDialog | Component | W15 |
| OnboardingPages | Pages | W16 |
| MessagesPage | Page | W17 |
| PodSettingsPage | Page | W18, W19 |
| ReportsPages | Pages | W20 |
