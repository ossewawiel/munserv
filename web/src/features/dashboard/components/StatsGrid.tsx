import { type FC } from 'react';
import { useTranslation } from 'react-i18next';
import Grid from '@mui/material/Grid';
import AssignmentOutlinedIcon from '@mui/icons-material/AssignmentOutlined';
import ScheduleOutlinedIcon from '@mui/icons-material/ScheduleOutlined';
import EqualizerOutlinedIcon from '@mui/icons-material/EqualizerOutlined';
import BoltOutlinedIcon from '@mui/icons-material/BoltOutlined';

import { StatCard } from '@/components/molecules/StatCard';
import { gridSpacing } from '@/theme';
import type { DashboardStats } from '../types';

interface StatsGridProps {
  stats: DashboardStats['stats'];
}

export const StatsGrid: FC<StatsGridProps> = ({ stats }) => {
  const { t } = useTranslation();

  return (
    <Grid container spacing={gridSpacing}>
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <StatCard
          title={t('dashboard.totalOpen')}
          value={stats.totalOpen}
          variant="primary"
          colored
          icon={<AssignmentOutlinedIcon />}
        />
      </Grid>
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <StatCard
          title={t('dashboard.reportedThisWeek')}
          value={stats.reportedThisWeek}
          variant="secondary"
          colored
          icon={<ScheduleOutlinedIcon />}
        />
      </Grid>
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <StatCard
          title={t('dashboard.avgResolution')}
          value={stats.avgResolutionDays}
          subtitle={t('dashboard.days')}
          variant="primary"
          colored
          icon={<EqualizerOutlinedIcon />}
        />
      </Grid>
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <StatCard
          title={t('issues.states.in_progress')}
          value={stats.byState.in_progress || 0}
          variant="secondary"
          colored
          icon={<BoltOutlinedIcon />}
        />
      </Grid>
    </Grid>
  );
};
