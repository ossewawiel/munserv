import { type FC, useState, useCallback, useMemo } from 'react';
import { useSearchParams } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Chip from '@mui/material/Chip';
import IconButton from '@mui/material/IconButton';
import LinearProgress from '@mui/material/LinearProgress';
import Menu from '@mui/material/Menu';
import MenuItem from '@mui/material/MenuItem';
import Tooltip from '@mui/material/Tooltip';
import Typography from '@mui/material/Typography';
import MoreVertIcon from '@mui/icons-material/MoreVert';
import PauseCircleIcon from '@mui/icons-material/PauseCircle';
import PersonRemoveIcon from '@mui/icons-material/PersonRemove';
import PlayCircleIcon from '@mui/icons-material/PlayCircle';

import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { Breadcrumbs } from '@/components/molecules/Breadcrumbs';
import { DataTableCard, type DataTableTab } from '@/components/organisms/DataTableCard';
import { RevokeDialog } from './components/RevokeDialog';
import {
  useGroundAdmins,
  useRevokeGroundAdmin,
  useUpdateGroundAdminStatus,
} from './hooks';
import type { GroundAdmin, GroundAdminStatus } from '@/shared/types/groundAdmin';
import { formatDate } from '@/shared/utils/formatters';

type StatusFilter = 'all' | GroundAdminStatus;

/**
 * Page for managing Ground Admins in the sector
 */
export const GroundAdminsPage: FC = () => {
  const { t } = useTranslation();
  const [searchParams, setSearchParams] = useSearchParams();

  // Filter state from URL
  const statusFilter = (searchParams.get('status') as StatusFilter) || 'all';

  // Local state
  const [selectedGroundAdmin, setSelectedGroundAdmin] = useState<GroundAdmin | null>(
    null
  );
  const [revokeDialogOpen, setRevokeDialogOpen] = useState(false);
  const [menuAnchor, setMenuAnchor] = useState<{
    el: HTMLElement;
    admin: GroundAdmin;
  } | null>(null);

  // Query with filter
  const { data, isLoading, error } = useGroundAdmins(
    statusFilter === 'all' ? undefined : statusFilter
  );

  // Mutations
  const revokeGroundAdmin = useRevokeGroundAdmin();
  const updateStatus = useUpdateGroundAdminStatus();

  const groundAdmins = useMemo(() => data?.items ?? [], [data]);

  // Tabs for status filter
  const tabs = useMemo<DataTableTab<StatusFilter>[]>(
    () => [
      { value: 'all', label: t('common.all', 'All') },
      { value: 'active', label: t('groundAdmin.status.active', 'Active') },
      { value: 'on_hold', label: t('groundAdmin.status.onHold', 'On Hold') },
      { value: 'inactive', label: t('groundAdmin.status.inactive', 'Inactive') },
    ],
    [t]
  );

  const handleTabChange = useCallback(
    (newValue: StatusFilter) => {
      setSearchParams((prev) => {
        if (newValue === 'all') {
          prev.delete('status');
        } else {
          prev.set('status', newValue);
        }
        return prev;
      });
    },
    [setSearchParams]
  );

  const handleMenuOpen = useCallback(
    (event: React.MouseEvent<HTMLElement>, admin: GroundAdmin) => {
      setMenuAnchor({ el: event.currentTarget, admin });
    },
    []
  );

  const handleMenuClose = useCallback(() => {
    setMenuAnchor(null);
  }, []);

  const handleRevokeClick = useCallback(() => {
    if (menuAnchor) {
      setSelectedGroundAdmin(menuAnchor.admin);
      setRevokeDialogOpen(true);
    }
    handleMenuClose();
  }, [menuAnchor, handleMenuClose]);

  const handlePutOnHold = useCallback(() => {
    if (menuAnchor) {
      updateStatus.mutate({ memberId: menuAnchor.admin.memberId, status: 'on_hold' });
    }
    handleMenuClose();
  }, [menuAnchor, updateStatus, handleMenuClose]);

  const handleReactivate = useCallback(() => {
    if (menuAnchor) {
      updateStatus.mutate({ memberId: menuAnchor.admin.memberId, status: 'active' });
    }
    handleMenuClose();
  }, [menuAnchor, updateStatus, handleMenuClose]);

  const handleRevoke = useCallback(
    (reason: string) => {
      if (selectedGroundAdmin) {
        revokeGroundAdmin.mutate(
          { memberId: selectedGroundAdmin.memberId, reason },
          {
            onSuccess: () => {
              setRevokeDialogOpen(false);
              setSelectedGroundAdmin(null);
            },
          }
        );
      }
    },
    [selectedGroundAdmin, revokeGroundAdmin]
  );

  const handleDialogPutOnHold = useCallback(() => {
    if (selectedGroundAdmin) {
      updateStatus.mutate(
        { memberId: selectedGroundAdmin.memberId, status: 'on_hold' },
        {
          onSuccess: () => {
            setRevokeDialogOpen(false);
            setSelectedGroundAdmin(null);
          },
        }
      );
    }
  }, [selectedGroundAdmin, updateStatus]);

  const columns = useMemo(
    () => [
      {
        key: 'name',
        header: t('groundAdmin.columns.name', 'Name'),
        render: (admin: GroundAdmin) => (
          <Typography variant="body2" sx={{
            fontWeight: 500
          }}>
            {admin.name}
          </Typography>
        ),
      },
      {
        key: 'status',
        header: t('groundAdmin.columns.status', 'Status'),
        render: (admin: GroundAdmin) => (
          <Chip
            label={t(`groundAdmin.status.${admin.status}`, admin.status)}
            size="small"
            color={
              admin.status === 'active'
                ? 'success'
                : admin.status === 'on_hold'
                  ? 'warning'
                  : 'default'
            }
          />
        ),
      },
      {
        key: 'responseRate',
        header: t('groundAdmin.columns.responseRate', 'Response Rate'),
        render: (admin: GroundAdmin) => (
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, minWidth: 100 }}>
            <LinearProgress
              variant="determinate"
              value={admin.responseRate}
              color={
                admin.responseRate >= 80
                  ? 'success'
                  : admin.responseRate >= 50
                    ? 'warning'
                    : 'error'
              }
              sx={{ flex: 1, height: 6, borderRadius: 1 }}
            />
            <Typography variant="caption" sx={{ minWidth: 35 }}>
              {admin.responseRate}%
            </Typography>
          </Box>
        ),
      },
      {
        key: 'pendingVerifications',
        header: t('groundAdmin.columns.pending', 'Pending'),
        render: (admin: GroundAdmin) => (
          <Typography variant="body2">
            {admin.pendingVerifications}
          </Typography>
        ),
      },
      {
        key: 'since',
        header: t('groundAdmin.columns.since', 'Since'),
        render: (admin: GroundAdmin) => (
          <Typography variant="body2" sx={{
            color: "text.secondary"
          }}>
            {formatDate(admin.since)}
          </Typography>
        ),
      },
      {
        key: 'actions',
        header: t('common.actions', 'Actions'),
        width: 80,
        render: (admin: GroundAdmin) => (
          <Tooltip title={t('common.actions', 'Actions')}>
            <IconButton
              size="small"
              onClick={(e) => handleMenuOpen(e, admin)}
              disabled={admin.status === 'inactive'}
            >
              <MoreVertIcon />
            </IconButton>
          </Tooltip>
        ),
      },
    ],
    [t, handleMenuOpen]
  );

  if (error) {
    return (
      <DashboardLayout>
        <Breadcrumbs
          title={t('groundAdmin.title', 'Ground Admins')}
          items={[
            { label: t('dashboard.title', 'Dashboard'), path: '/', icon: 'home' },
            { label: t('groundAdmin.title', 'Ground Admins') },
          ]}
        />
        <Box sx={{ p: 3, textAlign: 'center', mt: 3 }}>
          <Typography color="error">
            {t('errors.loadFailed', 'Failed to load data')}
          </Typography>
          <Button onClick={() => window.location.reload()} sx={{ mt: 2 }}>
            {t('common.buttons.retry', 'Retry')}
          </Button>
        </Box>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <Breadcrumbs
        title={t('groundAdmin.title', 'Ground Admins')}
        subtitle={t('groundAdmin.subtitle', 'Manage Ground Admins in your sector')}
        items={[
          { label: t('dashboard.title', 'Dashboard'), path: '/', icon: 'home' },
          { label: t('groundAdmin.title', 'Ground Admins') },
        ]}
      />

      <Box sx={{ mt: 3 }}>
        <DataTableCard
          columns={columns}
          data={groundAdmins}
        keyExtractor={(admin) => admin.id}
        totalItems={data?.total ?? 0}
        currentPage={1}
        pageSize={100}
        isLoading={isLoading}
        hidePagination
        tabs={{
          tabs,
          value: statusFilter,
          onChange: handleTabChange,
          ariaLabel: t('groundAdmin.filterByStatus', 'Filter by status'),
        }}
        emptyMessage={
          <Box sx={{ py: 4, textAlign: 'center' }}>
            <Typography sx={{
              color: "text.secondary"
            }}>
              {statusFilter === 'all'
                ? t('groundAdmin.empty', 'No Ground Admins in this sector yet')
                : t('groundAdmin.emptyFiltered', 'No Ground Admins with this status')}
            </Typography>
          </Box>
        }
        />
      </Box>

      {/* Actions Menu */}
      <Menu
        anchorEl={menuAnchor?.el}
        open={Boolean(menuAnchor)}
        onClose={handleMenuClose}
      >
        {menuAnchor?.admin.status === 'active' && (
          <MenuItem onClick={handlePutOnHold}>
            <PauseCircleIcon sx={{ mr: 1 }} fontSize="small" />
            {t('groundAdmin.putOnHold', 'Put on Hold')}
          </MenuItem>
        )}
        {menuAnchor?.admin.status === 'on_hold' && (
          <MenuItem onClick={handleReactivate}>
            <PlayCircleIcon sx={{ mr: 1 }} fontSize="small" />
            {t('groundAdmin.reactivate', 'Reactivate')}
          </MenuItem>
        )}
        <MenuItem onClick={handleRevokeClick} sx={{ color: 'error.main' }}>
          <PersonRemoveIcon sx={{ mr: 1 }} fontSize="small" />
          {t('groundAdmin.revoke', 'Revoke Status')}
        </MenuItem>
      </Menu>

      {/* Revoke Dialog */}
      <RevokeDialog
        open={revokeDialogOpen}
        groundAdmin={selectedGroundAdmin}
        onClose={() => {
          setRevokeDialogOpen(false);
          setSelectedGroundAdmin(null);
        }}
        onRevoke={handleRevoke}
        onPutOnHold={handleDialogPutOnHold}
        isLoading={revokeGroundAdmin.isPending || updateStatus.isPending}
      />
    </DashboardLayout>
  );
};
