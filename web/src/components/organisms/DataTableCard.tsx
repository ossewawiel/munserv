import { type ReactNode, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Divider from '@mui/material/Divider';
import FormControl from '@mui/material/FormControl';
import MenuItem from '@mui/material/MenuItem';
import MuiPagination from '@mui/material/Pagination';
import Select, { type SelectChangeEvent } from '@mui/material/Select';
import Typography from '@mui/material/Typography';

import { MainCard } from '@/components/atoms/MainCard';
import { TableSkeleton } from '@/components/molecules/LoadingSkeleton';
import { DataTable, type Column } from './DataTable';

const DEFAULT_PAGE_SIZE_OPTIONS = [5, 10, 20] as const;

export interface DataTableCardProps<T> {
  /** Table columns configuration */
  readonly columns: readonly Column<T>[];
  /** Data to display */
  readonly data: readonly T[];
  /** Function to extract unique key from each item */
  readonly keyExtractor: (item: T) => string;
  /** Total number of items (for pagination) */
  readonly totalItems: number;
  /** Current page number (1-indexed) */
  readonly currentPage: number;
  /** Current page size */
  readonly pageSize: number;
  /** Available page size options */
  readonly pageSizeOptions?: readonly number[];
  /** Callback when page changes */
  readonly onPageChange: (page: number) => void;
  /** Callback when page size changes */
  readonly onPageSizeChange: (pageSize: number) => void;
  /** Optional callback when row is clicked */
  readonly onRowClick?: (item: T) => void;
  /** Content for left side of toolbar (filters, search) */
  readonly filterSlot?: ReactNode;
  /** Content for right side of toolbar (action buttons) */
  readonly actionSlot?: ReactNode;
  /** Message to display when data is empty */
  readonly emptyMessage?: ReactNode;
  /** Loading state */
  readonly isLoading?: boolean;
  /** Hide toolbar when no filter/action slots provided */
  readonly hideToolbarWhenEmpty?: boolean;
  /** Card title (optional) */
  readonly title?: ReactNode;
}

interface PaginationFooterProps {
  currentPage: number;
  totalPages: number;
  totalItems: number;
  pageSize: number;
  pageSizeOptions: readonly number[];
  onPageChange: (page: number) => void;
  onPageSizeChange: (pageSize: number) => void;
}

function PaginationFooter({
  currentPage,
  totalPages,
  totalItems,
  pageSize,
  pageSizeOptions,
  onPageChange,
  onPageSizeChange,
}: PaginationFooterProps) {
  const { t } = useTranslation();

  const startItem = (currentPage - 1) * pageSize + 1;
  const endItem = Math.min(currentPage * pageSize, totalItems);

  const handlePageChange = useCallback(
    (_event: React.ChangeEvent<unknown>, page: number) => {
      onPageChange(page);
    },
    [onPageChange]
  );

  const handlePageSizeChange = useCallback(
    (event: SelectChangeEvent<number>) => {
      onPageSizeChange(Number(event.target.value));
    },
    [onPageSizeChange]
  );

  if (totalItems === 0) return null;

  return (
    <Box
      sx={{
        display: 'flex',
        flexDirection: { xs: 'column', sm: 'row' },
        alignItems: 'center',
        justifyContent: 'space-between',
        gap: 2,
        px: 2,
        py: 1.5,
      }}
    >
      <Typography variant="body2" color="text.secondary">
        {t('pagination.showing')} <strong>{startItem}</strong>{' '}
        {t('pagination.to')} <strong>{endItem}</strong>{' '}
        {t('pagination.of')} <strong>{totalItems}</strong>{' '}
        {t('pagination.results')}
      </Typography>

      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Typography variant="body2" color="text.secondary">
            {t('pagination.rowsPerPage')}
          </Typography>
          <FormControl size="small" variant="outlined">
            <Select
              value={pageSize}
              onChange={handlePageSizeChange}
              sx={{ minWidth: 70 }}
            >
              {pageSizeOptions.map((option) => (
                <MenuItem key={option} value={option}>
                  {option}
                </MenuItem>
              ))}
            </Select>
          </FormControl>
        </Box>

        {totalPages > 1 && (
          <MuiPagination
            count={totalPages}
            page={currentPage}
            onChange={handlePageChange}
            color="primary"
            size="small"
            showFirstButton
            showLastButton
          />
        )}
      </Box>
    </Box>
  );
}

export function DataTableCard<T>({
  columns,
  data,
  keyExtractor,
  totalItems,
  currentPage,
  pageSize,
  pageSizeOptions = DEFAULT_PAGE_SIZE_OPTIONS,
  onPageChange,
  onPageSizeChange,
  onRowClick,
  filterSlot,
  actionSlot,
  emptyMessage,
  isLoading = false,
  hideToolbarWhenEmpty = false,
  title,
}: DataTableCardProps<T>) {
  const showToolbar = !hideToolbarWhenEmpty || filterSlot || actionSlot;
  const totalPages = Math.ceil(totalItems / pageSize);

  return (
    <MainCard
      title={title}
      divider={!!title}
      contentSx={{ p: 0, '&:last-child': { pb: 0 } }}
    >
      {/* Toolbar */}
      {showToolbar && (
        <>
          <Box
            data-testid="datatable-toolbar"
            sx={{
              display: 'flex',
              flexDirection: { xs: 'column', sm: 'row' },
              alignItems: { xs: 'stretch', sm: 'center' },
              justifyContent: 'space-between',
              gap: 2,
              p: 2,
            }}
          >
            {/* Filter slot - left side */}
            <Box sx={{ display: 'flex', flexWrap: 'wrap', alignItems: 'center', gap: 2 }}>
              {filterSlot}
            </Box>

            {/* Action slot - right side */}
            {actionSlot && (
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                {actionSlot}
              </Box>
            )}
          </Box>
          <Divider />
        </>
      )}

      {/* Loading State */}
      {isLoading && (
        <Box sx={{ p: 2 }}>
          <TableSkeleton rows={5} columns={columns.length} />
        </Box>
      )}

      {/* Table */}
      {!isLoading && (
        <DataTable
          columns={columns}
          data={data}
          keyExtractor={keyExtractor}
          onRowClick={onRowClick}
          emptyMessage={emptyMessage}
          variant="embedded"
        />
      )}

      {/* Pagination Footer */}
      {!isLoading && totalItems > 0 && (
        <>
          <Divider />
          <PaginationFooter
            currentPage={currentPage}
            totalPages={totalPages}
            totalItems={totalItems}
            pageSize={pageSize}
            pageSizeOptions={pageSizeOptions}
            onPageChange={onPageChange}
            onPageSizeChange={onPageSizeChange}
          />
        </>
      )}
    </MainCard>
  );
}
