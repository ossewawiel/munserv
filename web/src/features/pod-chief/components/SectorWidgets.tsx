import { type FC } from 'react';
import { useTranslation } from 'react-i18next';
import Grid from '@mui/material/Grid';
import Skeleton from '@mui/material/Skeleton';
import AssignmentOutlinedIcon from '@mui/icons-material/AssignmentOutlined';
import CheckCircleOutlineIcon from '@mui/icons-material/CheckCircleOutline';
import PendingActionsOutlinedIcon from '@mui/icons-material/PendingActionsOutlined';
import PersonPinCircleOutlinedIcon from '@mui/icons-material/PersonPinCircleOutlined';
import PeopleOutlineIcon from '@mui/icons-material/PeopleOutline';

import { StatCard } from '@/components/molecules/StatCard';
import { gridSpacing } from '@/theme';
import type { SectorDashboardStats } from '../types';

interface SectorWidgetsProps {
  /** Dashboard statistics from the backend */
  stats: SectorDashboardStats | undefined;
  /** Loading state */
  isLoading?: boolean;
}

/**
 * Dashboard widgets for sector-level view.
 * Displays sector-filtered statistics including issues, ground admins, and members.
 */
export const SectorWidgets: FC<SectorWidgetsProps> = ({ stats, isLoading = false }) => {
  const { t } = useTranslation();

  if (isLoading || !stats) {
    return (
      <Grid container spacing={gridSpacing}>
        {Array.from({ length: 5 }).map((_, i) => (
          <Grid key={i} size={{ xs: 12, sm: 6, lg: 3 }}>
            <Skeleton variant="rounded" height={140} />
          </Grid>
        ))}
      </Grid>
    );
  }

  return (
    <Grid container spacing={gridSpacing}>
      {/* Issue metrics */}
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <StatCard
          title={t('podChief.dashboard.totalIssues')}
          value={stats.totalIssues}
          variant="primary"
          colored
          icon={<AssignmentOutlinedIcon />}
        />
      </Grid>
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <StatCard
          title={t('podChief.dashboard.openIssues')}
          value={stats.openIssues}
          variant="warning"
          colored
          icon={<PendingActionsOutlinedIcon />}
        />
      </Grid>
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <StatCard
          title={t('podChief.dashboard.resolvedThisMonth')}
          value={stats.resolvedThisMonth}
          variant="success"
          colored
          icon={<CheckCircleOutlineIcon />}
        />
      </Grid>

      {/* People metrics */}
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <StatCard
          title={t('podChief.dashboard.activeGroundAdmins')}
          value={stats.activeGroundAdmins}
          variant="success"
          icon={<PersonPinCircleOutlinedIcon />}
        />
      </Grid>
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <StatCard
          title={t('podChief.dashboard.totalMembers')}
          value={stats.totalMembers}
          variant="primary"
          icon={<PeopleOutlineIcon />}
        />
      </Grid>
    </Grid>
  );
};
