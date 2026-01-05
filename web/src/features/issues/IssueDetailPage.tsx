import { type FC, useState, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

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
          <div className="flex gap-2">
            <Button variant="secondary" onClick={handleBack}>
              {t('common.back')}
            </Button>
            {issue && (
              <Button onClick={handleOpenModal}>
                {t('issues.changeState')}
              </Button>
            )}
          </div>
        }
      />

      <div className="mt-6 space-y-6">
        {isLoading && (
          <div className="space-y-6">
            <LoadingSkeleton variant="rect" height={200} />
            <LoadingSkeleton variant="rect" height={300} />
            <LoadingSkeleton variant="rect" height={150} />
          </div>
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
            <div className="grid gap-6 lg:grid-cols-2">
              <div>
                <h3 className="mb-4 text-lg font-semibold text-text">
                  {t('issues.photos')}
                </h3>
                <PhotoGallery photos={issue.photoUrls} alt={t('issues.detail')} />
              </div>
              <IssueInfoCard issue={issue} />
            </div>
            <StateHistory history={issue.stateHistory || []} />
          </>
        )}
      </div>

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
