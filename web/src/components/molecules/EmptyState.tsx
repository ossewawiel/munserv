import { type FC, type ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import InboxIcon from '@mui/icons-material/Inbox';

interface EmptyStateProps {
  title?: string;
  description?: string;
  icon?: ReactNode;
  action?: ReactNode;
}

export const EmptyState: FC<EmptyStateProps> = ({
  title,
  description,
  icon,
  action,
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
      <Box sx={{ mb: 2, color: 'text.secondary' }}>
        {icon || <InboxIcon sx={{ fontSize: 48 }} />}
      </Box>
      <Typography variant="h6" sx={{
        fontWeight: 500
      }}>
        {title || t('common.noResults')}
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
      {action && <Box sx={{ mt: 3 }}>{action}</Box>}
    </Box>
  );
};
