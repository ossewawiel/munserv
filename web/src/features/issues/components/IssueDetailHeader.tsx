import { type FC } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Paper from '@mui/material/Paper';
import Stack from '@mui/material/Stack';

import { Button } from '@/components/atoms/Button';
import { IssueStateBadge } from '@/components/molecules/IssueStateBadge';
import { IssueTypeBadge } from '@/components/molecules/IssueTypeBadge';
import { HeatIndicator } from '@/components/molecules/HeatIndicator';
import type { IssueType, IssueState } from '../types';

interface IssueDetailHeaderProps {
  type: IssueType;
  state: IssueState;
  heat: number;
  onBack: () => void;
  onChangeState: () => void;
}

export const IssueDetailHeader: FC<IssueDetailHeaderProps> = ({
  type,
  state,
  heat,
  onBack,
  onChangeState,
}) => {
  const { t } = useTranslation();

  return (
    <Paper
      elevation={0}
      sx={{
        p: 2,
        border: 1,
        borderColor: 'divider',
        borderRadius: 2,
      }}
    >
      <Box
        sx={{
          display: 'flex',
          flexDirection: { xs: 'column', md: 'row' },
          alignItems: { xs: 'stretch', md: 'center' },
          gap: 2,
        }}
      >
        {/* Left: Type and State badges */}
        <Stack direction="row" spacing={2} sx={{ flexShrink: 0, alignItems: 'center' }}>
          <IssueTypeBadge type={type} size="lg" />
          <IssueStateBadge state={state} />
        </Stack>

        {/* Center: Heat bar */}
        <Box sx={{ flexGrow: 1, minWidth: { md: 200 } }}>
          <HeatIndicator heat={heat} size="md" />
        </Box>

        {/* Right: Action buttons */}
        <Stack direction="row" spacing={1} sx={{ flexShrink: 0 }}>
          <Button variant="secondary" onClick={onBack}>
            {t('common.back')}
          </Button>
          <Button onClick={onChangeState}>
            {t('issues.changeState')}
          </Button>
        </Stack>
      </Box>
    </Paper>
  );
};
