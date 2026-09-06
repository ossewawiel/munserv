import { useState } from 'react';
import type { Meta, StoryObj } from '@storybook/react-vite';
import Typography from '@mui/material/Typography';

import { Button } from '@/components/atoms/Button';
import { Input } from '@/components/atoms/Input';
import { EmptyState } from '@/components/molecules/EmptyState';
import { DataTableCard, type DataTableTab } from './DataTableCard';
import type { Column, SortState } from './DataTable';

interface DemoMember {
  id: string;
  name: string;
  status: 'pending' | 'active' | 'suspended';
  issuesReported: number;
}

const members: DemoMember[] = [
  { id: '1', name: 'Jane Doe', status: 'active', issuesReported: 4 },
  { id: '2', name: 'John Smith', status: 'pending', issuesReported: 1 },
  { id: '3', name: 'Alice Brown', status: 'active', issuesReported: 9 },
  { id: '4', name: 'Bob Jones', status: 'suspended', issuesReported: 0 },
];

const columns: Column<DemoMember>[] = [
  { key: 'name', header: 'Name', render: (item) => item.name },
  { key: 'status', header: 'Status', render: (item) => item.status },
  { key: 'issuesReported', header: 'Issues reported', render: (item) => item.issuesReported, align: 'right' },
];

const sortableColumns: Column<DemoMember>[] = [
  { key: 'name', header: 'Name', render: (item) => item.name, sortable: true },
  { key: 'status', header: 'Status', render: (item) => item.status, sortable: true },
  {
    key: 'issuesReported',
    header: 'Issues reported',
    render: (item) => item.issuesReported,
    align: 'right',
    sortable: true,
  },
];

const meta = {
  title: 'Organisms/DataTableCard',
  component: DataTableCard<DemoMember>,
} satisfies Meta<typeof DataTableCard<DemoMember>>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Basic: Story = {
  args: {
    columns,
    data: members,
    keyExtractor: (item) => item.id,
    totalItems: members.length,
    currentPage: 1,
    pageSize: 10,
    onPageChange: () => {},
    onPageSizeChange: () => {},
  },
};

export const WithFilterAndAction: Story = {
  args: {
    ...Basic.args,
    filterSlot: <Input label="Search" placeholder="Search members" size="small" />,
    actionSlot: <Button>Invite member</Button>,
  },
};

export const Loading: Story = {
  args: {
    ...Basic.args,
    data: [],
    isLoading: true,
  },
};

export const Empty: Story = {
  args: {
    ...Basic.args,
    data: [],
    totalItems: 0,
    emptyMessage: <EmptyState title="No members yet" description="Invited members will appear here." />,
  },
};

type StatusFilter = 'all' | 'pending' | 'active' | 'suspended';

function WithTabsDemo() {
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all');

  const filtered =
    statusFilter === 'all' ? members : members.filter((m) => m.status === statusFilter);

  const tabs: DataTableTab<StatusFilter>[] = [
    { value: 'all', label: 'All' },
    {
      value: 'pending',
      label: 'Pending',
      badge: members.filter((m) => m.status === 'pending').length,
      badgeColor: 'warning',
    },
    { value: 'active', label: 'Active' },
    { value: 'suspended', label: 'Suspended' },
  ];

  return (
    <DataTableCard
      columns={columns}
      data={filtered}
      keyExtractor={(item) => item.id}
      totalItems={filtered.length}
      currentPage={1}
      pageSize={10}
      onPageChange={() => {}}
      onPageSizeChange={() => {}}
      tabs={{
        tabs,
        value: statusFilter,
        onChange: setStatusFilter,
        ariaLabel: 'Filter by status',
      }}
    />
  );
}

export const WithTabsAndBadges: Story = {
  args: Basic.args,
  render: () => <WithTabsDemo />,
};

function WithSortableColumnsDemo() {
  const [sort, setSort] = useState<SortState>({ key: 'name', direction: 'asc' });

  const handleSortChange = (key: string) => {
    setSort((current) =>
      current.key === key
        ? { key, direction: current.direction === 'asc' ? 'desc' : 'asc' }
        : { key, direction: 'asc' }
    );
  };

  return (
    <DataTableCard
      columns={sortableColumns}
      data={members}
      keyExtractor={(item) => item.id}
      totalItems={members.length}
      currentPage={1}
      pageSize={10}
      onPageChange={() => {}}
      onPageSizeChange={() => {}}
      sort={sort}
      onSortChange={handleSortChange}
    />
  );
}

/** A sortable column, toggled between ascending and descending on click. */
export const WithSortableColumns: Story = {
  args: Basic.args,
  render: () => <WithSortableColumnsDemo />,
};

/** Search and filter controls render but are inert until a caller passes a handler. */
export const WithDisabledSearchAndFilter: Story = {
  args: {
    ...Basic.args,
    search: { value: '', placeholder: 'Search members' },
    filterPanel: {
      content: <Typography>Filtering is not switched on yet.</Typography>,
    },
  },
};

/** The filter drawer, opened via the toolbar's Filters button, with an active filter count. */
export const WithOpenFilterDrawer: Story = {
  args: {
    ...Basic.args,
    search: { value: '', placeholder: 'Search members', onChange: () => {} },
    filterPanel: {
      content: <Typography>Role and status filters go here.</Typography>,
      activeCount: 2,
      onClear: () => {},
    },
  },
  play: async ({ canvasElement, step }) => {
    const { within: withinDom, userEvent } = await import('storybook/test');
    const canvas = withinDom(canvasElement);
    await step('open the filter drawer', async () => {
      await userEvent.click(canvas.getByRole('button', { name: /filters/i }));
    });
  },
};
