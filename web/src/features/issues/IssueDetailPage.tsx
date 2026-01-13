import { type FC, useState, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Paper from '@mui/material/Paper';

import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { Breadcrumbs } from '@/components/molecules/Breadcrumbs';
import { ErrorState } from '@/components/molecules/ErrorState';
import { LoadingSkeleton } from '@/components/molecules/LoadingSkeleton';
import { useIssue, useUpdateIssueState } from './hooks';
import { IssueDetailHeader } from './components/IssueDetailHeader';
import { PhotoCarousel } from './components/PhotoCarousel';
import { LocationMapPreview } from './components/LocationMapPreview';
import { IssueDetailsRow } from './components/IssueDetailsRow';
import { HorizontalTimeline } from './components/HorizontalTimeline';
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
      <Breadcrumbs
        title={t('issues.detail')}
        items={[
          { label: t('dashboard.title'), path: '/', icon: 'home' },
          { label: t('issues.title'), path: '/issues' },
          { label: t('issues.detail') },
        ]}
      />

      {/* Gap between breadcrumb and cards: 3 (24px) */}
      <Box sx={{ mt: 3, display: 'flex', flexDirection: 'column', gap: 2 }}>
        {isLoading && (
          <>
            {/* Loading skeletons for each card */}
            <LoadingSkeleton variant="rect" height={56} />
            <LoadingSkeleton variant="rect" height={212} />
            <LoadingSkeleton variant="rect" height={80} />
            <LoadingSkeleton variant="rect" height={100} />
          </>
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
            {/* Card 1: Header - Type, State, Heat, Actions */}
            <IssueDetailHeader
              type={issue.type}
              state={issue.state}
              heat={issue.heat}
              onBack={handleBack}
              onChangeState={handleOpenModal}
            />

            {/* Card 2: Media - Photos (2/3) & Map (1/3) - map aspect ratio sets height */}
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
                  gap: 2,
                }}
              >
                {/* Left: Photo Carousel - 2/3 width, same height as map */}
                {/* Map: 1/3 width, 4:3 ratio → height = width * 3/4 */}
                {/* Photos: 2/3 width, same height → aspect ratio = (2/3) / (1/3 * 3/4) = 8/3 */}
                <Box
                  sx={{
                    flex: { xs: 'none', md: '2' },
                    minWidth: 0,
                    aspectRatio: { xs: '4/3', md: '8/3' },
                  }}
                >
                  <PhotoCarousel
                    photos={issue.photoUrls}
                    alt={t('issues.detail')}
                  />
                </Box>

                {/* Right: Map - 1/3 width, 4:3 aspect ratio */}
                <Box sx={{ flex: { xs: 'none', md: '1' }, minWidth: 0 }}>
                  <LocationMapPreview
                    location={issue.location}
                    address={issue.address}
                  />
                </Box>
              </Box>
            </Paper>

            {/* Card 3: Details - Address, Report Count, Dates */}
            <IssueDetailsRow
              address={issue.address}
              reportCount={issue.reportCount}
              createdAt={issue.createdAt}
              updatedAt={issue.updatedAt}
              description={issue.description}
            />

            {/* Card 4: Timeline - State History */}
            <HorizontalTimeline history={issue.stateHistory || []} />
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
