import { type FC, useMemo } from 'react';
import Box from '@mui/material/Box';
import LinearProgress from '@mui/material/LinearProgress';
import Typography from '@mui/material/Typography';
import Chip from '@mui/material/Chip';

import { getHeatLevel, heatColors, type HeatLevel } from '@/theme/colors';

interface HeatIndicatorProps {
  heat: number;
  showValue?: boolean;
  size?: 'sm' | 'md' | 'lg';
}

const sizeMap = {
  sm: { height: 6, fontSize: '0.75rem' },
  md: { height: 8, fontSize: '0.875rem' },
  lg: { height: 12, fontSize: '1rem' },
};

const heatColorValues: Record<HeatLevel, string> = {
  critical: heatColors.critical,
  high: heatColors.high,
  medium: heatColors.medium,
  low: heatColors.low,
  minimal: heatColors.minimal,
};

export const HeatIndicator: FC<HeatIndicatorProps> = ({
  heat,
  showValue = true,
  size = 'md',
}) => {
  const heatLevel = useMemo(() => getHeatLevel(heat), [heat]);
  const { height, fontSize } = sizeMap[size];
  const color = heatColorValues[heatLevel];

  return (
    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
      <Box sx={{ flexGrow: 1 }}>
        <LinearProgress
          variant="determinate"
          value={Math.min(heat, 100)}
          sx={{
            height,
            borderRadius: 1,
            bgcolor: 'action.hover',
            '& .MuiLinearProgress-bar': {
              bgcolor: color,
              borderRadius: 1,
            },
          }}
        />
      </Box>
      {showValue && (
        <Typography
          sx={{
            minWidth: 40,
            fontWeight: 600,
            fontSize,
            color,
          }}
        >
          {heat}
        </Typography>
      )}
    </Box>
  );
};

interface HeatBadgeProps {
  heat: number;
}

export const HeatBadge: FC<HeatBadgeProps> = ({ heat }) => {
  const heatLevel = useMemo(() => getHeatLevel(heat), [heat]);
  const color = heatColorValues[heatLevel];

  return (
    <Chip
      label={heat}
      size="small"
      sx={{
        fontWeight: 600,
        bgcolor: `${color}20`,
        color,
        borderColor: `${color}40`,
        border: 1,
      }}
    />
  );
};
