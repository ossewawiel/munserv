import { type FC, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import LinearProgress from '@mui/material/LinearProgress';

import { MainCard } from '@/components/atoms/MainCard';
import { issueStateColors } from '@/theme';
import type { IssueState } from '@/features/issues/types';

interface IssuesByStateChartProps {
  byState: Record<IssueState, number>;
}

const STATES_ORDER: IssueState[] = ['reported', 'confirmed', 'in_progress', 'fixed', 'rejected'];

export const IssuesByStateChart: FC<IssuesByStateChartProps> = ({ byState }) => {
  const { t } = useTranslation();

  const { total, items } = useMemo(() => {
    const totalCount = Object.values(byState).reduce((sum, count) => sum + count, 0);
    const chartItems = STATES_ORDER.map((state) => ({
      state,
      count: byState[state] || 0,
      percentage: totalCount > 0 ? ((byState[state] || 0) / totalCount) * 100 : 0,
    }));
    return { total: totalCount, items: chartItems };
  }, [byState]);

  return (
    <MainCard title={t('dashboard.byState')} divider={false}>
      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
        {items.map(({ state, count, percentage }) => (
          <Box key={state}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
              <Typography variant="body2" sx={{
                color: "text.primary"
              }}>
                {t(`issues.states.${state}`)}
              </Typography>
              <Typography
                variant="body2"
                sx={{
                  fontWeight: 500,
                  color: "text.primary"
                }}>
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
                  bgcolor: issueStateColors[state],
                },
              }}
            />
          </Box>
        ))}
      </Box>
      {total === 0 && (
        <Typography
          variant="body2"
          sx={{
            color: "text.secondary",
            mt: 2,
            textAlign: 'center'
          }}>
          {t('common.noResults')}
        </Typography>
      )}
    </MainCard>
  );
};
