import { type FC } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';
import Stepper from '@mui/material/Stepper';
import Step from '@mui/material/Step';
import StepLabel from '@mui/material/StepLabel';
import StepConnector, { stepConnectorClasses } from '@mui/material/StepConnector';
import { styled } from '@mui/material/styles';

import { IssueStateBadge } from '@/components/molecules/IssueStateBadge';
import type { StateHistoryEntry } from '../types';

interface HorizontalTimelineProps {
  history: StateHistoryEntry[];
}

const TimelineConnector = styled(StepConnector)(({ theme }) => ({
  [`&.${stepConnectorClasses.alternativeLabel}`]: {
    top: 12,
  },
  [`&.${stepConnectorClasses.completed}`]: {
    [`& .${stepConnectorClasses.line}`]: {
      backgroundColor: theme.palette.primary.main,
    },
  },
  [`& .${stepConnectorClasses.line}`]: {
    height: 3,
    border: 0,
    backgroundColor: theme.palette.divider,
    borderRadius: 1,
  },
}));

const TimelineStepIcon: FC<{ completed: boolean }> = ({ completed }) => (
  <Box
    sx={{
      width: 24,
      height: 24,
      borderRadius: '50%',
      bgcolor: completed ? 'primary.main' : 'action.disabled',
      border: 2,
      borderColor: completed ? 'primary.main' : 'divider',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
    }}
  >
    <Box
      sx={{
        width: 8,
        height: 8,
        borderRadius: '50%',
        bgcolor: completed ? 'background.paper' : 'transparent',
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

      <Box sx={{ overflowX: 'auto', pb: 1 }}>
        <Stepper
          alternativeLabel
          activeStep={history.length - 1}
          connector={<TimelineConnector />}
          role="list"
          sx={{ minWidth: history.length * 150 }}
        >
          {history.map((entry, index) => (
            <Step key={`${entry.state}-${entry.changedAt}`} completed={true}>
              <StepLabel
                StepIconComponent={() => (
                  <TimelineStepIcon completed={index <= history.length - 1} />
                )}
              >
                <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 0.5 }}>
                  <IssueStateBadge state={entry.state} />
                  <Typography
                    variant="caption"
                    color="text.secondary"
                    sx={{ fontWeight: 500 }}
                  >
                    {formatDate(entry.changedAt)}
                  </Typography>
                  {entry.changedBy && (
                    <Typography
                      variant="caption"
                      color="text.disabled"
                      sx={{ fontSize: '0.65rem' }}
                    >
                      {entry.changedBy}
                    </Typography>
                  )}
                </Box>
              </StepLabel>
            </Step>
          ))}
        </Stepper>
      </Box>
    </Paper>
  );
};
