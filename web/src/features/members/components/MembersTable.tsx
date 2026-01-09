import { type FC, useMemo, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Avatar from '@mui/material/Avatar';
import Typography from '@mui/material/Typography';
import IconButton from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';
import AssignmentIcon from '@mui/icons-material/Assignment';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import CancelIcon from '@mui/icons-material/Cancel';

import { DataTable, type Column } from '@/components/organisms/DataTable';
import { MemberStatusBadge } from '@/components/molecules/MemberStatusBadge';
import type { MemberListItem } from '../types';

interface MembersTableProps {
  members: MemberListItem[];
  showApprovalActions?: boolean;
  onApprove?: (member: MemberListItem) => void;
  onReject?: (member: MemberListItem) => void;
  onRowClick?: (member: MemberListItem) => void;
}

export const MembersTable: FC<MembersTableProps> = ({
  members,
  showApprovalActions = false,
  onApprove,
  onReject,
  onRowClick,
}) => {
  const { t } = useTranslation();

  const formatDate = useCallback((dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString(undefined, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  }, []);

  const columns: Column<MemberListItem>[] = useMemo(
    () => [
      {
        key: 'name',
        header: t('members.name'),
        render: (member) => (
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
            <Avatar
              sx={{
                width: 40,
                height: 40,
                bgcolor:
                  member.status === 'pending_approval'
                    ? 'warning.main'
                    : 'primary.light',
                color:
                  member.status === 'pending_approval'
                    ? 'warning.contrastText'
                    : 'primary.contrastText',
                fontSize: '0.875rem',
                fontWeight: 600,
              }}
            >
              {member.firstName.charAt(0)}
              {member.surname.charAt(0)}
            </Avatar>
            <Box>
              <Typography variant="body2" fontWeight={500}>
                {member.firstName} {member.surname}
              </Typography>
              <Typography variant="caption" color="text.secondary">
                {member.email}
              </Typography>
            </Box>
          </Box>
        ),
      },
      {
        key: 'phone',
        header: t('members.phone'),
        width: '140px',
        render: (member) => (
          <Typography variant="body2" color="text.secondary">
            {member.phoneNumber}
          </Typography>
        ),
      },
      {
        key: 'address',
        header: t('members.address'),
        render: (member) => (
          <Typography
            variant="body2"
            color="text.secondary"
            sx={{
              maxWidth: 200,
              overflow: 'hidden',
              textOverflow: 'ellipsis',
              whiteSpace: 'nowrap',
            }}
            title={member.address}
          >
            {member.address}
          </Typography>
        ),
      },
      {
        key: 'status',
        header: t('members.status'),
        width: '140px',
        render: (member) => <MemberStatusBadge status={member.status} />,
      },
      {
        key: 'issuesReported',
        header: t('members.issuesReported'),
        width: '100px',
        align: 'center',
        render: (member) => (
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 0.5,
              color: 'text.secondary',
            }}
          >
            <AssignmentIcon sx={{ fontSize: 16 }} />
            <Typography variant="body2">{member.issueCount}</Typography>
          </Box>
        ),
      },
      {
        key: 'joinedAt',
        header: t('members.joinedAt'),
        width: '130px',
        render: (member) => (
          <Typography variant="body2" color="text.secondary">
            {formatDate(member.joinedAt)}
          </Typography>
        ),
      },
      ...(showApprovalActions
        ? [
            {
              key: 'actions',
              header: t('members.actions'),
              width: '120px',
              align: 'center' as const,
              render: (member: MemberListItem) =>
                member.status === 'pending_approval' ? (
                  <Box
                    sx={{ display: 'flex', gap: 0.5, justifyContent: 'center' }}
                  >
                    <Tooltip title={t('members.approve')}>
                      <IconButton
                        color="success"
                        size="small"
                        aria-label={t('members.approve')}
                        onClick={(e) => {
                          e.stopPropagation();
                          onApprove?.(member);
                        }}
                      >
                        <CheckCircleIcon />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title={t('members.reject')}>
                      <IconButton
                        color="error"
                        size="small"
                        aria-label={t('members.reject')}
                        onClick={(e) => {
                          e.stopPropagation();
                          onReject?.(member);
                        }}
                      >
                        <CancelIcon />
                      </IconButton>
                    </Tooltip>
                  </Box>
                ) : null,
            },
          ]
        : []),
    ],
    [t, formatDate, showApprovalActions, onApprove, onReject]
  );

  const handleRowClick = useCallback(
    (member: MemberListItem) => {
      if (onRowClick) {
        onRowClick(member);
      }
    },
    [onRowClick]
  );

  return (
    <DataTable
      columns={columns}
      data={members}
      keyExtractor={(member) => member.id}
      onRowClick={onRowClick ? handleRowClick : undefined}
    />
  );
};
