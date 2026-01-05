import { type FC, useMemo } from 'react';
import { useTranslation } from 'react-i18next';

import type { IssueType } from '@/features/issues/types';

interface IssuesByTypeChartProps {
  byType: Partial<Record<IssueType, number>>;
}

const TYPES_ORDER: IssueType[] = [
  'pothole',
  'water_leak',
  'sewage_leak',
  'traffic_light',
  'street_light',
  'illegal_dumping',
  'other',
];

export const IssuesByTypeChart: FC<IssuesByTypeChartProps> = ({ byType }) => {
  const { t } = useTranslation();

  const { total, items } = useMemo(() => {
    const totalCount = Object.values(byType).reduce((sum, count) => sum + (count || 0), 0);
    const chartItems = TYPES_ORDER
      .map((type) => ({
        type,
        count: byType[type] || 0,
        percentage: totalCount > 0 ? ((byType[type] || 0) / totalCount) * 100 : 0,
      }))
      .filter((item) => item.count > 0)
      .sort((a, b) => b.count - a.count);
    return { total: totalCount, items: chartItems };
  }, [byType]);

  return (
    <div className="rounded-lg border border-border bg-background p-6">
      <h3 className="mb-4 text-lg font-semibold text-text">{t('dashboard.byType')}</h3>
      <div className="space-y-4">
        {items.map(({ type, count, percentage }) => (
          <div key={type}>
            <div className="mb-1 flex items-center justify-between text-sm">
              <span className="text-text">{t(`issues.types.${type}`)}</span>
              <span className="font-medium text-text">{count}</span>
            </div>
            <div className="h-2 overflow-hidden rounded-full bg-secondary-200">
              <div
                className="h-full rounded-full bg-primary-500 transition-all"
                style={{ width: `${percentage}%` }}
              />
            </div>
          </div>
        ))}
      </div>
      {total === 0 && (
        <p className="mt-4 text-center text-sm text-text-muted">
          {t('common.noResults')}
        </p>
      )}
    </div>
  );
};
