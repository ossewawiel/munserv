import { type FC, useState, useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';

import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { Breadcrumbs } from '@/components/molecules/Breadcrumbs';
import { ErrorState } from '@/components/molecules/ErrorState';
import { Spinner } from '@/components/atoms/Spinner';
import { IssueTypeFilterBar } from '@/components/molecules/IssueTypeFilterBar';
import { IssueMapCard } from './components/IssueMapCard';
import { useIssuesForMap } from './hooks';
import type { IssueType } from './types';

const ALL_ISSUE_TYPES: IssueType[] = [
  'pothole',
  'water_leak',
  'sewage_leak',
  'traffic_light',
  'street_light',
  'illegal_dumping',
  'other',
];

export const IssueMapPage: FC = () => {
  const { t } = useTranslation();
  const { data: issues, isLoading, error, refetch } = useIssuesForMap();

  const [activeTypes, setActiveTypes] = useState<Set<IssueType>>(
    () => new Set(ALL_ISSUE_TYPES)
  );

  const handleToggle = useCallback((type: IssueType) => {
    setActiveTypes((prev) => {
      const next = new Set(prev);
      if (next.has(type)) {
        next.delete(type);
      } else {
        next.add(type);
      }
      return next;
    });
  }, []);

  const filteredIssues = useMemo(
    () => issues?.filter((issue) => activeTypes.has(issue.type)) ?? [],
    [issues, activeTypes]
  );

  return (
    <DashboardLayout>
      <Breadcrumbs
        title={t('issues.map.title')}
        items={[
          { label: t('dashboard.title'), path: '/', icon: 'home' },
          { label: t('issues.title'), path: '/issues' },
          { label: t('issues.map.title') },
        ]}
      />

      <Box sx={{ mt: 3, display: 'flex', gap: 2, height: 'calc(100vh - 220px)' }}>
        {isLoading && (
          <Box sx={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Spinner />
          </Box>
        )}

        {error && (
          <ErrorState
            title={t('common.error')}
            description={t('errors.serverError')}
            onRetry={() => refetch()}
          />
        )}

        {!isLoading && !error && (
          <>
            <IssueMapCard issues={filteredIssues} />
            <IssueTypeFilterBar activeTypes={activeTypes} onToggle={handleToggle} />
          </>
        )}
      </Box>
    </DashboardLayout>
  );
};

export default IssueMapPage;
