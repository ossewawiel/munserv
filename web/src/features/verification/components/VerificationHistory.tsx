import { type FC } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Card from '@mui/material/Card';
import CardContent from '@mui/material/CardContent';
import CardHeader from '@mui/material/CardHeader';
import Chip from '@mui/material/Chip';
import Divider from '@mui/material/Divider';
import Skeleton from '@mui/material/Skeleton';
import Stack from '@mui/material/Stack';
import Timeline from '@mui/lab/Timeline';
import TimelineItem from '@mui/lab/TimelineItem';
import TimelineSeparator from '@mui/lab/TimelineSeparator';
import TimelineConnector from '@mui/lab/TimelineConnector';
import TimelineContent from '@mui/lab/TimelineContent';
import TimelineDot from '@mui/lab/TimelineDot';
import TimelineOppositeContent from '@mui/lab/TimelineOppositeContent';
import Typography from '@mui/material/Typography';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import CancelIcon from '@mui/icons-material/Cancel';
import HelpIcon from '@mui/icons-material/Help';
import HourglassEmptyIcon from '@mui/icons-material/HourglassEmpty';
import HistoryIcon from '@mui/icons-material/History';

import type { IssueVerification } from '@/shared/types/verification';
import { formatDateTime } from '@/shared/utils/formatters';

interface VerificationHistoryProps {
  verifications: IssueVerification[];
  isLoading?: boolean;
}

/**
 * Get icon and color based on verification result
 */
function getResultDisplay(
  result: IssueVerification['result'],
  status: IssueVerification['status']
): {
  icon: React.ReactNode;
  color: 'success' | 'error' | 'warning' | 'grey';
} {
  if (status === 'pending') {
    return { icon: <HourglassEmptyIcon />, color: 'grey' };
  }
  if (status === 'expired') {
    return { icon: <HelpIcon />, color: 'warning' };
  }

  switch (result) {
    case 'confirmed':
      return { icon: <CheckCircleIcon />, color: 'success' };
    case 'not_found':
    case 'not_fixed':
      return { icon: <CancelIcon />, color: 'error' };
    case 'cannot_verify':
      return { icon: <HelpIcon />, color: 'warning' };
    default:
      return { icon: <HelpIcon />, color: 'grey' };
  }
}

/**
 * Component to display verification history for an issue
 */
export const VerificationHistory: FC<VerificationHistoryProps> = ({
  verifications,
  isLoading = false,
}) => {
  const { t } = useTranslation();

  if (isLoading) {
    return (
      <Card>
        <CardHeader
          avatar={<HistoryIcon color="action" />}
          title={t('verification.history', 'Verification History')}
        />
        <Divider />
        <CardContent>
          <Stack spacing={2}>
            {[1, 2].map((i) => (
              <Box key={i} sx={{ display: 'flex', gap: 2 }}>
                <Skeleton variant="circular" width={40} height={40} />
                <Box sx={{ flex: 1 }}>
                  <Skeleton variant="text" width="60%" />
                  <Skeleton variant="text" width="40%" />
                </Box>
              </Box>
            ))}
          </Stack>
        </CardContent>
      </Card>
    );
  }

  if (verifications.length === 0) {
    return (
      <Card>
        <CardHeader
          avatar={<HistoryIcon color="action" />}
          title={t('verification.history', 'Verification History')}
        />
        <Divider />
        <CardContent>
          <Typography
            variant="body2"
            sx={{
              color: "text.secondary",
              textAlign: "center",
              py: 2
            }}>
            {t('verification.noHistory', 'No verification requests yet')}
          </Typography>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader
        avatar={<HistoryIcon color="action" />}
        title={t('verification.history', 'Verification History')}
      />
      <Divider />
      <CardContent sx={{ py: 0 }}>
        <Timeline
          sx={{
            px: 0,
            '& .MuiTimelineItem-root:before': {
              flex: 0,
              padding: 0,
            },
          }}
        >
          {verifications.map((verification, index) => {
            const { icon, color } = getResultDisplay(verification.result, verification.status);
            const isLast = index === verifications.length - 1;

            return (
              <TimelineItem key={verification.id}>
                <TimelineOppositeContent sx={{ display: 'none' }} />
                <TimelineSeparator>
                  <TimelineDot color={color} variant="outlined">
                    {icon}
                  </TimelineDot>
                  {!isLast && <TimelineConnector />}
                </TimelineSeparator>
                <TimelineContent sx={{ py: 1.5 }}>
                  <Box
                    sx={{
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'flex-start',
                      mb: 0.5,
                    }}
                  >
                    <Typography variant="subtitle2">
                      {verification.verificationType === 'existence'
                        ? t('verification.existenceVerification', 'Existence Verification')
                        : t('verification.fixVerification', 'Fix Verification')}
                    </Typography>
                    <Chip
                      label={t(`verification.status.${verification.status}`, verification.status)}
                      size="small"
                      color={
                        verification.status === 'completed'
                          ? 'success'
                          : verification.status === 'pending'
                            ? 'default'
                            : 'warning'
                      }
                    />
                  </Box>

                  {verification.status === 'completed' && verification.result && (
                    <Typography
                      variant="body2"
                      color={
                        verification.result === 'confirmed'
                          ? 'success.main'
                          : verification.result === 'cannot_verify'
                            ? 'warning.main'
                            : 'error.main'
                      }
                    >
                      {t(`verification.results.${verification.result}`, verification.result)}
                      {verification.verifiedByName &&
                        ` - ${t('verification.by', 'by')} ${verification.verifiedByName}`}
                    </Typography>
                  )}

                  {verification.status === 'pending' && verification.assignedToName && (
                    <Typography variant="body2" sx={{
                      color: "text.secondary"
                    }}>
                      {t('verification.assignedTo', 'Assigned to')} {verification.assignedToName}
                    </Typography>
                  )}

                  {verification.reason && (
                    <Typography variant="body2" sx={{
                      color: "text.secondary"
                    }}>
                      {t('verification.reason', 'Reason')}:{' '}
                      {t(`verification.reasons.${verification.reason}`, verification.reason)}
                    </Typography>
                  )}

                  {verification.note && (
                    <Typography
                      variant="body2"
                      sx={{
                        color: "text.secondary",
                        fontStyle: 'italic',
                        mt: 0.5
                      }}>
                      "{verification.note}"
                    </Typography>
                  )}

                  <Typography
                    variant="caption"
                    sx={{
                      color: "text.disabled",
                      display: 'block',
                      mt: 0.5
                    }}>
                    {formatDateTime(verification.requestedAt)}
                    {verification.respondedAt &&
                      ` → ${formatDateTime(verification.respondedAt)}`}
                  </Typography>
                </TimelineContent>
              </TimelineItem>
            );
          })}
        </Timeline>
      </CardContent>
    </Card>
  );
};
