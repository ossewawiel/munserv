import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
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
});
