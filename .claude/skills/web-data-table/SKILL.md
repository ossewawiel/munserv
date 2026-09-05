---
name: web-data-table
description: How to build tabbed, paginated admin tables in the MunServ web portal with the DataTableCard organism - basic usage, URL-synced status tabs, per-tab toolbars, and the tab props reference. Load when a page lists records.
---

# DataTableCard

`DataTableCard` (`src/components/organisms/DataTableCard.tsx`) is the one table component for admin lists. Do not build a second one.

## DataTableCard with Tabs

Use `DataTableCard` for tabbed data tables where:
- Tabs filter data by category (status, type, etc.)
- Each tab can have its own toolbar (filterSlot, actionSlot)
- Tab state syncs with URL for bookmarkability

### Basic Usage (No Tabs)
```typescript
<DataTableCard
  columns={columns}
  data={data?.items ?? []}
  keyExtractor={(item) => item.id}
  totalItems={data?.pagination.totalItems ?? 0}
  currentPage={currentPage}
  pageSize={pageSize}
  onPageChange={handlePageChange}
  onPageSizeChange={handlePageSizeChange}
  filterSlot={<Filters />}
  actionSlot={<Button>Export</Button>}
  emptyMessage={<EmptyState ... />}
/>
```

### With Tabs (Status Filtering)
```typescript
import { DataTableCard, type DataTableTab } from '@/components/organisms/DataTableCard';

type StatusFilter = 'all' | 'pending' | 'active' | 'suspended';

// Tab configuration with optional badge
const tabs = useMemo<DataTableTab<StatusFilter>[]>(() => [
  { value: 'all', label: t('common.all') },
  {
    value: 'pending',
    label: t('common.pending'),
    badge: pendingCount,       // Shows count badge
    badgeColor: 'warning',     // Badge color variant
  },
  { value: 'active', label: t('common.active') },
  { value: 'suspended', label: t('common.suspended') },
], [t, pendingCount]);

// URL-synced tab state
const statusFilter = (searchParams.get('status') as StatusFilter) || 'all';

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

// Usage
<DataTableCard
  columns={columns}
  data={data?.items ?? []}
  keyExtractor={(item) => item.id}
  totalItems={data?.pagination.totalItems ?? 0}
  currentPage={currentPage}
  pageSize={pageSize}
  onPageChange={handlePageChange}
  onPageSizeChange={handlePageSizeChange}
  isLoading={isLoading}
  hideToolbarWhenEmpty
  tabs={{
    tabs,
    value: statusFilter,        // Controlled mode
    onChange: handleTabChange,
    ariaLabel: t('common.filterByStatus'),
  }}
  emptyMessage={<EmptyState ... />}
/>
```

### Per-Tab Toolbar Content
Each tab can have its own filterSlot and actionSlot:
```typescript
const tabs = useMemo<DataTableTab<StatusFilter>[]>(() => [
  {
    value: 'all',
    label: 'All',
    filterSlot: <AllFilters />,   // Shown when "All" tab active
  },
  {
    value: 'pending',
    label: 'Pending',
    badge: pendingCount,
    actionSlot: <ApproveAllButton />, // Shown when "Pending" tab active
  },
], [pendingCount]);
```

### Tab Props Reference
| Prop | Type | Description |
|------|------|-------------|
| `value` | `string` | Unique tab identifier |
| `label` | `ReactNode` | Tab display text |
| `badge` | `number \| string` | Optional badge content |
| `badgeColor` | `'primary' \| 'warning' \| ...` | Badge color variant |
| `filterSlot` | `ReactNode` | Tab-specific filters |
| `actionSlot` | `ReactNode` | Tab-specific actions |
| `disabled` | `boolean` | Whether tab is disabled |
