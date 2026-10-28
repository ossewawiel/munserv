import { describe, it, expect, vi } from 'vitest';
import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ThemeProvider, createTheme } from '@mui/material/styles';

import { DataTable, type Column } from './DataTable';

const theme = createTheme();

function renderWithTheme(ui: React.ReactElement) {
  return render(<ThemeProvider theme={theme}>{ui}</ThemeProvider>);
}

interface TestItem {
  id: string;
  name: string;
  value: number;
}

const mockData: TestItem[] = [
  { id: '1', name: 'Bravo', value: 200 },
  { id: '2', name: 'Alpha', value: 100 },
  { id: '3', name: 'Charlie', value: 300 },
];

const columns: Column<TestItem>[] = [
  { key: 'name', header: 'Name', render: (item) => item.name, sortable: true },
  { key: 'value', header: 'Value', render: (item) => item.value },
];

describe('DataTable', () => {
  it('should render a sort label only for sortable columns', () => {
    renderWithTheme(<DataTable columns={columns} data={mockData} keyExtractor={(item) => item.id} />);

    const nameHeader = screen.getByRole('columnheader', { name: 'Name' });
    const valueHeader = screen.getByRole('columnheader', { name: 'Value' });

    expect(within(nameHeader).getByRole('button')).toBeInTheDocument();
    expect(within(valueHeader).queryByRole('button')).not.toBeInTheDocument();
  });

  it('should disable the sort label when no sort handler is given', () => {
    renderWithTheme(<DataTable columns={columns} data={mockData} keyExtractor={(item) => item.id} />);

    const nameHeader = screen.getByRole('columnheader', { name: 'Name' });
    expect(within(nameHeader).getByRole('button')).toHaveAttribute('aria-disabled', 'true');
  });

  it('should call onSortChange with the column key when a sortable header is clicked', async () => {
    const onSortChange = vi.fn();
    const user = userEvent.setup();
    renderWithTheme(
      <DataTable
        columns={columns}
        data={mockData}
        keyExtractor={(item) => item.id}
        onSortChange={onSortChange}
      />
    );

    const nameHeader = screen.getByRole('columnheader', { name: 'Name' });
    await user.click(within(nameHeader).getByRole('button'));

    expect(onSortChange).toHaveBeenCalledWith('name');
  });

  it('should not reorder the rows it is given', () => {
    renderWithTheme(
      <DataTable
        columns={columns}
        data={mockData}
        keyExtractor={(item) => item.id}
        sort={{ key: 'name', direction: 'asc' }}
      />
    );

    const rows = screen.getAllByRole('row').slice(1); // skip header row
    const names = rows.map((row) => within(row).getAllByRole('cell')[0].textContent);

    expect(names).toEqual(['Bravo', 'Alpha', 'Charlie']);
  });
});
