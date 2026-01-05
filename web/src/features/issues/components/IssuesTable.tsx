import { type FC, useMemo } from 'react';
import { useTranslation } from 'react-i18next';

import { DataTable, type Column } from '@/components/organisms/DataTable';
import { IssueStateBadge } from '@/components/molecules/IssueStateBadge';
import { IssueTypeBadge } from '@/components/molecules/IssueTypeBadge';
import { HeatBadge } from '@/components/molecules/HeatIndicator';
import { EmptyState } from '@/components/molecules/EmptyState';
import type { IssueSummary } from '../types';

interface IssuesTableProps {
  issues: IssueSummary[];
  onRowClick: (issue: IssueSummary) => void;
}

export const IssuesTable: FC<IssuesTableProps> = ({ issues, onRowClick }) => {
  const { t } = useTranslation();

  const columns = useMemo<Column<IssueSummary>[]>(
    () => [
      {
        key: 'thumbnail',
        header: '',
        width: '60px',
        render: (issue) => (
          <img
            src={issue.thumbnailUrl}
            alt=""
            className="h-10 w-10 rounded object-cover"
          />
        ),
      },
      {
        key: 'type',
        header: t('issues.type'),
        render: (issue) => <IssueTypeBadge type={issue.type} />,
      },
      {
        key: 'state',
        header: t('issues.state'),
        render: (issue) => <IssueStateBadge state={issue.state} />,
      },
      {
        key: 'heat',
        header: t('issues.heat'),
        align: 'center' as const,
        render: (issue) => <HeatBadge heat={issue.heat} />,
      },
      {
        key: 'createdAt',
        header: t('issues.createdAt'),
        render: (issue) =>
          new Date(issue.createdAt).toLocaleDateString(undefined, {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
          }),
      },
    ],
    [t]
  );

  return (
    <DataTable
      columns={columns}
      data={issues}
      keyExtractor={(issue) => issue.id}
      onRowClick={onRowClick}
      emptyMessage={
        <EmptyState
          title={t('common.noResults')}
          description={t('issues.noIssuesDescription')}
        />
      }
    />
  );
};
