import { type FC, useState, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Grid from '@mui/material/Grid';
import Typography from '@mui/material/Typography';

import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { PageHeader } from '@/components/molecules/PageHeader';
import { ErrorState } from '@/components/molecules/ErrorState';
import { LoadingSkeleton } from '@/components/molecules/LoadingSkeleton';
import { PhotoGallery } from '@/components/molecules/PhotoGallery';
import { Button } from '@/components/atoms/Button';
import { useIssue, useUpdateIssueState } from './hooks';
import { IssueInfoCard } from './components/IssueInfoCard';
import { StateHistory } from './components/StateHistory';
import { StateChangeModal } from './components/StateChangeModal';
import type { IssueState } from './types';

export const IssueDetailPage: FC = () => {
  const { t } = useTranslation();
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [isModalOpen, setIsModalOpen] = useState(false);

  const { data: issue, isLoading, error, refetch } = useIssue(id!);
  const updateState = useUpdateIssueState();

  const handleBack = useCallback(() => {
    navigate('/issues');
  }, [navigate]);

  const handleOpenModal = useCallback(() => {
    setIsModalOpen(true);
  }, []);

  const handleCloseModal = useCallback(() => {
    setIsModalOpen(false);
  }, []);

  const handleStateChange = useCallback(
    (state: IssueState, note?: string) => {
      if (!issue) return;
      updateState.mutate(
        { id: issue.id, state, note },
        {
          onSuccess: () => {
            setIsModalOpen(false);
          },
        }
      );
    },
    [issue, updateState]
  );

  return (
    <DashboardLayout>
      <PageHeader
        title={t('issues.detail')}
        actions={
          <Box sx={{ display: 'flex', gap: 1 }}>
            <Button variant="secondary" onClick={handleBack}>
              {t('common.back')}
            </Button>
            {issue && (
              <Button onClick={handleOpenModal}>
                {t('issues.changeState')}
              </Button>
            )}
          </Box>
        }
      />

      <Box sx={{ mt: 3, display: 'flex', flexDirection: 'column', gap: 3 }}>
        {isLoading && (
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
            <LoadingSkeleton variant="rect" height={200} />
            <LoadingSkeleton variant="rect" height={300} />
            <LoadingSkeleton variant="rect" height={150} />
          </Box>
        )}

        {error && (
          <ErrorState
            title={t('common.error')}
            description={t('errors.serverError')}
            onRetry={() => refetch()}
          />
        )}

        {issue && (
          <>
            <Grid container spacing={3}>
              <Grid size={{ xs: 12, lg: 6 }}>
                <Typography variant="h6" sx={{ mb: 2, fontWeight: 600 }}>
                  {t('issues.photos')}
                </Typography>
                <PhotoGallery photos={issue.photoUrls} alt={t('issues.detail')} />
              </Grid>
              <Grid size={{ xs: 12, lg: 6 }}>
                <IssueInfoCard issue={issue} />
              </Grid>
            </Grid>
            <StateHistory history={issue.stateHistory || []} />
          </>
        )}
      </Box>

      {issue && (
        <StateChangeModal
          isOpen={isModalOpen}
          onClose={handleCloseModal}
          currentState={issue.state}
          onSubmit={handleStateChange}
          isLoading={updateState.isPending}
        />
      )}
    </DashboardLayout>
  );
};

export default IssueDetailPage;
