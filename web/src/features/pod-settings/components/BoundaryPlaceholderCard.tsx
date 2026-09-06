import { type FC } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Chip from '@mui/material/Chip';
import Tooltip from '@mui/material/Tooltip';
import Typography from '@mui/material/Typography';

import { MainCard } from '@/components/atoms/MainCard';
import { Button } from '@/components/atoms/Button';

interface BoundaryPlaceholderCardProps {
  readonly title: string;
  readonly description: string;
}

/**
 * Visible-but-disabled placeholder for a boundary configuration section.
 * Boundary geometry is post-MVP; this card exists so a pod chief sees the
 * feature is planned instead of missing entirely. Molecule-level: no data
 * fetching.
 */
export const BoundaryPlaceholderCard: FC<BoundaryPlaceholderCardProps> = ({
  title,
  description,
}) => {
  const { t } = useTranslation();

  return (
    <MainCard
      aria-disabled="true"
      sx={{ bgcolor: 'action.hover', flex: 1, display: 'flex', flexDirection: 'column' }}
      contentSx={{ flex: 1, display: 'flex', flexDirection: 'column' }}
      title={title}
      secondary={
        <Chip
          label={t('common.comingSoon', 'Coming soon')}
          size="small"
          color="default"
          variant="outlined"
          sx={{ mt: 0.25 }}
        />
      }
    >
      <Typography variant="body2" color="text.secondary" sx={{ flex: 1 }}>
        {description}
      </Typography>
      <Box sx={{ display: 'flex', justifyContent: 'flex-end', mt: 2 }}>
        <Tooltip
          title={t('podSettings.boundaries.comingSoonHint', 'Boundary editing is not available yet.')}
        >
          <span>
            <Button variant="primary" disabled>
              {t('podSettings.boundaries.configure', 'Configure boundaries')}
            </Button>
          </span>
        </Tooltip>
      </Box>
    </MainCard>
  );
};
