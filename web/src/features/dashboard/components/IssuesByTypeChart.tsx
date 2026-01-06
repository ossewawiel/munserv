import { type FC, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import LinearProgress from '@mui/material/LinearProgress';

import { MainCard } from '@/components/atoms/MainCard';
import type { IssueType } from '@/features/issues/types';

interface IssuesByTypeChartProps {
  byType: Partial<Record<IssueType, number>>;
}

const TYPES_ORDER: IssueType[] = [
  'pothole',
  'water_leak',
  'sewage_leak',
  'traffic_light',
  'street_light',
  'illegal_dumping',
  'other',
];

export const IssuesByTypeChart: FC<IssuesByTypeChartProps> = ({ byType }) => {
  const { t } = useTranslation();

  const { total, items } = useMemo(() => {
    const totalCount = Object.values(byType).reduce((sum, count) => sum + (count || 0), 0);
    const chartItems = TYPES_ORDER
      .map((type) => ({
        type,
        count: byType[type] || 0,
        percentage: totalCount > 0 ? ((byType[type] || 0) / totalCount) * 100 : 0,
      }))
      .filter((item) => item.count > 0)
      .sort((a, b) => b.count - a.count);
    return { total: totalCount, items: chartItems };
  }, [byType]);

  return (
    <MainCard title={t('dashboard.byType')} divider={false}>
      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
        {items.map(({ type, count, percentage }) => (
          <Box key={type}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
              <Typography variant="body2" color="text.primary">
                {t(`issues.types.${type}`)}
              </Typography>
              <Typography variant="body2" fontWeight={500} color="text.primary">
                {count}
              </Typography>
            </Box>
            <LinearProgress
              variant="determinate"
              value={percentage}
              sx={{
                height: 8,
                borderRadius: 4,
                bgcolor: 'action.hover',
                '& .MuiLinearProgress-bar': {
                  borderRadius: 4,
                  bgcolor: 'primary.main',
                },
              }}
            />
          </Box>
        ))}
      </Box>
      {total === 0 && (
        <Typography variant="body2" color="text.secondary" sx={{ mt: 2, textAlign: 'center' }}>
          {t('common.noResults')}
        </Typography>
      )}
    </MainCard>
  );
};
