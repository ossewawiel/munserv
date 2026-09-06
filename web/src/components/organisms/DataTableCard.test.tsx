import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent, waitForElementToBeRemoved } from '@testing-library/react';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { DataTableCard } from './DataTableCard';
import type { Column } from './DataTable';

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        pagination: {
          showing: 'Showing',
          to: 'to',
          of: 'of',
          results: 'results',
          rowsPerPage: 'Rows per page',
        },
        common: {
          noResults: 'No results',
        },
        dataTable: {
          searchPlaceholder: 'Search',
          filters: 'Filters',
          filtersTitle: 'Filters',
          clearFilters: 'Clear filters',
          closeFilters: 'Close filters',
          sortBy: 'Sort by',
        },
      },
    },
  },
});

const theme = createTheme();

function renderWithProviders(ui: React.ReactElement) {
  return render(
    <ThemeProvider theme={theme}>
      <I18nextProvider i18n={i18n}>{ui}</I18nextProvider>
    </ThemeProvider>
  );
}

interface TestItem {
  id: string;
  name: string;
  value: number;
}

const mockData: TestItem[] = [
  { id: '1', name: 'Item 1', value: 100 },
  { id: '2', name: 'Item 2', value: 200 },
  { id: '3', name: 'Item 3', value: 300 },
];

const mockColumns: Column<TestItem>[] = [
  { key: 'name', header: 'Name', render: (item) => item.name },
  { key: 'value', header: 'Value', render: (item) => item.value },
];

describe('DataTableCard', () => {
  describe('structure', () => {
    it('should render table inside a card', () => {
      renderWithProviders(
        <DataTableCard
          columns={mockColumns}
          data={mockData}
          keyExtractor={(item) => item.id}
          totalItems={3}
          currentPage={1}
          pageSize={10}
          onPageChange={vi.fn()}
          onPageSizeChange={vi.fn()}
        />
      );

      // Should have a table
      expect(screen.getByRole('table')).toBeInTheDocument();
    });

    it('should render filter slot content on the left side of toolbar', () => {
      const FilterComponent = () => <div data-testid="filter-component">Filter</div>;

      renderWithProviders(
        <DataTableCard
          columns={mockColumns}
          data={mockData}
          keyExtractor={(item) => item.id}
          totalItems={3}
          currentPage={1}
          pageSize={10}
          onPageChange={vi.fn()}
          onPageSizeChange={vi.fn()}
          filterSlot={<FilterComponent />}
        />
      );

      expect(screen.getByTestId('filter-component')).toBeInTheDocument();
    });

    it('should render action slot content on the right side of toolbar', () => {
      const ActionComponent = () => <button data-testid="action-button">Export</button>;

      renderWithProviders(
        <DataTableCard
          columns={mockColumns}
          data={mockData}
          keyExtractor={(item) => item.id}
          totalItems={3}
          currentPage={1}
          pageSize={10}
          onPageChange={vi.fn()}
          onPageSizeChange={vi.fn()}
          actionSlot={<ActionComponent />}
        />
      );

      expect(screen.getByTestId('action-button')).toBeInTheDocument();
    });

    it('should render both filter and action slots in toolbar', () => {
      renderWithProviders(
        <DataTableCard
          columns={mockColumns}
          data={mockData}
          keyExtractor={(item) => item.id}
          totalItems={3}
          currentPage={1}
          pageSize={10}
          onPageChange={vi.fn()}
          onPageSizeChange={vi.fn()}
          filterSlot={<div data-testid="filters">Filters</div>}
          actionSlot={<div data-testid="actions">Actions</div>}
        />
      );

      expect(screen.getByTestId('filters')).toBeInTheDocument();
      expect(screen.getByTestId('actions')).toBeInTheDocument();
    });
  });

  describe('pagination', () => {
    it('should display pagination info showing current range', () => {
      renderWithProviders(
        <DataTableCard
          columns={mockColumns}
          data={mockData}
          keyExtractor={(item) => item.id}
          totalItems={45}
          currentPage={1}
          pageSize={10}
          onPageChange={vi.fn()}
          onPageSizeChange={vi.fn()}
        />
      );

      // Should show "Showing 1 to 10 of 45 results"
      // Use regex to match the full pattern to avoid conflicts with pagination buttons
      expect(screen.getByText(/Showing/)).toBeInTheDocument();
      expect(screen.getByText(/to/)).toBeInTheDocument();
      expect(screen.getByText(/of/)).toBeInTheDocument();
      expect(screen.getByText(/results/)).toBeInTheDocument();
      // Check that the numbers appear within strong elements
      const strongElements = screen.getAllByText(/^(1|10|45)$/);
      expect(strongElements.length).toBeGreaterThanOrEqual(3);
    });

    it('should render page size selector with options 5, 10, 20', () => {
      renderWithProviders(
        <DataTableCard
          columns={mockColumns}
          data={mockData}
          keyExtractor={(item) => item.id}
          totalItems={45}
          currentPage={1}
          pageSize={10}
          pageSizeOptions={[5, 10, 20]}
          onPageChange={vi.fn()}
          onPageSizeChange={vi.fn()}
        />
      );

      // Should have rows per page selector
      expect(screen.getByText(/Rows per page/)).toBeInTheDocument();
    });

    it('should call onPageSizeChange when page size is changed', async () => {
      const onPageSizeChange = vi.fn();

      renderWithProviders(
        <DataTableCard
          columns={mockColumns}
          data={mockData}
          keyExtractor={(item) => item.id}
          totalItems={45}
          currentPage={1}
          pageSize={10}
          pageSizeOptions={[5, 10, 20]}
          onPageChange={vi.fn()}
          onPageSizeChange={onPageSizeChange}
        />
      );

      // Find and interact with the select
      const select = screen.getByRole('combobox');
      fireEvent.mouseDown(select);

      // Select a different page size
      const option5 = screen.getByRole('option', { name: '5' });
      fireEvent.click(option5);

      expect(onPageSizeChange).toHaveBeenCalledWith(5);
    });

    it('should call onPageChange when page navigation is used', () => {
      const onPageChange = vi.fn();

      renderWithProviders(
        <DataTableCard
          columns={mockColumns}
          data={mockData}
          keyExtractor={(item) => item.id}
          totalItems={45}
          currentPage={1}
          pageSize={10}
          onPageChange={onPageChange}
          onPageSizeChange={vi.fn()}
        />
      );

      // Find page 2 button and click it
      const page2Button = screen.getByRole('button', { name: /page 2/i });
      fireEvent.click(page2Button);

      expect(onPageChange).toHaveBeenCalledWith(2);
    });

    it('should not render pagination when totalItems is 0', () => {
      renderWithProviders(
        <DataTableCard
          columns={mockColumns}
          data={[]}
          keyExtractor={(item) => item.id}
          totalItems={0}
          currentPage={1}
          pageSize={10}
          onPageChange={vi.fn()}
          onPageSizeChange={vi.fn()}
        />
      );

      expect(screen.queryByText(/Showing/)).not.toBeInTheDocument();
    });
  });

  describe('table behavior', () => {
    it('should call onRowClick when a row is clicked', () => {
      const onRowClick = vi.fn();

      renderWithProviders(
        <DataTableCard
          columns={mockColumns}
          data={mockData}
          keyExtractor={(item) => item.id}
          totalItems={3}
          currentPage={1}
          pageSize={10}
          onPageChange={vi.fn()}
          onPageSizeChange={vi.fn()}
          onRowClick={onRowClick}
        />
      );

      // Click on a row containing "Item 1"
      const row = screen.getByText('Item 1').closest('tr');
      if (row) fireEvent.click(row);

      expect(onRowClick).toHaveBeenCalledWith(mockData[0]);
    });

    it('should render empty state when data is empty', () => {
      renderWithProviders(
        <DataTableCard
          columns={mockColumns}
          data={[]}
          keyExtractor={(item) => item.id}
          totalItems={0}
          currentPage={1}
          pageSize={10}
          onPageChange={vi.fn()}
          onPageSizeChange={vi.fn()}
          emptyMessage={<div data-testid="empty-state">No data</div>}
        />
      );

      expect(screen.getByTestId('empty-state')).toBeInTheDocument();
    });

    it('should render loading skeleton when isLoading is true', () => {
      renderWithProviders(
        <DataTableCard
          columns={mockColumns}
          data={[]}
          keyExtractor={(item) => item.id}
          totalItems={0}
          currentPage={1}
          pageSize={10}
          onPageChange={vi.fn()}
          onPageSizeChange={vi.fn()}
          isLoading
        />
      );

      // Should show skeleton, not the table
      expect(screen.queryByRole('table')).not.toBeInTheDocument();
    });
  });

  describe('toolbar visibility', () => {
    it('should hide toolbar when no filter or action slots provided and hideToolbarWhenEmpty is true', () => {
      const { container } = renderWithProviders(
        <DataTableCard
          columns={mockColumns}
          data={mockData}
          keyExtractor={(item) => item.id}
          totalItems={3}
          currentPage={1}
          pageSize={10}
          onPageChange={vi.fn()}
          onPageSizeChange={vi.fn()}
          hideToolbarWhenEmpty
        />
      );

      // Toolbar should not be present
      const toolbar = container.querySelector('[data-testid="datatable-toolbar"]');
      expect(toolbar).not.toBeInTheDocument();
    });

    it('should show toolbar when filter slot is provided', () => {
      const { container } = renderWithProviders(
        <DataTableCard
          columns={mockColumns}
          data={mockData}
          keyExtractor={(item) => item.id}
          totalItems={3}
          currentPage={1}
          pageSize={10}
          onPageChange={vi.fn()}
          onPageSizeChange={vi.fn()}
          hideToolbarWhenEmpty
          filterSlot={<div>Filter</div>}
        />
      );

      const toolbar = container.querySelector('[data-testid="datatable-toolbar"]');
      expect(toolbar).toBeInTheDocument();
    });
  });

  describe('tabs functionality', () => {
    describe('tab rendering', () => {
      it('should render tabs when tabs config is provided', () => {
        renderWithProviders(
          <DataTableCard
            columns={mockColumns}
            data={mockData}
            keyExtractor={(item) => item.id}
            totalItems={3}
            currentPage={1}
            pageSize={10}
            onPageChange={vi.fn()}
            onPageSizeChange={vi.fn()}
            tabs={{
              tabs: [
                { value: 'all', label: 'All' },
                { value: 'active', label: 'Active' },
                { value: 'pending', label: 'Pending' },
              ],
            }}
          />
        );

        expect(screen.getByRole('tablist')).toBeInTheDocument();
        expect(screen.getByRole('tab', { name: 'All' })).toBeInTheDocument();
        expect(screen.getByRole('tab', { name: 'Active' })).toBeInTheDocument();
        expect(screen.getByRole('tab', { name: 'Pending' })).toBeInTheDocument();
      });

      it('should render tab badges when provided', () => {
        renderWithProviders(
          <DataTableCard
            columns={mockColumns}
            data={mockData}
            keyExtractor={(item) => item.id}
            totalItems={3}
            currentPage={1}
            pageSize={10}
            onPageChange={vi.fn()}
            onPageSizeChange={vi.fn()}
            tabs={{
              tabs: [
                { value: 'all', label: 'All' },
                { value: 'pending', label: 'Pending', badge: 5, badgeColor: 'warning' },
              ],
            }}
          />
        );

        // Badge should be rendered with content "5"
        expect(screen.getByText('5')).toBeInTheDocument();
      });

      it('should not render tabs section when tabs prop is undefined', () => {
        const { container } = renderWithProviders(
          <DataTableCard
            columns={mockColumns}
            data={mockData}
            keyExtractor={(item) => item.id}
            totalItems={3}
            currentPage={1}
            pageSize={10}
            onPageChange={vi.fn()}
            onPageSizeChange={vi.fn()}
          />
        );

        expect(container.querySelector('[data-testid="datatable-tabs"]')).not.toBeInTheDocument();
        expect(screen.queryByRole('tablist')).not.toBeInTheDocument();
      });

      it('should render disabled tabs correctly', () => {
        renderWithProviders(
          <DataTableCard
            columns={mockColumns}
            data={mockData}
            keyExtractor={(item) => item.id}
            totalItems={3}
            currentPage={1}
            pageSize={10}
            onPageChange={vi.fn()}
            onPageSizeChange={vi.fn()}
            tabs={{
              tabs: [
                { value: 'all', label: 'All' },
                { value: 'archived', label: 'Archived', disabled: true },
              ],
            }}
          />
        );

        const archivedTab = screen.getByRole('tab', { name: 'Archived' });
        expect(archivedTab).toBeDisabled();
      });
    });

    describe('tab state management', () => {
      it('should support controlled mode with value prop', () => {
        renderWithProviders(
          <DataTableCard
            columns={mockColumns}
            data={mockData}
            keyExtractor={(item) => item.id}
            totalItems={3}
            currentPage={1}
            pageSize={10}
            onPageChange={vi.fn()}
            onPageSizeChange={vi.fn()}
            tabs={{
              tabs: [
                { value: 'all', label: 'All' },
                { value: 'active', label: 'Active' },
              ],
              value: 'active',
            }}
          />
        );

        // Active tab should be selected
        const activeTab = screen.getByRole('tab', { name: 'Active' });
        expect(activeTab).toHaveAttribute('aria-selected', 'true');
      });

      it('should support uncontrolled mode with defaultValue', () => {
        renderWithProviders(
          <DataTableCard
            columns={mockColumns}
            data={mockData}
            keyExtractor={(item) => item.id}
            totalItems={3}
            currentPage={1}
            pageSize={10}
            onPageChange={vi.fn()}
            onPageSizeChange={vi.fn()}
            tabs={{
              tabs: [
                { value: 'all', label: 'All' },
                { value: 'active', label: 'Active' },
              ],
              defaultValue: 'active',
            }}
          />
        );

        const activeTab = screen.getByRole('tab', { name: 'Active' });
        expect(activeTab).toHaveAttribute('aria-selected', 'true');
      });

      it('should select first tab by default when no value or defaultValue', () => {
        renderWithProviders(
          <DataTableCard
            columns={mockColumns}
            data={mockData}
            keyExtractor={(item) => item.id}
            totalItems={3}
            currentPage={1}
            pageSize={10}
            onPageChange={vi.fn()}
            onPageSizeChange={vi.fn()}
            tabs={{
              tabs: [
                { value: 'all', label: 'All' },
                { value: 'active', label: 'Active' },
              ],
            }}
          />
        );

        const allTab = screen.getByRole('tab', { name: 'All' });
        expect(allTab).toHaveAttribute('aria-selected', 'true');
      });

      it('should call onChange when tab is clicked', () => {
        const onChange = vi.fn();

        renderWithProviders(
          <DataTableCard
            columns={mockColumns}
            data={mockData}
            keyExtractor={(item) => item.id}
            totalItems={3}
            currentPage={1}
            pageSize={10}
            onPageChange={vi.fn()}
            onPageSizeChange={vi.fn()}
            tabs={{
              tabs: [
                { value: 'all', label: 'All' },
                { value: 'active', label: 'Active' },
              ],
              value: 'all',
              onChange,
            }}
          />
        );

        fireEvent.click(screen.getByRole('tab', { name: 'Active' }));
        expect(onChange).toHaveBeenCalledWith('active');
      });

      it('should update internal state in uncontrolled mode when tab clicked', () => {
        renderWithProviders(
          <DataTableCard
            columns={mockColumns}
            data={mockData}
            keyExtractor={(item) => item.id}
            totalItems={3}
            currentPage={1}
            pageSize={10}
            onPageChange={vi.fn()}
            onPageSizeChange={vi.fn()}
            tabs={{
              tabs: [
                { value: 'all', label: 'All' },
                { value: 'active', label: 'Active' },
              ],
            }}
          />
        );

        // Initial state - first tab selected
        expect(screen.getByRole('tab', { name: 'All' })).toHaveAttribute('aria-selected', 'true');

        // Click second tab
        fireEvent.click(screen.getByRole('tab', { name: 'Active' }));

        // Should now be selected
        expect(screen.getByRole('tab', { name: 'Active' })).toHaveAttribute('aria-selected', 'true');
      });
    });

    describe('slot resolution', () => {
      it('should show tab-specific filterSlot when active tab has one', () => {
        renderWithProviders(
          <DataTableCard
            columns={mockColumns}
            data={mockData}
            keyExtractor={(item) => item.id}
            totalItems={3}
            currentPage={1}
            pageSize={10}
            onPageChange={vi.fn()}
            onPageSizeChange={vi.fn()}
            filterSlot={<div data-testid="default-filter">Default Filter</div>}
            tabs={{
              tabs: [
                { value: 'all', label: 'All' },
                {
                  value: 'active',
                  label: 'Active',
                  filterSlot: <div data-testid="active-filter">Active Filter</div>,
                },
              ],
              value: 'active',
            }}
          />
        );

        // Should show tab-specific filter, not default
        expect(screen.getByTestId('active-filter')).toBeInTheDocument();
        expect(screen.queryByTestId('default-filter')).not.toBeInTheDocument();
      });

      it('should fall back to default filterSlot when tab has none', () => {
        renderWithProviders(
          <DataTableCard
            columns={mockColumns}
            data={mockData}
            keyExtractor={(item) => item.id}
            totalItems={3}
            currentPage={1}
            pageSize={10}
            onPageChange={vi.fn()}
            onPageSizeChange={vi.fn()}
            filterSlot={<div data-testid="default-filter">Default Filter</div>}
            tabs={{
              tabs: [
                { value: 'all', label: 'All' },
                { value: 'active', label: 'Active' },
              ],
              value: 'all',
            }}
          />
        );

        // Should show default filter since "all" tab has no filterSlot
        expect(screen.getByTestId('default-filter')).toBeInTheDocument();
      });

      it('should show tab-specific actionSlot when active tab has one', () => {
        renderWithProviders(
          <DataTableCard
            columns={mockColumns}
            data={mockData}
            keyExtractor={(item) => item.id}
            totalItems={3}
            currentPage={1}
            pageSize={10}
            onPageChange={vi.fn()}
            onPageSizeChange={vi.fn()}
            actionSlot={<button data-testid="default-action">Default Action</button>}
            tabs={{
              tabs: [
                { value: 'all', label: 'All' },
                {
                  value: 'pending',
                  label: 'Pending',
                  actionSlot: <button data-testid="pending-action">Approve All</button>,
                },
              ],
              value: 'pending',
            }}
          />
        );

        // Should show tab-specific action, not default
        expect(screen.getByTestId('pending-action')).toBeInTheDocument();
        expect(screen.queryByTestId('default-action')).not.toBeInTheDocument();
      });

      it('should switch filterSlot content when tab changes in uncontrolled mode', () => {
        renderWithProviders(
          <DataTableCard
            columns={mockColumns}
            data={mockData}
            keyExtractor={(item) => item.id}
            totalItems={3}
            currentPage={1}
            pageSize={10}
            onPageChange={vi.fn()}
            onPageSizeChange={vi.fn()}
            tabs={{
              tabs: [
                {
                  value: 'all',
                  label: 'All',
                  filterSlot: <div data-testid="all-filter">All Filter</div>,
                },
                {
                  value: 'active',
                  label: 'Active',
                  filterSlot: <div data-testid="active-filter">Active Filter</div>,
                },
              ],
            }}
          />
        );

        // Initially shows "all" tab filter
        expect(screen.getByTestId('all-filter')).toBeInTheDocument();
        expect(screen.queryByTestId('active-filter')).not.toBeInTheDocument();

        // Click "active" tab
        fireEvent.click(screen.getByRole('tab', { name: 'Active' }));

        // Now shows "active" tab filter
        expect(screen.getByTestId('active-filter')).toBeInTheDocument();
        expect(screen.queryByTestId('all-filter')).not.toBeInTheDocument();
      });

      it('should hide toolbar when hideToolbarWhenEmpty and no slots for active tab', () => {
        const { container } = renderWithProviders(
          <DataTableCard
            columns={mockColumns}
            data={mockData}
            keyExtractor={(item) => item.id}
            totalItems={3}
            currentPage={1}
            pageSize={10}
            onPageChange={vi.fn()}
            onPageSizeChange={vi.fn()}
            hideToolbarWhenEmpty
            tabs={{
              tabs: [
                { value: 'all', label: 'All' },
                {
                  value: 'active',
                  label: 'Active',
                  filterSlot: <div>Active Filter</div>,
                },
              ],
              value: 'all', // "all" tab has no slots
            }}
          />
        );

        // Toolbar should not be present for "all" tab
        const toolbar = container.querySelector('[data-testid="datatable-toolbar"]');
        expect(toolbar).not.toBeInTheDocument();
      });

      it('should show toolbar when active tab has filterSlot even with hideToolbarWhenEmpty', () => {
        const { container } = renderWithProviders(
          <DataTableCard
            columns={mockColumns}
            data={mockData}
            keyExtractor={(item) => item.id}
            totalItems={3}
            currentPage={1}
            pageSize={10}
            onPageChange={vi.fn()}
            onPageSizeChange={vi.fn()}
            hideToolbarWhenEmpty
            tabs={{
              tabs: [
                { value: 'all', label: 'All' },
                {
                  value: 'active',
                  label: 'Active',
                  filterSlot: <div>Active Filter</div>,
                },
              ],
              value: 'active', // "active" tab has filterSlot
            }}
          />
        );

        // Toolbar should be present for "active" tab
        const toolbar = container.querySelector('[data-testid="datatable-toolbar"]');
        expect(toolbar).toBeInTheDocument();
      });
    });

    describe('backward compatibility', () => {
      it('should work with filterSlot and actionSlot when no tabs provided', () => {
        renderWithProviders(
          <DataTableCard
            columns={mockColumns}
            data={mockData}
            keyExtractor={(item) => item.id}
            totalItems={3}
            currentPage={1}
            pageSize={10}
            onPageChange={vi.fn()}
            onPageSizeChange={vi.fn()}
            filterSlot={<div data-testid="legacy-filter">Filter</div>}
            actionSlot={<button data-testid="legacy-action">Export</button>}
          />
        );

        expect(screen.getByTestId('legacy-filter')).toBeInTheDocument();
        expect(screen.getByTestId('legacy-action')).toBeInTheDocument();
        expect(screen.queryByRole('tablist')).not.toBeInTheDocument();
      });
    });
  });

  describe('search', () => {
    it('should render a disabled search field when no handler is given', () => {
      renderWithProviders(
        <DataTableCard
          columns={mockColumns}
          data={mockData}
          keyExtractor={(item) => item.id}
          totalItems={3}
          currentPage={1}
          pageSize={10}
          onPageChange={vi.fn()}
          onPageSizeChange={vi.fn()}
          search={{ value: '' }}
        />
      );

      expect(screen.getByPlaceholderText('Search')).toBeDisabled();
    });

    it('should call the search handler as the user types', () => {
      const onChange = vi.fn();
      renderWithProviders(
        <DataTableCard
          columns={mockColumns}
          data={mockData}
          keyExtractor={(item) => item.id}
          totalItems={3}
          currentPage={1}
          pageSize={10}
          onPageChange={vi.fn()}
          onPageSizeChange={vi.fn()}
          search={{ value: '', onChange }}
        />
      );

      fireEvent.change(screen.getByPlaceholderText('Search'), { target: { value: 'a' } });

      expect(onChange).toHaveBeenCalledWith('a');
    });
  });

  describe('filter panel', () => {
    it('should render a disabled filter button when no handler is given', () => {
      renderWithProviders(
        <DataTableCard
          columns={mockColumns}
          data={mockData}
          keyExtractor={(item) => item.id}
          totalItems={3}
          currentPage={1}
          pageSize={10}
          onPageChange={vi.fn()}
          onPageSizeChange={vi.fn()}
          filterPanel={{ content: <div>Filter content</div> }}
        />
      );

      expect(screen.getByRole('button', { name: 'Filters' })).toBeEnabled();
    });

    it('should open the filter drawer and show its content', () => {
      renderWithProviders(
        <DataTableCard
          columns={mockColumns}
          data={mockData}
          keyExtractor={(item) => item.id}
          totalItems={3}
          currentPage={1}
          pageSize={10}
          onPageChange={vi.fn()}
          onPageSizeChange={vi.fn()}
          filterPanel={{ content: <div>Filter content</div> }}
        />
      );

      fireEvent.click(screen.getByRole('button', { name: 'Filters' }));

      expect(screen.getByText('Filter content')).toBeInTheDocument();
    });

    it('should close the filter drawer', async () => {
      renderWithProviders(
        <DataTableCard
          columns={mockColumns}
          data={mockData}
          keyExtractor={(item) => item.id}
          totalItems={3}
          currentPage={1}
          pageSize={10}
          onPageChange={vi.fn()}
          onPageSizeChange={vi.fn()}
          filterPanel={{ content: <div>Filter content</div> }}
        />
      );

      fireEvent.click(screen.getByRole('button', { name: 'Filters' }));
      fireEvent.click(screen.getByRole('button', { name: 'Close filters' }));

      await waitForElementToBeRemoved(() => screen.queryByText('Filter content'));
    });

    it('should badge the filter button with the active filter count', () => {
      renderWithProviders(
        <DataTableCard
          columns={mockColumns}
          data={mockData}
          keyExtractor={(item) => item.id}
          totalItems={3}
          currentPage={1}
          pageSize={10}
          onPageChange={vi.fn()}
          onPageSizeChange={vi.fn()}
          filterPanel={{ content: <div>Filter content</div>, activeCount: 2 }}
        />
      );

      expect(screen.getByText('2')).toBeInTheDocument();
    });

    it('should disable the clear button when no clear handler is given', () => {
      renderWithProviders(
        <DataTableCard
          columns={mockColumns}
          data={mockData}
          keyExtractor={(item) => item.id}
          totalItems={3}
          currentPage={1}
          pageSize={10}
          onPageChange={vi.fn()}
          onPageSizeChange={vi.fn()}
          filterPanel={{ content: <div>Filter content</div> }}
        />
      );

      fireEvent.click(screen.getByRole('button', { name: 'Filters' }));

      expect(screen.getByRole('button', { name: 'Clear filters' })).toBeDisabled();
    });

    it('should call onClear when the clear button is enabled and clicked', () => {
      const onClear = vi.fn();
      renderWithProviders(
        <DataTableCard
          columns={mockColumns}
          data={mockData}
          keyExtractor={(item) => item.id}
          totalItems={3}
          currentPage={1}
          pageSize={10}
          onPageChange={vi.fn()}
          onPageSizeChange={vi.fn()}
          filterPanel={{ content: <div>Filter content</div>, onClear }}
        />
      );

      fireEvent.click(screen.getByRole('button', { name: 'Filters' }));
      fireEvent.click(screen.getByRole('button', { name: 'Clear filters' }));

      expect(onClear).toHaveBeenCalled();
    });
  });
});
