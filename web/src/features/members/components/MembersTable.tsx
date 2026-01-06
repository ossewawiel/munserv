import { type FC, useMemo, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Avatar from '@mui/material/Avatar';
import Typography from '@mui/material/Typography';
import AssignmentIcon from '@mui/icons-material/Assignment';

import { DataTable, type Column } from '@/components/organisms/DataTable';
import { MemberStatusBadge } from '@/components/molecules/MemberStatusBadge';
import type { MemberListItem } from '../types';

interface MembersTableProps {
  members: MemberListItem[];
  onRowClick?: (member: MemberListItem) => void;
}

export const MembersTable: FC<MembersTableProps> = ({
  members,
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
                bgcolor: 'primary.light',
                color: 'primary.contrastText',
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
                {member.phoneNumber}
              </Typography>
            </Box>
          </Box>
        ),
      },
      {
        key: 'address',
        header: t('members.address'),
        render: (member) => (
          <Typography variant="body2" color="text.secondary">
            {member.address}
          </Typography>
        ),
      },
      {
        key: 'status',
        header: t('members.status'),
        width: '120px',
        render: (member) => <MemberStatusBadge status={member.status} />,
      },
      {
        key: 'issuesReported',
        header: t('members.issuesReported'),
        width: '140px',
        align: 'center',
        render: (member) => (
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, color: 'text.secondary' }}>
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
    ],
    [t, formatDate]
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
