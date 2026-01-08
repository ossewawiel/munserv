import { type FC } from 'react';
import { useTranslation } from 'react-i18next';

import { IssueStateBadge } from '@/components/molecules/IssueStateBadge';
import type { StateHistoryEntry } from '../types';

interface StateHistoryProps {
  history: StateHistoryEntry[];
}

export const StateHistory: FC<StateHistoryProps> = ({ history }) => {
  const { t } = useTranslation();

  if (history.length === 0) {
    return (
      <div className="rounded-lg border border-border bg-background p-6">
        <h3 className="mb-4 text-lg font-semibold text-text">
          {t('issues.stateHistory')}
        </h3>
        <p className="text-sm text-text-muted">{t('common.noResults')}</p>
      </div>
    );
  }

  return (
    <div className="rounded-lg border border-border bg-background p-6">
      <h3 className="mb-4 text-lg font-semibold text-text">
        {t('issues.stateHistory')}
      </h3>
      <div className="relative">
        <div className="absolute left-3 top-0 h-full w-0.5 bg-border" />
        <ul className="space-y-4">
          {history.map((entry) => (
            <li key={`${entry.state}-${entry.changedAt}`} className="relative pl-8">
              <div className="absolute left-1.5 top-1.5 h-3 w-3 rounded-full border-2 border-primary-500 bg-background" />
              <div className="flex flex-col gap-1">
                <div className="flex items-center gap-2">
                  <IssueStateBadge state={entry.state} />
                  <span className="text-sm text-text-muted">
                    {new Date(entry.changedAt).toLocaleDateString(undefined, {
                      year: 'numeric',
                      month: 'short',
                      day: 'numeric',
                      hour: '2-digit',
                      minute: '2-digit',
                    })}
                  </span>
                </div>
                {entry.changedBy && (
                  <p className="text-sm text-text-muted">
                    by {entry.changedBy}
                  </p>
                )}
                {entry.note && (
                  <p className="text-sm text-text">{entry.note}</p>
                )}
              </div>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
};
