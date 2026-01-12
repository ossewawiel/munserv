# Full Page with Routing

name: "page"
description: "Generate page component with route registration and layout integration"
parameters:
  - name: "name"
    description: "Page name in PascalCase (e.g., SectorsPage, NotificationsPage)"
    required: true
  - name: "feature"
    description: "Feature folder name (e.g., sectors, notifications)"
    required: true
  - name: "layout"
    description: "Layout type: dashboard, auth, minimal"
    required: false
    default: "dashboard"
  - name: "route"
    description: "Route path (e.g., /sectors, /settings/notifications)"
    required: false

---

You are an expert React developer creating pages for the MunServ web admin portal.

## Task

Generate a page component `{{name}}` with proper routing integration.

## Page Template (Dashboard Layout)

```typescript
import { type FC } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import AddIcon from '@mui/icons-material/Add';
import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { use{{Feature}} } from './hooks';
// Import feature components

const {{name}}: FC = () => {
  const navigate = useNavigate();
  const { data, isLoading, error } = use{{Feature}}();

  if (isLoading) {
    return (
      <DashboardLayout>
        <Box sx={{ p: 3, display: 'flex', justifyContent: 'center' }}>
          <Typography>Loading...</Typography>
        </Box>
      </DashboardLayout>
    );
  }

  if (error) {
    return (
      <DashboardLayout>
        <Box sx={{ p: 3 }}>
          <Typography color="error">
            Error loading data: {error.message}
          </Typography>
        </Box>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <Box sx={{ p: 3 }}>
        {/* Page Header */}
        <Box
          sx={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            mb: 3,
          }}
        >
          <Typography variant="h4">{{PageTitle}}</Typography>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => navigate('/{{feature}}/new')}
          >
            Add New
          </Button>
        </Box>

        {/* Page Content */}
        {data?.items.length === 0 ? (
          <Box sx={{ textAlign: 'center', py: 4 }}>
            <Typography color="text.secondary">
              No {{feature}} found
            </Typography>
          </Box>
        ) : (
          // Render data table or list
          <Box>
            {/* Feature content */}
          </Box>
        )}
      </Box>
    </DashboardLayout>
  );
};

export default {{name}};
```

## Page Template (Auth Layout)

```typescript
import { type FC } from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import { AuthLayout } from '@/components/templates/AuthLayout';

const {{name}}: FC = () => {
  return (
    <AuthLayout>
      <Box sx={{ maxWidth: 400, mx: 'auto', p: 3 }}>
        <Typography variant="h4" sx={{ mb: 3, textAlign: 'center' }}>
          {{PageTitle}}
        </Typography>
        {/* Auth content */}
      </Box>
    </AuthLayout>
  );
};

export default {{name}};
```

## Detail Page Template

```typescript
import { type FC } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { use{{Entity}} } from './hooks';

const {{name}}: FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { data: {{entity}}, isLoading, error } = use{{Entity}}(id!);

  if (isLoading) {
    return (
      <DashboardLayout>
        <Box sx={{ p: 3 }}>
          <Typography>Loading...</Typography>
        </Box>
      </DashboardLayout>
    );
  }

  if (error || !{{entity}}) {
    return (
      <DashboardLayout>
        <Box sx={{ p: 3 }}>
          <Typography color="error">
            {{Entity}} not found
          </Typography>
          <Button onClick={() => navigate('/{{feature}}')}>
            Back to list
          </Button>
        </Box>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <Box sx={{ p: 3 }}>
        {/* Back button */}
        <Button
          startIcon={<ArrowBackIcon />}
          onClick={() => navigate('/{{feature}}')}
          sx={{ mb: 2 }}
        >
          Back to {{Feature}}
        </Button>

        {/* Page content */}
        <Typography variant="h4" sx={{ mb: 3 }}>
          {{Entity}} Details
        </Typography>

        {/* Detail content */}
      </Box>
    </DashboardLayout>
  );
};

export default {{name}};
```

## Route Registration (App.tsx)

Add route to `src/App.tsx`:

```typescript
import { lazy, Suspense } from 'react';
import { Routes, Route } from 'react-router-dom';
import { ProtectedRoute } from '@/components/guards/ProtectedRoute';

// Lazy load pages
const {{name}} = lazy(() => import('./features/{{feature}}/{{name}}'));
const {{Entity}}DetailPage = lazy(() => import('./features/{{feature}}/{{Entity}}DetailPage'));

// Inside Routes
<Route element={<ProtectedRoute />}>
  {/* Existing routes */}
  <Route path="/{{feature}}" element={<{{name}} />} />
  <Route path="/{{feature}}/:id" element={<{{Entity}}DetailPage />} />
</Route>
```

## Sidebar Integration (Sidebar.tsx)

Add navigation item in `src/components/templates/Sidebar.tsx`:

```typescript
import {{Icon}}Icon from '@mui/icons-material/{{Icon}}';

const navItems = [
  // Existing items...
  {
    label: '{{PageTitle}}',
    path: '/{{feature}}',
    icon: <{{Icon}}Icon />,
  },
];
```

## i18n Keys

Add to `src/locales/en/translation.json`:

```json
{
  "{{feature}}": {
    "title": "{{PageTitle}}",
    "list": {
      "empty": "No {{feature}} found",
      "loading": "Loading {{feature}}..."
    },
    "detail": {
      "title": "{{Entity}} Details",
      "notFound": "{{Entity}} not found"
    },
    "actions": {
      "create": "Add {{Entity}}",
      "edit": "Edit",
      "delete": "Delete",
      "back": "Back to {{Feature}}"
    }
  }
}
```

## Tabbed Data Table Page Template

For list pages with status/category tabs, use `DataTableCard` with `tabs` prop:

```typescript
import { type FC, useCallback, useMemo } from 'react';
import { useSearchParams } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';

import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { Breadcrumbs } from '@/components/molecules/Breadcrumbs';
import { EmptyState } from '@/components/molecules/EmptyState';
import { ErrorState } from '@/components/molecules/ErrorState';
import { DataTableCard, type DataTableTab } from '@/components/organisms/DataTableCard';
import type { Column } from '@/components/organisms/DataTable';
import { use{{Feature}} } from './hooks';
import type { {{Entity}} } from './types';

type StatusFilter = 'all' | 'active' | 'pending' | 'archived';

const PAGE_SIZE_OPTIONS = [5, 10, 20] as const;

export const {{name}}: FC = () => {
  const { t } = useTranslation();
  const [searchParams, setSearchParams] = useSearchParams();

  // URL state
  const statusFilter = (searchParams.get('status') as StatusFilter) || 'all';
  const currentPage = Number(searchParams.get('page')) || 1;
  const pageSize = Number(searchParams.get('pageSize')) || 10;

  // Data fetching
  const { data, isLoading, error, refetch } = use{{Feature}}({
    page: currentPage,
    limit: pageSize,
    status: statusFilter === 'all' ? undefined : statusFilter,
  });

  // Tab change handler
  const handleTabChange = useCallback((newValue: StatusFilter) => {
    setSearchParams((prev) => {
      prev.set('page', '1');
      if (newValue === 'all') {
        prev.delete('status');
      } else {
        prev.set('status', newValue);
      }
      return prev;
    });
  }, [setSearchParams]);

  // Pagination handlers
  const handlePageChange = useCallback((page: number) => {
    setSearchParams((prev) => {
      prev.set('page', String(page));
      return prev;
    });
  }, [setSearchParams]);

  const handlePageSizeChange = useCallback((newPageSize: number) => {
    setSearchParams((prev) => {
      prev.set('pageSize', String(newPageSize));
      prev.set('page', '1');
      return prev;
    });
  }, [setSearchParams]);

  // Tab configuration
  const tabs = useMemo<DataTableTab<StatusFilter>[]>(() => [
    { value: 'all', label: t('common.all') },
    { value: 'active', label: t('common.active') },
    { value: 'pending', label: t('common.pending') },
    { value: 'archived', label: t('common.archived') },
  ], [t]);

  // Column configuration
  const columns = useMemo<Column<{{Entity}}>[]>(() => [
    // Define columns here
  ], [t]);

  if (error) {
    return (
      <DashboardLayout>
        <Breadcrumbs title={t('{{feature}}.title')} items={[...]} />
        <Box sx={{ mt: 3 }}>
          <ErrorState title={t('common.error')} onRetry={() => refetch()} />
        </Box>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <Breadcrumbs title={t('{{feature}}.title')} items={[...]} />
      <Box sx={{ mt: 3 }}>
        <DataTableCard
          columns={columns}
          data={data?.items ?? []}
          keyExtractor={(item) => item.id}
          totalItems={data?.pagination.totalItems ?? 0}
          currentPage={data?.pagination.page ?? currentPage}
          pageSize={data?.pagination.limit ?? pageSize}
          pageSizeOptions={PAGE_SIZE_OPTIONS}
          onPageChange={handlePageChange}
          onPageSizeChange={handlePageSizeChange}
          isLoading={isLoading}
          hideToolbarWhenEmpty
          tabs={{
            tabs,
            value: statusFilter,
            onChange: handleTabChange,
            ariaLabel: t('common.filterByStatus'),
          }}
          emptyMessage={<EmptyState title={t('{{feature}}.noResults')} />}
        />
      </Box>
    </DashboardLayout>
  );
};

export default {{name}};
```

## Output

1. Generate page component with layout integration
2. Add route to App.tsx
3. Add sidebar navigation item
4. Add i18n keys
5. Use React Query hooks for data fetching
6. Include loading/error states
7. Default export for lazy loading
8. For tabbed list pages, use DataTableCard with tabs prop
