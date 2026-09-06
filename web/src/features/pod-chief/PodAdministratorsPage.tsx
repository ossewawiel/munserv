import { type FC, useState, useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Chip from '@mui/material/Chip';
import IconButton from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';
import Typography from '@mui/material/Typography';
import AddIcon from '@mui/icons-material/Add';
import DeleteIcon from '@mui/icons-material/Delete';
import EditIcon from '@mui/icons-material/Edit';

import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { Breadcrumbs } from '@/components/molecules/Breadcrumbs';
import { DataTableCard } from '@/components/organisms/DataTableCard';
import { CreatePodAdminDialog } from './components/CreatePodAdminDialog';
import { EditPodAdminDialog } from './components/EditPodAdminDialog';
import { DeletePodAdminDialog } from './components/DeletePodAdminDialog';
import {
  usePodAdministrators,
  useCreatePodAdministrator,
  useUpdatePodAdministrator,
  useDeletePodAdministrator,
} from './hooks';
import { ADMIN_ROLE_LABELS } from '@/shared/types/admin';
import { formatDate } from '@/shared/utils/formatters';
import type { PodAdministrator, CreatePodAdministratorRequest } from './types';

/**
 * Gets a human-readable description of an administrator's assignment.
 * For pod-level admins, shows "Pod". For ward-level, shows ward count.
 * For sector-level, shows sector info.
 */
function getAssignmentLabel(admin: PodAdministrator, t: (key: string) => string): string {
  if (admin.level === 'pod') {
    return t('podAdministrators.table.podLevel');
  }
  if (admin.wardId) {
    return t('podAdministrators.table.wardAssigned');
  }
  if (admin.sectorId) {
    return t('podAdministrators.table.sectorAssigned');
  }
  return t('common.notAvailable');
}

/**
 * Pod Administrators page for Pod Chiefs to manage all administrators within their pod.
 * Shows a table list with name, contact, role, assignment, and actions.
 *
 * Acceptance criteria (W14):
 * - Shows name, contact, ward/sector assignment
 * - Actions column present
 * - Add button available
 * - Table prepared for search/sort/filter (disabled for MVP)
 */
export const PodAdministratorsPage: FC = () => {
  const { t } = useTranslation();

  // Data fetching
  const { data, isLoading, error } = usePodAdministrators();

  // Mutations
  const createAdmin = useCreatePodAdministrator();
  const updateAdmin = useUpdatePodAdministrator();
  const deleteAdmin = useDeletePodAdministrator();

  // Dialog state
  const [createDialogOpen, setCreateDialogOpen] = useState(false);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedAdmin, setSelectedAdmin] = useState<PodAdministrator | null>(null);
  const [temporaryPassword, setTemporaryPassword] = useState<string | undefined>();

  const admins = useMemo(() => data?.items ?? [], [data]);

  // Handlers
  const handleCreateClick = useCallback(() => {
    setTemporaryPassword(undefined);
    setCreateDialogOpen(true);
  }, []);

  const handleCreateSubmit = useCallback(
    (formData: CreatePodAdministratorRequest) => {
      createAdmin.mutate(formData, {
        onSuccess: (result) => {
          setTemporaryPassword(result.temporaryPassword);
        },
      });
    },
    [createAdmin]
  );

  const handleCreateClose = useCallback(() => {
    setCreateDialogOpen(false);
    setTemporaryPassword(undefined);
    createAdmin.reset();
  }, [createAdmin]);

  const handleEditClick = useCallback((admin: PodAdministrator) => {
    setSelectedAdmin(admin);
    setEditDialogOpen(true);
  }, []);

  const handleEditSubmit = useCallback(
    (displayName: string) => {
      if (selectedAdmin) {
        updateAdmin.mutate(
          { id: selectedAdmin.id, request: { displayName } },
          {
            onSuccess: () => {
              setEditDialogOpen(false);
              setSelectedAdmin(null);
            },
          }
        );
      }
    },
    [selectedAdmin, updateAdmin]
  );

  const handleEditClose = useCallback(() => {
    setEditDialogOpen(false);
    setSelectedAdmin(null);
  }, []);

  const handleDeleteClick = useCallback((admin: PodAdministrator) => {
    setSelectedAdmin(admin);
    setDeleteDialogOpen(true);
  }, []);

  const handleDeleteConfirm = useCallback(() => {
    if (selectedAdmin) {
      deleteAdmin.mutate(selectedAdmin.id, {
        onSuccess: () => {
          setDeleteDialogOpen(false);
          setSelectedAdmin(null);
        },
      });
    }
  }, [selectedAdmin, deleteAdmin]);

  const handleDeleteClose = useCallback(() => {
    setDeleteDialogOpen(false);
    setSelectedAdmin(null);
  }, []);

  // Table columns
  const columns = useMemo(
    () => [
      {
        key: 'displayName',
        header: t('podAdministrators.table.name'),
        sortable: true,
        render: (admin: PodAdministrator) => (
          <Typography variant="body2" sx={{
            fontWeight: 500
          }}>
            {admin.displayName}
          </Typography>
        ),
      },
      {
        key: 'email',
        header: t('podAdministrators.table.email'),
        sortable: true,
        render: (admin: PodAdministrator) => (
          <Typography variant="body2" sx={{
            color: "text.secondary"
          }}>
            {admin.email}
          </Typography>
        ),
      },
      {
        key: 'role',
        header: t('podAdministrators.table.role'),
        sortable: true,
        render: (admin: PodAdministrator) => (
          <Chip
            label={ADMIN_ROLE_LABELS[admin.role] ?? admin.role}
            size="small"
            color="default"
          />
        ),
      },
      {
        key: 'assignedTo',
        header: t('podAdministrators.table.assignedTo'),
        sortable: true,
        render: (admin: PodAdministrator) => (
          <Typography variant="body2" sx={{
            color: "text.secondary"
          }}>
            {getAssignmentLabel(admin, t)}
          </Typography>
        ),
      },
      {
        key: 'createdAt',
        header: t('podAdministrators.table.createdAt'),
        sortable: true,
        render: (admin: PodAdministrator) => (
          <Typography variant="body2" sx={{
            color: "text.secondary"
          }}>
            {formatDate(admin.createdAt)}
          </Typography>
        ),
      },
      {
        key: 'actions',
        header: t('podAdministrators.table.actions'),
        width: 100,
        render: (admin: PodAdministrator) => (
          <Box sx={{ display: 'flex', gap: 0.5 }}>
            <Tooltip title={t('common.edit')}>
              <IconButton size="small" onClick={() => handleEditClick(admin)}>
                <EditIcon fontSize="small" />
              </IconButton>
            </Tooltip>
            <Tooltip title={t('common.delete')}>
              <IconButton
                size="small"
                onClick={() => handleDeleteClick(admin)}
                color="error"
              >
                <DeleteIcon fontSize="small" />
              </IconButton>
            </Tooltip>
          </Box>
        ),
      },
    ],
    [t, handleEditClick, handleDeleteClick]
  );

  if (error) {
    return (
      <DashboardLayout>
        <Breadcrumbs
          title={t('podAdministrators.title')}
          items={[
            { label: t('dashboard.title'), path: '/', icon: 'home' },
            { label: t('podAdministrators.title') },
          ]}
        />
        <Box sx={{ p: 3, textAlign: 'center', mt: 3 }}>
          <Typography color="error">{t('errors.loadFailed')}</Typography>
          <Button onClick={() => window.location.reload()} sx={{ mt: 2 }}>
            {t('common.retry')}
          </Button>
        </Box>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <Breadcrumbs
        title={t('podAdministrators.title')}
        subtitle={t('podAdministrators.subtitle')}
        items={[
          { label: t('dashboard.title'), path: '/', icon: 'home' },
          { label: t('podAdministrators.title') },
        ]}
      />

      <Box sx={{ mt: 3 }}>
        <DataTableCard
          columns={columns}
          data={admins}
          keyExtractor={(admin) => admin.id}
          totalItems={data?.total ?? 0}
          currentPage={1}
          pageSize={100}
          isLoading={isLoading}
          hidePagination
          search={{ value: '' }}
          filterPanel={{
            content: <Typography>{t('podAdministrators.filters.comingSoon')}</Typography>,
          }}
          actionSlot={
            <Button
              variant="contained"
              startIcon={<AddIcon />}
              onClick={handleCreateClick}
              size="small"
            >
              {t('podAdministrators.addNew')}
            </Button>
          }
          emptyMessage={
            <Box sx={{ py: 4, textAlign: 'center' }}>
              <Typography sx={{
                color: "text.secondary"
              }}>
                {t('podAdministrators.empty')}
              </Typography>
            </Box>
          }
        />
      </Box>

      {/* Create Admin Dialog */}
      <CreatePodAdminDialog
        open={createDialogOpen}
        onClose={handleCreateClose}
        onSubmit={handleCreateSubmit}
        isLoading={createAdmin.isPending}
        temporaryPassword={temporaryPassword}
      />

      {/* Edit Admin Dialog */}
      <EditPodAdminDialog
        open={editDialogOpen}
        admin={selectedAdmin}
        onClose={handleEditClose}
        onSubmit={handleEditSubmit}
        isLoading={updateAdmin.isPending}
      />

      {/* Delete Admin Dialog */}
      <DeletePodAdminDialog
        open={deleteDialogOpen}
        admin={selectedAdmin}
        onClose={handleDeleteClose}
        onConfirm={handleDeleteConfirm}
        isLoading={deleteAdmin.isPending}
      />
    </DashboardLayout>
  );
};
