import { type FC } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import IconButton from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import CancelIcon from '@mui/icons-material/Cancel';

interface MemberActionButtonsProps {
  onApprove: () => void;
  onReject: () => void;
}

export const MemberActionButtons: FC<MemberActionButtonsProps> = ({
  onApprove,
  onReject,
}) => {
  const { t } = useTranslation();

  return (
    <Box sx={{ display: 'flex', gap: 0.5, justifyContent: 'center' }}>
      <Tooltip title={t('members.approve')}>
        <IconButton
          color="success"
          size="small"
          aria-label={t('members.approve')}
          onClick={(e) => {
            e.stopPropagation();
            onApprove();
          }}
        >
          <CheckCircleIcon />
        </IconButton>
      </Tooltip>
      <Tooltip title={t('members.reject')}>
        <IconButton
          color="error"
          size="small"
          aria-label={t('members.reject')}
          onClick={(e) => {
            e.stopPropagation();
            onReject();
          }}
        >
          <CancelIcon />
        </IconButton>
      </Tooltip>
    </Box>
  );
};
