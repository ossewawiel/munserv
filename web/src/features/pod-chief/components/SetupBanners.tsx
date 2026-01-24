import { type FC } from 'react';
import Box from '@mui/material/Box';

import type { SetupStep } from '@/shared/hooks/usePodSetup';
import { SetupBanner } from './SetupBanner';

interface SetupBannersProps {
  /** List of incomplete setup steps to display banners for */
  missingSteps: SetupStep[];
}

/**
 * Container for setup task banners.
 * Displays a banner for each incomplete setup step.
 * Banners automatically disappear when their corresponding step is completed.
 */
export const SetupBanners: FC<SetupBannersProps> = ({ missingSteps }) => {
  if (missingSteps.length === 0) {
    return null;
  }

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
      {missingSteps.map((step) => (
        <SetupBanner key={step} step={step} />
      ))}
    </Box>
  );
};
