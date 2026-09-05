import { type FC, useCallback } from 'react';
import Stack from '@mui/material/Stack';
import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';
import { useTranslation } from 'react-i18next';

import { IssueTypeFilterButton } from '@/components/atoms/IssueTypeFilterButton';
import type { IssueType } from '@/features/issues/types';

const ALL_ISSUE_TYPES: IssueType[] = [
  'pothole',
  'water_leak',
  'sewage_leak',
  'traffic_light',
  'street_light',
  'illegal_dumping',
  'other',
];

interface IssueTypeFilterBarProps {
  activeTypes: Set<IssueType>;
  onToggle: (type: IssueType) => void;
}

export const IssueTypeFilterBar: FC<IssueTypeFilterBarProps> = ({
  activeTypes,
  onToggle,
}) => {
  const { t } = useTranslation();

  const handleToggle = useCallback(
    (type: IssueType) => () => onToggle(type),
    [onToggle]
  );

  return (
    <Paper
      elevation={0}
      sx={{
        p: 1.5,
        border: 1,
        borderColor: 'divider',
        borderRadius: 2,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: 1,
      }}
    >
      <Typography
        variant="caption"
        sx={{
          color: "text.secondary",
          mb: 0.5,
          writingMode: 'vertical-rl',
          textOrientation: 'mixed'
        }}>
        {t('issues.map.filterByType')}
      </Typography>
      <Stack direction="column" spacing={1}>
        {ALL_ISSUE_TYPES.map((type) => (
          <IssueTypeFilterButton
            key={type}
            type={type}
            isActive={activeTypes.has(type)}
            onClick={handleToggle(type)}
          />
        ))}
      </Stack>
    </Paper>
  );
};
