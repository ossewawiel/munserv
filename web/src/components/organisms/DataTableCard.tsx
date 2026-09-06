import { type ChangeEvent, type ReactNode, useCallback, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import Badge from '@mui/material/Badge';
import Box from '@mui/material/Box';
import Divider from '@mui/material/Divider';
import Drawer from '@mui/material/Drawer';
import FormControl from '@mui/material/FormControl';
import IconButton from '@mui/material/IconButton';
import MenuItem from '@mui/material/MenuItem';
import MuiPagination from '@mui/material/Pagination';
import Select, { type SelectChangeEvent } from '@mui/material/Select';
import Tab from '@mui/material/Tab';
import Tabs from '@mui/material/Tabs';
import Typography from '@mui/material/Typography';
import CloseIcon from '@mui/icons-material/Close';
import FilterListIcon from '@mui/icons-material/FilterList';
import SearchIcon from '@mui/icons-material/Search';

import { ActionButton } from '@/components/atoms/ActionButton';
import { Input } from '@/components/atoms/Input';
import { MainCard } from '@/components/atoms/MainCard';
import { TableSkeleton } from '@/components/molecules/LoadingSkeleton';
import { DataTable, type Column, type SortState } from './DataTable';

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
  /** Callback when page changes (required unless hidePagination is true) */
  readonly onPageChange?: (page: number) => void;
  /** Callback when page size changes (required unless hidePagination is true) */
  readonly onPageSizeChange?: (pageSize: number) => void;
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
  /** Hide pagination footer */
  readonly hidePagination?: boolean;
  /** Current sort state, if any column is sorted */
  readonly sort?: SortState | null;
  /** Called with the column key when a sortable header is clicked. Omit to keep sorting inert. */
  readonly onSortChange?: (key: string) => void;
  /** Search field shown at the head of the toolbar's left box. Omit `onChange` to render it inert. */
  readonly search?: {
    readonly value: string;
    readonly placeholder?: string;
    readonly onChange?: (value: string) => void;
  };
  /**
   * Filter slide-out panel. Renders a filter button at the head of the toolbar's right box.
   * The button is enabled whenever this prop is set; only the drawer's clear button is gated
   * on `onClear`.
   */
  readonly filterPanel?: {
    readonly content: ReactNode;
    readonly activeCount?: number;
    readonly onClear?: () => void;
  };
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
      <Typography variant="body2" sx={{
        color: "text.secondary"
      }}>
        {t('pagination.showing')} <strong>{startItem}</strong>{' '}
        {t('pagination.to')} <strong>{endItem}</strong>{' '}
        {t('pagination.of')} <strong>{totalItems}</strong>{' '}
        {t('pagination.results')}
      </Typography>

      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Typography variant="body2" sx={{
            color: "text.secondary"
          }}>
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
  hidePagination = false,
  sort,
  onSortChange,
  search,
  filterPanel,
}: DataTableCardProps<T, TTabValue>) {
  const { t } = useTranslation();

  // Filter drawer open state - UI state, not server state
  const [isFilterDrawerOpen, setIsFilterDrawerOpen] = useState(false);

  const handleSearchChange = useCallback(
    (event: ChangeEvent<HTMLInputElement>) => {
      search?.onChange?.(event.target.value);
    },
    [search]
  );

  const handleOpenFilterDrawer = useCallback(() => {
    setIsFilterDrawerOpen(true);
  }, []);

  const handleCloseFilterDrawer = useCallback(() => {
    setIsFilterDrawerOpen(false);
  }, []);

  const handleClearFilters = useCallback(() => {
    filterPanel?.onClear?.();
  }, [filterPanel]);

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

  const showToolbar =
    !hideToolbarWhenEmpty || resolvedFilterSlot || resolvedActionSlot || search || filterPanel;
  const totalPages = Math.ceil(totalItems / pageSize);
  const activeFilterCount = filterPanel?.activeCount ?? 0;

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
              {search && (
                <Input
                  value={search.value}
                  onChange={handleSearchChange}
                  placeholder={search.placeholder ?? t('dataTable.searchPlaceholder')}
                  disabled={!search.onChange}
                  size="small"
                  sx={{ width: 280 }}
                  slotProps={{
                    input: {
                      startAdornment: <SearchIcon fontSize="small" />,
                    },
                  }}
                />
              )}
              {resolvedFilterSlot}
            </Box>

            {/* Action slot - right side */}
            {(resolvedActionSlot || filterPanel) && (
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                {filterPanel && (
                  <Badge
                    color="primary"
                    badgeContent={activeFilterCount > 0 ? activeFilterCount : undefined}
                  >
                    <ActionButton icon={<FilterListIcon />} onClick={handleOpenFilterDrawer}>
                      {t('dataTable.filters')}
                    </ActionButton>
                  </Badge>
                )}
                {resolvedActionSlot}
              </Box>
            )}
          </Box>
          <Divider />
        </>
      )}

      {filterPanel && (
        <Drawer
          anchor="right"
          open={isFilterDrawerOpen}
          onClose={handleCloseFilterDrawer}
          slotProps={{ paper: { sx: { width: { xs: '100%', sm: 360 } } } }}
        >
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              gap: 2,
              p: 2,
            }}
          >
            <Typography variant="h6">{t('dataTable.filtersTitle')}</Typography>
            <IconButton
              onClick={handleCloseFilterDrawer}
              aria-label={t('dataTable.closeFilters')}
              size="small"
            >
              <CloseIcon fontSize="small" />
            </IconButton>
          </Box>
          <Divider />
          <Box sx={{ flex: '1 1 auto', p: 2 }}>{filterPanel.content}</Box>
          <Divider />
          <Box sx={{ p: 2 }}>
            <ActionButton
              variant="outlined"
              onClick={handleClearFilters}
              disabled={!filterPanel.onClear}
              sx={{ width: '100%', justifyContent: 'center' }}
            >
              {t('dataTable.clearFilters')}
            </ActionButton>
          </Box>
        </Drawer>
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
          sort={sort}
          onSortChange={onSortChange}
        />
      )}

      {/* Pagination Footer */}
      {!isLoading && !hidePagination && totalItems > 0 && onPageChange && onPageSizeChange && (
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
