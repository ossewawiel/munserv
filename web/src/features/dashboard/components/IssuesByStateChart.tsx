import { type FC, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { clsx } from 'clsx';

import type { IssueState } from '@/features/issues/types';

interface IssuesByStateChartProps {
  byState: Record<IssueState, number>;
}

const stateColors: Record<IssueState, string> = {
  reported: 'bg-info-500',
  confirmed: 'bg-warning-500',
  in_progress: 'bg-accent-500',
  fixed: 'bg-success-500',
  rejected: 'bg-danger-500',
};

const STATES_ORDER: IssueState[] = ['reported', 'confirmed', 'in_progress', 'fixed', 'rejected'];

export const IssuesByStateChart: FC<IssuesByStateChartProps> = ({ byState }) => {
  const { t } = useTranslation();

  const { total, items } = useMemo(() => {
    const totalCount = Object.values(byState).reduce((sum, count) => sum + count, 0);
    const chartItems = STATES_ORDER.map((state) => ({
      state,
      count: byState[state] || 0,
      percentage: totalCount > 0 ? ((byState[state] || 0) / totalCount) * 100 : 0,
    }));
    return { total: totalCount, items: chartItems };
  }, [byState]);

  return (
    <div className="rounded-lg border border-border bg-background p-6">
      <h3 className="mb-4 text-lg font-semibold text-text">{t('dashboard.byState')}</h3>
      <div className="space-y-4">
        {items.map(({ state, count, percentage }) => (
          <div key={state}>
            <div className="mb-1 flex items-center justify-between text-sm">
              <span className="text-text">{t(`issues.states.${state}`)}</span>
              <span className="font-medium text-text">{count}</span>
            </div>
            <div className="h-2 overflow-hidden rounded-full bg-secondary-200">
              <div
                className={clsx('h-full rounded-full transition-all', stateColors[state])}
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
