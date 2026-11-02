import { type FC, useState, useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { useSearchParams } from 'react-router-dom';
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
import { PodAdministratorFilters } from './components/PodAdministratorFilters';
import { useDebouncedCallback } from '@/shared/hooks/useDebouncedCallback';
import { usePodSetup } from '@/shared/hooks/usePodSetup';
import { ADMIN_ROLES, ADMIN_ROLE_LABELS, type AdminRole } from '@/shared/types/admin';
import { formatDate } from '@/shared/utils/formatters';
import {
  POD_ADMINISTRATOR_SORT_COLUMNS,
  type PodAdministrator,
  type PodAdministratorQuery,
  type PodAdministratorSort,
  type PodAdministratorSortColumn,
  type CreatePodAdministratorRequest,
} from './types';

const SEARCH_DEBOUNCE_MS = 300;

function isAdminRoleValue(value: string): value is AdminRole {
  return (ADMIN_ROLES as readonly string[]).includes(value);
}

function isSortColumn(value: string): value is PodAdministratorSortColumn {
  return (POD_ADMINISTRATOR_SORT_COLUMNS as readonly string[]).includes(value);
}

/** Parses `column:direction`; anything unknown means no sort. */
function parseSort(value: string | null): PodAdministratorSort | null {
  if (!value) return null;
  const [column, direction] = value.split(':');
  if (!column || !isSortColumn(column)) return null;
  if (direction !== 'asc' && direction !== 'desc') return null;
  return { column, direction };
}

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
  const [searchParams, setSearchParams] = useSearchParams();
  const { status: podSetupStatus } = usePodSetup();
  const wards = podSetupStatus?.wards ?? [];

  // The URL is the single source of truth for the query; only the raw search text is local.
  const urlSearch = searchParams.get('q') ?? '';
  const urlWardId = searchParams.get('ward');
  const urlRoleKey = searchParams.getAll('role').join(',');
  const urlSortParam = searchParams.get('sort');
  const [searchInput, setSearchInput] = useState(urlSearch);

  const roles = useMemo(() => urlRoleKey.split(',').filter(isAdminRoleValue), [urlRoleKey]);
  const sort = useMemo(() => parseSort(urlSortParam), [urlSortParam]);

  const query = useMemo<PodAdministratorQuery>(
    () => ({
      ...(urlSearch ? { q: urlSearch } : {}),
      ...(roles.length > 0 ? { roles } : {}),
      ...(urlWardId ? { wardId: urlWardId } : {}),
      sort: sort ?? undefined,
    }),
    [urlSearch, roles, urlWardId, sort]
  );

  // Data fetching
  const { data, isLoading, error } = usePodAdministrators(query);

  const writeSearch = useDebouncedCallback((value: string) => {
    setSearchParams(
      (prev) => {
        const next = new URLSearchParams(prev);
        if (value) {
          next.set('q', value);
        } else {
          next.delete('q');
        }
        return next;
      },
      { replace: true }
    );
  }, SEARCH_DEBOUNCE_MS);

  const handleSearchChange = useCallback(
    (value: string) => {
      setSearchInput(value);
      writeSearch(value);
    },
    [writeSearch]
  );

  const handleSortChange = useCallback(
    (column: string) => {
      if (!isSortColumn(column)) return;
      const direction = sort?.column === column && sort.direction === 'asc' ? 'desc' : 'asc';
      setSearchParams((prev) => {
        const next = new URLSearchParams(prev);
        next.set('sort', `${column}:${direction}`);
        return next;
      });
    },
    [sort, setSearchParams]
  );

  const handleRolesChange = useCallback(
    (nextRoles: readonly AdminRole[]) => {
      setSearchParams((prev) => {
        const next = new URLSearchParams(prev);
        next.delete('role');
        nextRoles.forEach((role) => next.append('role', role));
        return next;
      });
    },
    [setSearchParams]
  );

  const handleWardChange = useCallback(
    (wardId: string | null) => {
      setSearchParams((prev) => {
        const next = new URLSearchParams(prev);
        if (wardId) {
          next.set('ward', wardId);
        } else {
          next.delete('ward');
        }
        return next;
      });
    },
    [setSearchParams]
  );

  const handleClearFilters = useCallback(() => {
    setSearchParams((prev) => {
      const next = new URLSearchParams(prev);
      next.delete('role');
      next.delete('ward');
      return next;
    });
  }, [setSearchParams]);

  const hasQuery = urlSearch !== '' || roles.length > 0 || urlWardId !== null;

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
    createAdmin.reset();
    setCreateDialogOpen(true);
  }, [createAdmin]);

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
          sort={sort ? { key: sort.column, direction: sort.direction } : null}
          onSortChange={handleSortChange}
          search={{ value: searchInput, onChange: handleSearchChange }}
          filterPanel={{
            content: (
              <PodAdministratorFilters
                roles={roles}
                wardId={urlWardId}
                wards={wards}
                onRolesChange={handleRolesChange}
                onWardChange={handleWardChange}
              />
            ),
            activeCount: roles.length + (urlWardId ? 1 : 0),
            onClear: handleClearFilters,
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
                {hasQuery ? t('podAdministrators.emptyFiltered') : t('podAdministrators.empty')}
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
        error={createAdmin.error}
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
