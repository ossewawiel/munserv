import { type ReactNode, useCallback } from 'react';
import Box from '@mui/material/Box';
import Paper from '@mui/material/Paper';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';

export interface Column<T> {
  key: string;
  header: string;
  render: (item: T) => ReactNode;
  width?: string | number;
  align?: 'left' | 'center' | 'right';
}

interface DataTableProps<T> {
  readonly columns: readonly Column<T>[];
  readonly data: readonly T[];
  readonly keyExtractor: (item: T) => string;
  readonly onRowClick?: (item: T) => void;
  readonly emptyMessage?: ReactNode;
  /** Use 'embedded' when inside a card (no border/rounded corners) */
  readonly variant?: 'standalone' | 'embedded';
}

export function DataTable<T>({
  columns,
  data,
  keyExtractor,
  onRowClick,
  emptyMessage,
  variant = 'standalone',
}: DataTableProps<T>) {
  const handleRowClick = useCallback(
    (item: T) => {
      if (onRowClick) {
        onRowClick(item);
      }
    },
    [onRowClick]
  );

  if (!data || data.length === 0) {
    if (emptyMessage) {
      return <>{emptyMessage}</>;
    }
    return null;
  }

  const isEmbedded = variant === 'embedded';

  const tableContent = (
    <Table>
      <TableHead>
        <TableRow>
          {columns.map((column) => (
            <TableCell
              key={column.key}
              align={column.align ?? 'left'}
              sx={{
                width: column.width,
                fontWeight: 600,
                bgcolor: 'var(--munserv-palette-background-default)',
              }}
            >
              {column.header}
            </TableCell>
          ))}
        </TableRow>
      </TableHead>
      <TableBody>
        {data.map((item) => (
          <TableRow
            key={keyExtractor(item)}
            onClick={() => handleRowClick(item)}
            hover={!!onRowClick}
            sx={{
              cursor: onRowClick ? 'pointer' : 'default',
              '&:last-child td': { borderBottom: 0 },
            }}
          >
            {columns.map((column) => (
              <TableCell
                key={column.key}
                align={column.align ?? 'left'}
              >
                {column.render(item)}
              </TableCell>
            ))}
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );

  if (isEmbedded) {
    return (
      <TableContainer component={Box}>
        {tableContent}
      </TableContainer>
    );
  }

  return (
    <TableContainer component={Paper} variant="outlined">
      {tableContent}
    </TableContainer>
  );
}
