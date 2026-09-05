import { type FC, useCallback, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import BlockIcon from '@mui/icons-material/Block';

import { DataTableCard } from '@/components/organisms/DataTableCard';
import type { Column } from '@/components/organisms/DataTable';
import { ActionIconButton } from '@/components/atoms/ActionIconButton';
import { Badge } from '@/components/atoms/Badge';
import { EmptyState } from '@/components/molecules/EmptyState';
import { ADMIN_ROLE_LABELS } from '@/shared/types/admin';
import { formatDateTime } from '@/shared/utils/formatters';
import type { SupportGrant, SupportGrantStatus } from '../types';

const PAGE_SIZE_OPTIONS = [5, 10, 20] as const;

type SupportGrantsTableVariant = 'active' | 'history';

interface SupportGrantsTableProps {
  /** Whether this table shows the active grant or the history of past grants */
  variant: SupportGrantsTableVariant;
  /** Grants to display, already filtered by status */
  grants: readonly SupportGrant[];
  /** Called with the grant when the pod chief presses the revoke action (active variant only) */
  onRevoke?: (grant: SupportGrant) => void;
  /** Loading state for the underlying data */
  isLoading?: boolean;
}

const STATUS_BADGE_VARIANTS: Record<SupportGrantStatus, 'success' | 'default' | 'warning'> = {
  active: 'success',
  expired: 'default',
  revoked: 'warning',
};

/**
 * Table of support grants in Pod Settings > Support Access. Driven by `variant`:
 * `active` shows the currently active grant with a revoke action, `history` shows
 * past grants (expired or revoked) with no actions.
 */
export const SupportGrantsTable: FC<SupportGrantsTableProps> = ({
  variant,
  grants,
  onRevoke,
  isLoading = false,
}) => {
  const { t } = useTranslation();
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState<number>(PAGE_SIZE_OPTIONS[1]);

  const handlePageChange = useCallback((newPage: number) => setPage(newPage), []);
  const handlePageSizeChange = useCallback((newSize: number) => {
    setPageSize(newSize);
    setPage(1);
  }, []);

  const pagedGrants = useMemo(() => {
    const start = (page - 1) * pageSize;
    return grants.slice(start, start + pageSize);
  }, [grants, page, pageSize]);

  const columns = useMemo<Column<SupportGrant>[]>(() => {
    const shared: Column<SupportGrant>[] = [
      {
        key: 'role',
        header: t('supportAccess.table.role', 'Role'),
        render: (grant) => t(`roles.${grant.grantedRole}`, ADMIN_ROLE_LABELS[grant.grantedRole]),
      },
      {
        key: 'purpose',
        header: t('supportAccess.table.purpose', 'Purpose'),
        render: (grant) => grant.purpose,
      },
      {
        key: 'grantedBy',
        header: t('supportAccess.table.grantedBy', 'Granted by'),
        render: (grant) => grant.grantedByName,
      },
      {
        key: 'grantedAt',
        header: t('supportAccess.table.grantedAt', 'Granted'),
        render: (grant) => formatDateTime(grant.grantedAt),
      },
    ];

    if (variant === 'active') {
      return [
        ...shared,
        {
          key: 'lastActivity',
          header: t('supportAccess.table.lastActivity', 'Last activity'),
          render: (grant) =>
            grant.lastActivity
              ? formatDateTime(grant.lastActivity)
              : t('supportAccess.table.never', 'Never'),
        },
        {
          key: 'expiresAt',
          header: t('supportAccess.table.expiresAt', 'Expires'),
          render: (grant) => formatDateTime(grant.expiresAt),
        },
        {
          key: 'actions',
          header: t('supportAccess.table.actions', 'Actions'),
          align: 'right',
          render: (grant) => (
            <ActionIconButton
              color="secondary"
              tooltip={t('supportAccess.revoke', 'Revoke')}
              aria-label={t('supportAccess.revoke', 'Revoke')}
              onClick={() => onRevoke?.(grant)}
            >
              <BlockIcon fontSize="small" />
            </ActionIconButton>
          ),
        },
      ];
    }

    return [
      ...shared,
      {
        key: 'status',
        header: t('supportAccess.table.status', 'Status'),
        render: (grant) => (
          <Badge variant={STATUS_BADGE_VARIANTS[grant.status]}>
            {t(`supportAccess.status.${grant.status}`, grant.status)}
          </Badge>
        ),
      },
      {
        key: 'endedAt',
        header: t('supportAccess.table.endedAt', 'Ended'),
        render: (grant) => {
          const endedAt = grant.revokedAt ?? grant.expiredAt;
          return endedAt ? formatDateTime(endedAt) : '-';
        },
      },
    ];
  }, [variant, t, onRevoke]);

  const emptyMessage = (
    <EmptyState
      title={
        variant === 'active'
          ? t('supportAccess.table.emptyActive', 'No active support grant')
          : t('supportAccess.table.emptyHistory', 'No past support grants')
      }
    />
  );

  return (
    <DataTableCard
      columns={columns}
      data={pagedGrants}
      keyExtractor={(grant) => grant.id}
      totalItems={grants.length}
      currentPage={page}
      pageSize={pageSize}
      pageSizeOptions={PAGE_SIZE_OPTIONS}
      onPageChange={handlePageChange}
      onPageSizeChange={handlePageSizeChange}
      isLoading={isLoading}
      emptyMessage={emptyMessage}
    />
  );
};
