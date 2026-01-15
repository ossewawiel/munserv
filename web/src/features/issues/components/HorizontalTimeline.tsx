import { type FC, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';

import { IssueStateBadge } from '@/components/molecules/IssueStateBadge';
import type { StateHistoryEntry } from '../types';

interface HorizontalTimelineProps {
  history: StateHistoryEntry[];
}

/**
 * Calculate proportional positions (0-100%) for each timeline entry based on duration.
 * First entry at 0%, last at 100%, others positioned proportionally by time elapsed.
 */
function calculateProportionalPositions(history: StateHistoryEntry[]): number[] {
  if (history.length === 0) return [];
  if (history.length === 1) return [50]; // Center single item

  const timestamps = history.map((entry) => new Date(entry.changedAt).getTime());
  const firstTime = timestamps[0];
  const lastTime = timestamps[timestamps.length - 1];
  const totalDuration = lastTime - firstTime;

  // If all at same time, distribute evenly
  if (totalDuration === 0) {
    return history.map((_, i) => (i / (history.length - 1)) * 100);
  }

  // Calculate proportional positions as percentages
  return timestamps.map((time) => {
    const elapsed = time - firstTime;
    return (elapsed / totalDuration) * 100;
  });
}

/**
 * Get the overall width percentage based on number of status entries.
 * More statuses = wider timeline.
 */
function getTimelineWidthPercent(count: number): number {
  if (count >= 5) return 80; // 80% for all 5 possible states
  if (count >= 3) return 60; // 60% for 3-4 states
  return 40; // 40% for 1-2 states
}

const TimelineNode: FC = () => (
  <Box
    sx={{
      width: 16,
      height: 16,
      borderRadius: '50%',
      bgcolor: 'primary.main',
      border: 2,
      borderColor: 'primary.main',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      flexShrink: 0,
      zIndex: 1,
    }}
  >
    <Box
      sx={{
        width: 6,
        height: 6,
        borderRadius: '50%',
        bgcolor: 'background.paper',
      }}
    />
  </Box>
);

export const HorizontalTimeline: FC<HorizontalTimelineProps> = ({ history }) => {
  const { t } = useTranslation();

  const formatDate = (dateStr: string) =>
    new Date(dateStr).toLocaleDateString(undefined, {
      month: 'short',
      day: 'numeric',
    });

  const positions = useMemo(() => calculateProportionalPositions(history), [history]);
  const timelineWidth = useMemo(() => getTimelineWidthPercent(history.length), [history.length]);

  if (history.length === 0) {
    return (
      <Paper
        elevation={0}
        sx={{
          p: 2.5,
          border: 1,
          borderColor: 'divider',
          borderRadius: 2,
        }}
      >
        <Typography variant="subtitle1" fontWeight={600} sx={{ mb: 2 }}>
          {t('issues.stateHistory')}
        </Typography>
        <Typography variant="body2" color="text.secondary">
          {t('common.noResults')}
        </Typography>
      </Paper>
    );
  }

  return (
    <Paper
      elevation={0}
      sx={{
        p: 2.5,
        border: 1,
        borderColor: 'divider',
        borderRadius: 2,
      }}
    >
      <Typography variant="subtitle1" fontWeight={600} sx={{ mb: 3 }}>
        {t('issues.stateHistory')}
      </Typography>

      {/* Timeline container - centered with proportional width */}
      <Box
        sx={{
          display: 'flex',
          justifyContent: 'center',
          width: '100%',
          overflowX: 'auto',
          pb: 1,
        }}
      >
        <Box
          role="list"
          sx={{
            position: 'relative',
            width: `${timelineWidth}%`,
            minWidth: 250,
            height: 85,
          }}
        >
          {/* Timeline track (horizontal line) */}
          <Box
            sx={{
              position: 'absolute',
              top: 7,
              left: 0,
              right: 0,
              height: 3,
              bgcolor: 'primary.main',
              borderRadius: 1,
            }}
          />

          {/* Timeline entries positioned proportionally */}
          {history.map((entry, index) => (
            <Box
              key={`${entry.state}-${entry.changedAt}`}
              role="listitem"
              sx={{
                position: 'absolute',
                left: `${positions[index]}%`,
                transform: 'translateX(-50%)',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                gap: 0.5,
              }}
            >
              <TimelineNode />
              <IssueStateBadge state={entry.state} />
              <Typography
                variant="caption"
                color="text.secondary"
                sx={{ fontWeight: 500, whiteSpace: 'nowrap' }}
              >
                {formatDate(entry.changedAt)}
              </Typography>
            </Box>
          ))}
        </Box>
      </Box>
    </Paper>
  );
};
