import { type FC } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import ErrorOutlineIcon from '@mui/icons-material/ErrorOutlined';

import { Button } from '@/components/atoms/Button';

interface ErrorStateProps {
  title?: string;
  description?: string;
  onRetry?: () => void;
}

export const ErrorState: FC<ErrorStateProps> = ({
  title,
  description,
  onRetry,
}) => {
  const { t } = useTranslation();

  return (
    <Box
      sx={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        py: 6,
        textAlign: 'center',
      }}
    >
      <ErrorOutlineIcon sx={{ fontSize: 48, mb: 2, color: 'error.main' }} />
      <Typography variant="h6" sx={{
        fontWeight: 500
      }}>
        {title || t('common.error')}
      </Typography>
      {description && (
        <Typography
          variant="body2"
          sx={{
            color: "text.secondary",
            mt: 1,
            maxWidth: 400
          }}>
          {description}
        </Typography>
      )}
      {onRetry && (
        <Box sx={{ mt: 3 }}>
          <Button variant="secondary" onClick={onRetry}>
            {t('common.retry')}
          </Button>
        </Box>
      )}
    </Box>
  );
};
