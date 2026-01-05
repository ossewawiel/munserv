import { type FC } from 'react';
import { useTranslation } from 'react-i18next';

import { Badge } from '@/components/atoms/Badge';
import type { IssueState } from '@/features/issues/types';

interface IssueStateBadgeProps {
  state: IssueState;
}

const stateVariants: Record<IssueState, 'default' | 'success' | 'warning' | 'danger' | 'info'> = {
  reported: 'info',
  confirmed: 'warning',
  in_progress: 'warning',
  fixed: 'success',
  rejected: 'danger',
};

export const IssueStateBadge: FC<IssueStateBadgeProps> = ({ state }) => {
  const { t } = useTranslation();

  return (
    <Badge variant={stateVariants[state]}>
      {t(`issues.states.${state}`)}
    </Badge>
  );
};
