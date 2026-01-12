import { type ReactNode, useCallback, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import Badge from '@mui/material/Badge';
import Box from '@mui/material/Box';
import Divider from '@mui/material/Divider';
import FormControl from '@mui/material/FormControl';
import MenuItem from '@mui/material/MenuItem';
import MuiPagination from '@mui/material/Pagination';
import Select, { type SelectChangeEvent } from '@mui/material/Select';
import Tab from '@mui/material/Tab';
import Tabs from '@mui/material/Tabs';
import Typography from '@mui/material/Typography';

import { MainCard } from '@/components/atoms/MainCard';
import { TableSkeleton } from '@/components/molecules/LoadingSkeleton';
import { DataTable, type Column } from './DataTable';

const DEFAULT_PAGE_SIZE_OPTIONS = [5, 10, 20] as const;

/**
 * Configuration for a single tab in DataTableCard
 */
export interface DataTableTab<TValue extends string = string> {
  /** Unique identifier for the tab (used as value) */
  readonly value: TValue;
  /** Display label for the tab */
  readonly label: ReactNode;
  /** Optional badge content (e.g., count) */
  readonly badge?: number | string;
  /** Badge color variant */
  readonly badgeColor?:
    | 'default'
    | 'primary'
    | 'secondary'
    | 'error'
    | 'info'
    | 'success'
    | 'warning';
  /** Content for left side of toolbar (filters, search) when this tab is active */
  readonly filterSlot?: ReactNode;
  /** Content for right side of toolbar (action buttons) when this tab is active */
  readonly actionSlot?: ReactNode;
  /** Whether the tab is disabled */
  readonly disabled?: boolean;
}

/**
 * Configuration for the tabs section of DataTableCard
 */
export interface DataTableTabsConfig<TValue extends string = string> {
  /** Array of tab configurations */
  readonly tabs: readonly DataTableTab<TValue>[];
  /** Currently active tab value (controlled mode) */
  readonly value?: TValue;
  /** Default active tab value (uncontrolled mode) */
  readonly defaultValue?: TValue;
  /** Callback when tab changes */
  readonly onChange?: (value: TValue) => void;
  /** Accessibility label for the tabs container */
  readonly ariaLabel?: string;
}

export interface DataTableCardProps<T, TTabValue extends string = string> {
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
  /**
   * Content for left side of toolbar (filters, search).
   * When tabs are present, this serves as the DEFAULT filter slot
   * shown when no tab-specific filterSlot is defined.
   */
  readonly filterSlot?: ReactNode;
  /**
   * Content for right side of toolbar (action buttons).
   * When tabs are present, this serves as the DEFAULT action slot
   * shown when no tab-specific actionSlot is defined.
   */
  readonly actionSlot?: ReactNode;
  /** Message to display when data is empty */
  readonly emptyMessage?: ReactNode;
  /** Loading state */
  readonly isLoading?: boolean;
  /** Hide toolbar when no filter/action slots provided */
  readonly hideToolbarWhenEmpty?: boolean;
  /** Card title (optional) */
  readonly title?: ReactNode;
  /** Tab configuration - when provided, tabs appear above the toolbar */
  readonly tabs?: DataTableTabsConfig<TTabValue>;
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

export function DataTableCard<T, TTabValue extends string = string>({
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
  filterSlot: defaultFilterSlot,
  actionSlot: defaultActionSlot,
  emptyMessage,
  isLoading = false,
  hideToolbarWhenEmpty = false,
  title,
  tabs,
}: DataTableCardProps<T, TTabValue>) {
  // Tab state management (uncontrolled mode)
  const [internalTabValue, setInternalTabValue] = useState<TTabValue | undefined>(
    tabs?.defaultValue ?? tabs?.tabs[0]?.value
  );

  // Determine if controlled or uncontrolled
  const isControlled = tabs?.value !== undefined;
  const activeTabValue = isControlled ? tabs.value : internalTabValue;

  // Find active tab configuration
  const activeTab = useMemo(
    () => tabs?.tabs.find((tab) => tab.value === activeTabValue),
    [tabs?.tabs, activeTabValue]
  );

  // Handle tab change
  const handleTabChange = useCallback(
    (_event: React.SyntheticEvent, newValue: TTabValue) => {
      if (!isControlled) {
        setInternalTabValue(newValue);
      }
      tabs?.onChange?.(newValue);
    },
    [isControlled, tabs]
  );

  // Resolve which filter/action slots to show (tab-specific overrides default)
  const resolvedFilterSlot = activeTab?.filterSlot ?? defaultFilterSlot;
  const resolvedActionSlot = activeTab?.actionSlot ?? defaultActionSlot;

  const showToolbar = !hideToolbarWhenEmpty || resolvedFilterSlot || resolvedActionSlot;
  const totalPages = Math.ceil(totalItems / pageSize);

  return (
    <MainCard
      title={title}
      divider={!!title}
      contentSx={{ p: 0, '&:last-child': { pb: 0 } }}
    >
      {/* Tabs Section */}
      {tabs && (
        <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
          <Tabs
            value={activeTabValue}
            onChange={handleTabChange}
            aria-label={tabs.ariaLabel}
            data-testid="datatable-tabs"
          >
            {tabs.tabs.map((tab) => (
              <Tab
                key={tab.value}
                value={tab.value}
                disabled={tab.disabled}
                sx={
                  tab.badge !== undefined
                    ? { pr: 4, minWidth: 'auto' } // Extra padding for badge
                    : undefined
                }
                label={
                  tab.badge !== undefined ? (
                    <Badge
                      badgeContent={tab.badge}
                      color={tab.badgeColor ?? 'primary'}
                      sx={{
                        '& .MuiBadge-badge': {
                          right: -16,
                          top: 2,
                          minWidth: 20,
                          height: 20,
                          fontSize: '0.75rem',
                        },
                      }}
                    >
                      {tab.label}
                    </Badge>
                  ) : (
                    tab.label
                  )
                }
              />
            ))}
          </Tabs>
        </Box>
      )}

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
              {resolvedFilterSlot}
            </Box>

            {/* Action slot - right side */}
            {resolvedActionSlot && (
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                {resolvedActionSlot}
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
