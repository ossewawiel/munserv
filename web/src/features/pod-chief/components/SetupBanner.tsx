import { type FC } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Alert from '@mui/material/Alert';
import AlertTitle from '@mui/material/AlertTitle';
import Button from '@mui/material/Button';
import SettingsIcon from '@mui/icons-material/Settings';
import MapIcon from '@mui/icons-material/Map';
import LocationCityIcon from '@mui/icons-material/LocationCity';
import PersonAddIcon from '@mui/icons-material/PersonAdd';

import type { SetupStep } from '@/shared/hooks/usePodSetup';

interface SetupBannerProps {
  step: SetupStep;
}

/**
 * Configuration for each setup step banner
 */
const stepConfig: Record<
  SetupStep,
  {
    path: string;
    icon: React.ElementType;
    titleKey: string;
    descriptionKey: string;
  }
> = {
  pod_name: {
    path: '/settings/pod',
    icon: SettingsIcon,
    titleKey: 'podChief.setup.podName',
    descriptionKey: 'podChief.setup.podNameDescription',
  },
  pod_boundaries: {
    path: '/settings/pod#boundaries',
    icon: MapIcon,
    titleKey: 'podChief.setup.podBoundaries',
    descriptionKey: 'podChief.setup.podBoundariesDescription',
  },
  wards_sectors: {
    path: '/settings/pod#wards',
    icon: LocationCityIcon,
    titleKey: 'podChief.setup.wardsSectors',
    descriptionKey: 'podChief.setup.wardsSectorsDescription',
  },
  first_admin: {
    path: '/pod-administrators',
    icon: PersonAddIcon,
    titleKey: 'podChief.setup.firstAdmin',
    descriptionKey: 'podChief.setup.firstAdminDescription',
  },
};

/**
 * Single setup task banner component.
 * Displays an info alert with the setup step details and a configure button.
 */
export const SetupBanner: FC<SetupBannerProps> = ({ step }) => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const config = stepConfig[step];
  const Icon = config.icon;

  return (
    <Alert
      severity="info"
      icon={<Icon />}
      action={
        <Button
          color="inherit"
          size="small"
          onClick={() => navigate(config.path)}
          sx={{ whiteSpace: 'nowrap' }}
        >
          {t('common.configure')}
        </Button>
      }
      sx={{
        '& .MuiAlert-message': {
          flex: 1,
        },
      }}
    >
      <AlertTitle sx={{ fontWeight: 600 }}>{t(config.titleKey)}</AlertTitle>
      {t(config.descriptionKey)}
    </Alert>
  );
};
