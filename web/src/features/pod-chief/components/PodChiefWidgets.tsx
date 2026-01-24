import { type FC } from 'react';
import { useTranslation } from 'react-i18next';
import Grid from '@mui/material/Grid';
import Skeleton from '@mui/material/Skeleton';
import AssignmentOutlinedIcon from '@mui/icons-material/AssignmentOutlined';
import CheckCircleOutlineIcon from '@mui/icons-material/CheckCircleOutline';
import PendingActionsOutlinedIcon from '@mui/icons-material/PendingActionsOutlined';
import SupervisorAccountOutlinedIcon from '@mui/icons-material/SupervisorAccountOutlined';
import PeopleOutlineIcon from '@mui/icons-material/PeopleOutline';
import PersonPinCircleOutlinedIcon from '@mui/icons-material/PersonPinCircleOutlined';
import LocationCityOutlinedIcon from '@mui/icons-material/LocationCityOutlined';
import GridViewOutlinedIcon from '@mui/icons-material/GridViewOutlined';

import { StatCard } from '@/components/molecules/StatCard';
import { gridSpacing } from '@/theme';
import type { PodDashboardStats } from '../types';

interface PodChiefWidgetsProps {
  /** Dashboard statistics from the backend */
  stats: PodDashboardStats | undefined;
  /** Loading state */
  isLoading?: boolean;
}

/**
 * Dashboard widgets for Pod Chief role.
 * Displays pod-level statistics including issues, administrators, and organizational structure.
 */
export const PodChiefWidgets: FC<PodChiefWidgetsProps> = ({ stats, isLoading = false }) => {
  const { t } = useTranslation();

  if (isLoading || !stats) {
    return (
      <Grid container spacing={gridSpacing}>
        {Array.from({ length: 8 }).map((_, i) => (
          <Grid key={i} size={{ xs: 12, sm: 6, lg: 3 }}>
            <Skeleton variant="rounded" height={140} />
          </Grid>
        ))}
      </Grid>
    );
  }

  return (
    <Grid container spacing={gridSpacing}>
      {/* Row 1: Issue metrics */}
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
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <StatCard
          title={t('podChief.dashboard.pendingIssues')}
          value={stats.pendingIssues}
          variant="secondary"
          colored
          icon={<PendingActionsOutlinedIcon />}
        />
      </Grid>

      {/* Row 2: People metrics */}
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <StatCard
          title={t('podChief.dashboard.activeAdmins')}
          value={stats.activeAdministrators}
          variant="info"
          icon={<SupervisorAccountOutlinedIcon />}
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
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <StatCard
          title={t('podChief.dashboard.activeGroundAdmins')}
          value={stats.activeGroundAdmins}
          variant="success"
          icon={<PersonPinCircleOutlinedIcon />}
        />
      </Grid>

      {/* Row 2 continued: Organizational structure */}
      <Grid size={{ xs: 6, sm: 3, lg: 1.5 }}>
        <StatCard
          title={t('podChief.dashboard.wards')}
          value={stats.wardCount}
          variant="secondary"
          icon={<LocationCityOutlinedIcon />}
        />
      </Grid>
      <Grid size={{ xs: 6, sm: 3, lg: 1.5 }}>
        <StatCard
          title={t('podChief.dashboard.sectors')}
          value={stats.sectorCount}
          variant="secondary"
          icon={<GridViewOutlinedIcon />}
        />
      </Grid>
    </Grid>
  );
};
