import { type FC } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';

import { IssueStateBadge } from '@/components/molecules/IssueStateBadge';
import { IssueTypeBadge } from '@/components/molecules/IssueTypeBadge';
import { HeatIndicator } from '@/components/molecules/HeatIndicator';
import type { Issue } from '../types';

interface IssueInfoCardProps {
  issue: Issue;
}

export const IssueInfoCard: FC<IssueInfoCardProps> = ({ issue }) => {
  const { t } = useTranslation();

  const infoItems = [
    {
      label: t('issues.type'),
      value: <IssueTypeBadge type={issue.type} />,
    },
    {
      label: t('issues.state'),
      value: <IssueStateBadge state={issue.state} />,
    },
    {
      label: t('issues.heat'),
      value: <HeatIndicator heat={issue.heat} size="md" />,
    },
    {
      label: t('issues.reportCount'),
      value: issue.reportCount,
    },
    {
      label: t('issues.location'),
      value: issue.address || `${issue.location.latitude.toFixed(4)}, ${issue.location.longitude.toFixed(4)}`,
    },
    {
      label: t('issues.createdAt'),
      value: new Date(issue.createdAt).toLocaleDateString(undefined, {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
      }),
    },
    {
      label: t('issues.updatedAt'),
      value: new Date(issue.updatedAt).toLocaleDateString(undefined, {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
      }),
    },
  ];

  return (
    <Box
      sx={{
        borderRadius: 2,
        border: 1,
        borderColor: 'divider',
        bgcolor: 'background.paper',
        p: 3,
      }}
    >
      <Box component="dl" sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
        {infoItems.map((item) => (
          <Box
            key={item.label}
            sx={{
              display: 'flex',
              flexDirection: { xs: 'column', sm: 'row' },
              gap: { xs: 0.5, sm: 2 },
            }}
          >
            <Typography
              component="dt"
              variant="body2"
              sx={{
                width: { sm: 128 },
                flexShrink: 0,
                fontWeight: 500,
                color: 'text.secondary',
              }}
            >
              {item.label}
            </Typography>
            <Typography component="dd" variant="body2" sx={{ color: 'text.primary' }}>
              {item.value}
            </Typography>
          </Box>
        ))}
        {issue.description && (
          <Box
            sx={{
              display: 'flex',
              flexDirection: { xs: 'column', sm: 'row' },
              gap: { xs: 0.5, sm: 2 },
            }}
          >
            <Typography
              component="dt"
              variant="body2"
              sx={{
                width: { sm: 128 },
                flexShrink: 0,
                fontWeight: 500,
                color: 'text.secondary',
              }}
            >
              {t('issues.description')}
            </Typography>
            <Typography component="dd" variant="body2" sx={{ color: 'text.primary' }}>
              {issue.description}
            </Typography>
          </Box>
        )}
      </Box>
    </Box>
  );
};
