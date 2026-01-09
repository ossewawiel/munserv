import { type FC } from 'react';
import { useTranslation } from 'react-i18next';

import { Badge } from '@/components/atoms/Badge';
import type { MemberStatus } from '@/features/auth/types';

interface MemberStatusBadgeProps {
  status: MemberStatus;
}

const statusVariants: Record<
  MemberStatus,
  'default' | 'success' | 'warning' | 'danger' | 'info'
> = {
  active: 'success',
  pending_approval: 'warning',
  suspended: 'danger',
};

export const MemberStatusBadge: FC<MemberStatusBadgeProps> = ({ status }) => {
  const { t } = useTranslation();

  return (
    <Badge variant={statusVariants[status]}>
      {t(`members.statuses.${status}`)}
    </Badge>
  );
};
