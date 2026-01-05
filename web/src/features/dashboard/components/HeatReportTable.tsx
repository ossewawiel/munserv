import { type FC, useMemo, useCallback } from 'react';
import { useTranslation } from 'react-i18next';

import { DataTable, type Column } from '@/components/organisms/DataTable';
import { IssueStateBadge } from '@/components/molecules/IssueStateBadge';
import { IssueTypeBadge } from '@/components/molecules/IssueTypeBadge';
import { HeatBadge } from '@/components/molecules/HeatIndicator';
import type { HeatReportItem } from '../types';

interface HeatReportTableProps {
  items: HeatReportItem[];
  onRowClick?: (item: HeatReportItem) => void;
  className?: string;
}

export const HeatReportTable: FC<HeatReportTableProps> = ({
  items,
  onRowClick,
  className,
}) => {
  const { t } = useTranslation();

  const columns: Column<HeatReportItem & { rank: number }>[] = useMemo(
    () => [
      {
        key: 'rank',
        header: t('heatReport.rank'),
        width: '60px',
        align: 'center',
        render: (item) => (
          <span className="inline-flex h-7 w-7 items-center justify-center rounded-full bg-primary-100 text-sm font-bold text-primary-700">
            {item.rank}
          </span>
        ),
      },
      {
        key: 'thumbnail',
        header: '',
        width: '64px',
        render: (item) => (
          <img
            src={item.thumbnailUrl}
            alt={t(`issues.types.${item.type}`)}
            className="h-12 w-12 rounded-md object-cover"
          />
        ),
      },
      {
        key: 'type',
        header: t('issues.type'),
        render: (item) => <IssueTypeBadge type={item.type} />,
      },
      {
        key: 'state',
        header: t('issues.state'),
        render: (item) => <IssueStateBadge state={item.state} />,
      },
      {
        key: 'heat',
        header: t('issues.heat'),
        width: '100px',
        align: 'center',
        render: (item) => <HeatBadge heat={item.heat} />,
      },
      {
        key: 'daysOpen',
        header: t('heatReport.daysOpen'),
        width: '100px',
        align: 'center',
        render: (item) => (
          <span className="text-text-muted">{item.daysOpen}</span>
        ),
      },
      {
        key: 'reportCount',
        header: t('issues.reportCount'),
        width: '120px',
        align: 'center',
        render: (item) => (
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
                d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
              />
            </svg>
            {item.reportCount}
          </span>
        ),
      },
    ],
    [t]
  );

  const rankedItems = useMemo(
    () => items.map((item, index) => ({ ...item, rank: index + 1 })),
    [items]
  );

  const handleRowClick = useCallback(
    (item: HeatReportItem & { rank: number }) => {
      if (onRowClick) {
        onRowClick(item);
      }
    },
    [onRowClick]
  );

  return (
    <DataTable
      columns={columns}
      data={rankedItems}
      keyExtractor={(item) => item.id}
      onRowClick={handleRowClick}
      className={className}
    />
  );
};
