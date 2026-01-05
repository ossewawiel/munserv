import { type FC } from 'react';
import { useTranslation } from 'react-i18next';

import { IssueStateBadge } from '@/components/molecules/IssueStateBadge';
import { IssueTypeBadge } from '@/components/molecules/IssueTypeBadge';
import { HeatIndicator } from '@/components/molecules/HeatIndicator';
import type { Issue } from '../types';

interface IssueInfoCardProps {
  issue: Issue;
}

export const IssueInfoCard: FC<IssueInfoCardProps> = ({ issue }) => {
  const { t } = useTranslation();

  const infoItems = [
    {
      label: t('issues.type'),
      value: <IssueTypeBadge type={issue.type} />,
    },
    {
      label: t('issues.state'),
      value: <IssueStateBadge state={issue.state} />,
    },
    {
      label: t('issues.heat'),
      value: <HeatIndicator heat={issue.heat} size="md" />,
    },
    {
      label: t('issues.reportCount'),
      value: issue.reportCount,
    },
    {
      label: t('issues.location'),
      value: issue.address || `${issue.location.latitude.toFixed(4)}, ${issue.location.longitude.toFixed(4)}`,
    },
    {
      label: t('issues.createdAt'),
      value: new Date(issue.createdAt).toLocaleDateString(undefined, {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
      }),
    },
    {
      label: t('issues.updatedAt'),
      value: new Date(issue.updatedAt).toLocaleDateString(undefined, {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
      }),
    },
  ];

  return (
    <div className="rounded-lg border border-border bg-background p-6">
      <dl className="space-y-4">
        {infoItems.map((item) => (
          <div key={item.label} className="flex flex-col gap-1 sm:flex-row sm:gap-4">
            <dt className="w-32 flex-shrink-0 text-sm font-medium text-text-muted">
              {item.label}
            </dt>
            <dd className="text-sm text-text">{item.value}</dd>
          </div>
        ))}
        {issue.description && (
          <div className="flex flex-col gap-1 sm:flex-row sm:gap-4">
            <dt className="w-32 flex-shrink-0 text-sm font-medium text-text-muted">
              {t('issues.description')}
            </dt>
            <dd className="text-sm text-text">{issue.description}</dd>
          </div>
        )}
      </dl>
    </div>
  );
};
