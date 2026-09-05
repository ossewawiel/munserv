import { type FC } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';
import Grid from '@mui/material/Grid';
import Divider from '@mui/material/Divider';

interface IssueDetailsRowProps {
  address: string | null;
  reportCount: number;
  createdAt: string;
  updatedAt: string;
  description?: string | null;
}

interface DetailItemProps {
  label: string;
  value: React.ReactNode;
}

const DetailItem: FC<DetailItemProps> = ({ label, value }) => (
  <Box>
    <Typography
      variant="caption"
      sx={{
        color: "text.secondary",
        display: 'block',
        mb: 0.5,
        fontWeight: 500
      }}>
      {label}
    </Typography>
    <Typography variant="body2" sx={{
      color: "text.primary"
    }}>
      {value}
    </Typography>
  </Box>
);

export const IssueDetailsRow: FC<IssueDetailsRowProps> = ({
  address,
  reportCount,
  createdAt,
  updatedAt,
  description,
}) => {
  const { t } = useTranslation();

  const formatDate = (dateStr: string) =>
    new Date(dateStr).toLocaleDateString(undefined, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });

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
      <Grid container spacing={3}>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <DetailItem
            label={t('issues.location')}
            value={address || t('common.notAvailable')}
          />
        </Grid>

        <Grid size={{ xs: 6, sm: 6, md: 2 }}>
          <DetailItem
            label={t('issues.reportCount')}
            value={reportCount}
          />
        </Grid>

        <Grid size={{ xs: 6, sm: 6, md: 3.5 }}>
          <DetailItem
            label={t('issues.createdAt')}
            value={formatDate(createdAt)}
          />
        </Grid>

        <Grid size={{ xs: 12, sm: 6, md: 3.5 }}>
          <DetailItem
            label={t('issues.updatedAt')}
            value={formatDate(updatedAt)}
          />
        </Grid>
      </Grid>

      {description && (
        <>
          <Divider sx={{ my: 2 }} />
          <Box>
            <Typography
              variant="caption"
              sx={{
                color: "text.secondary",
                display: 'block',
                mb: 0.5,
                fontWeight: 500
              }}>
              {t('issues.description')}
            </Typography>
            <Typography variant="body2" sx={{
              color: "text.primary"
            }}>
              {description}
            </Typography>
          </Box>
        </>
      )}
    </Paper>
  );
};
