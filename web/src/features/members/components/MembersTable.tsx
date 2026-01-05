import { type FC, useMemo, useCallback } from 'react';
import { useTranslation } from 'react-i18next';

import { DataTable, type Column } from '@/components/organisms/DataTable';
import { MemberStatusBadge } from '@/components/molecules/MemberStatusBadge';
import type { MemberListItem } from '../types';

interface MembersTableProps {
  members: MemberListItem[];
  onRowClick?: (member: MemberListItem) => void;
  className?: string;
}

export const MembersTable: FC<MembersTableProps> = ({
  members,
  onRowClick,
  className,
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
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary-100 text-sm font-semibold text-primary-700">
              {member.firstName.charAt(0)}
              {member.surname.charAt(0)}
            </div>
            <div>
              <div className="font-medium text-text">
                {member.firstName} {member.surname}
              </div>
              <div className="text-sm text-text-muted">{member.phoneNumber}</div>
            </div>
          </div>
        ),
      },
      {
        key: 'address',
        header: t('members.address'),
        render: (member) => (
          <span className="text-text-muted">{member.address}</span>
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
          <span className="inline-flex items-center gap-1 text-text-muted">
            <svg
              className="h-4 w-4"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
              />
            </svg>
            {member.issueCount}
          </span>
        ),
      },
      {
        key: 'joinedAt',
        header: t('members.joinedAt'),
        width: '130px',
        render: (member) => (
          <span className="text-text-muted">{formatDate(member.joinedAt)}</span>
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
      className={className}
    />
  );
};
