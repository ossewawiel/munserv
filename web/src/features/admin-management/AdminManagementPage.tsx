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
import { CreateAdminDialog } from './components/CreateAdminDialog';
import { EditAdminDialog } from './components/EditAdminDialog';
import { DeleteAdminDialog } from './components/DeleteAdminDialog';
import { useAdmins, useCreateAdmin, useUpdateAdmin, useDeleteAdmin } from './hooks';
import { ADMIN_ROLE_LABELS } from '@/shared/types/admin';
import { formatDate } from '@/shared/utils/formatters';
import type { Admin } from './types';

/**
 * Admin Management page for sector chiefs to manage sector admins.
 */
export const AdminManagementPage: FC = () => {
  const { t } = useTranslation();

  // Data fetching
  const { data, isLoading, error } = useAdmins();

  // Mutations
  const createAdmin = useCreateAdmin();
  const updateAdmin = useUpdateAdmin();
  const deleteAdmin = useDeleteAdmin();

  // Dialog state
  const [createDialogOpen, setCreateDialogOpen] = useState(false);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedAdmin, setSelectedAdmin] = useState<Admin | null>(null);
  const [temporaryPassword, setTemporaryPassword] = useState<string | undefined>();

  const admins = useMemo(() => data?.items ?? [], [data]);

  // Handlers
  const handleCreateClick = useCallback(() => {
    setTemporaryPassword(undefined);
    setCreateDialogOpen(true);
  }, []);

  const handleCreateSubmit = useCallback(
    (formData: { email: string; displayName: string }) => {
      createAdmin.mutate(
        { ...formData, role: 'sector_admin' },
        {
          onSuccess: (result) => {
            setTemporaryPassword(result.temporaryPassword);
          },
        }
      );
    },
    [createAdmin]
  );

  const handleCreateClose = useCallback(() => {
    setCreateDialogOpen(false);
    setTemporaryPassword(undefined);
    createAdmin.reset();
  }, [createAdmin]);

  const handleEditClick = useCallback((admin: Admin) => {
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

  const handleDeleteClick = useCallback((admin: Admin) => {
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
        header: t('adminManagement.table.name', 'Name'),
        render: (admin: Admin) => (
          <Typography variant="body2" fontWeight={500}>
            {admin.displayName}
          </Typography>
        ),
      },
      {
        key: 'email',
        header: t('adminManagement.table.email', 'Email'),
        render: (admin: Admin) => (
          <Typography variant="body2" color="text.secondary">
            {admin.email}
          </Typography>
        ),
      },
      {
        key: 'role',
        header: t('adminManagement.table.role', 'Role'),
        render: (admin: Admin) => (
          <Chip
            label={ADMIN_ROLE_LABELS[admin.role] ?? admin.role}
            size="small"
            color="default"
          />
        ),
      },
      {
        key: 'createdAt',
        header: t('adminManagement.table.createdAt', 'Created'),
        render: (admin: Admin) => (
          <Typography variant="body2" color="text.secondary">
            {formatDate(admin.createdAt)}
          </Typography>
        ),
      },
      {
        key: 'actions',
        header: t('adminManagement.table.actions', 'Actions'),
        width: 100,
        render: (admin: Admin) => (
          <Box sx={{ display: 'flex', gap: 0.5 }}>
            <Tooltip title={t('common.edit', 'Edit')}>
              <IconButton size="small" onClick={() => handleEditClick(admin)}>
                <EditIcon fontSize="small" />
              </IconButton>
            </Tooltip>
            <Tooltip title={t('common.delete', 'Delete')}>
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
          title={t('adminManagement.title', 'Admin Management')}
          items={[
            { label: t('dashboard.title', 'Dashboard'), path: '/', icon: 'home' },
            { label: t('adminManagement.title', 'Admin Management') },
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
        title={t('adminManagement.title', 'Admin Management')}
        subtitle={t(
          'adminManagement.subtitle',
          'Create and manage sector administrators'
        )}
        items={[
          { label: t('dashboard.title', 'Dashboard'), path: '/', icon: 'home' },
          { label: t('adminManagement.title', 'Admin Management') },
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
          actionSlot={
            <Button
              variant="contained"
              startIcon={<AddIcon />}
              onClick={handleCreateClick}
              size="small"
            >
              {t('adminManagement.createAdmin', 'Create Admin')}
            </Button>
          }
          emptyMessage={
            <Box sx={{ py: 4, textAlign: 'center' }}>
              <Typography color="text.secondary">
                {t('adminManagement.empty', 'No admins found')}
              </Typography>
            </Box>
          }
        />
      </Box>

      {/* Create Admin Dialog */}
      <CreateAdminDialog
        open={createDialogOpen}
        onClose={handleCreateClose}
        onSubmit={handleCreateSubmit}
        isLoading={createAdmin.isPending}
        temporaryPassword={temporaryPassword}
      />

      {/* Edit Admin Dialog */}
      <EditAdminDialog
        open={editDialogOpen}
        admin={selectedAdmin}
        onClose={handleEditClose}
        onSubmit={handleEditSubmit}
        isLoading={updateAdmin.isPending}
      />

      {/* Delete Admin Dialog */}
      <DeleteAdminDialog
        open={deleteDialogOpen}
        admin={selectedAdmin}
        onClose={handleDeleteClose}
        onConfirm={handleDeleteConfirm}
        isLoading={deleteAdmin.isPending}
      />
    </DashboardLayout>
  );
};
