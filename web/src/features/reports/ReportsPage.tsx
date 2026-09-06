import { type FC, useCallback, useMemo } from 'react';
import { useParams, useSearchParams } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';

import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { Breadcrumbs } from '@/components/molecules/Breadcrumbs';
import { EmptyState } from '@/components/molecules/EmptyState';
import { DataTableCard, type DataTableTab } from '@/components/organisms/DataTableCard';
import type { Column } from '@/components/organisms/DataTable';
import { usePodSetup } from '@/shared/hooks/usePodSetup';
import { REPORT_TABS, type ReportScope, type ReportTab } from './types';

type ReportRow = Record<string, never>;

const REPORT_COLUMNS: readonly Column<ReportRow>[] = [];
const REPORT_DATA: readonly ReportRow[] = [];
const keyExtractor = (): string => '';

const isReportTab = (value: string | null): value is ReportTab =>
  value !== null && (REPORT_TABS as readonly string[]).includes(value);

interface ReportsPageProps {
  readonly scope: ReportScope;
}

export const ReportsPage: FC<ReportsPageProps> = ({ scope }) => {
  const { t } = useTranslation();
  const { wardId, sectorId } = useParams<{ wardId?: string; sectorId?: string }>();
  const [searchParams, setSearchParams] = useSearchParams();
  const podSetup = usePodSetup();

  const areaName = useMemo(() => {
    if (scope === 'ward' && wardId) {
      return podSetup.status?.wards.find((ward) => ward.id === wardId)?.name;
    }
    if (scope === 'sector' && sectorId) {
      return podSetup.status?.sectors.find((sector) => sector.id === sectorId)?.name;
    }
    return undefined;
  }, [scope, wardId, sectorId, podSetup.status]);

  const title = areaName ?? t(`reports.scopes.${scope}`);

  const rawTab = searchParams.get('tab');
  const activeTab: ReportTab = isReportTab(rawTab) ? rawTab : 'summary';

  const handleTabChange = useCallback(
    (value: ReportTab) => {
      setSearchParams((prev) => {
        prev.set('tab', value);
        return prev;
      });
    },
    [setSearchParams]
  );

  const tabs = useMemo<readonly DataTableTab<ReportTab>[]>(
    () =>
      REPORT_TABS.map((tab) => ({
        value: tab,
        label: t(`reports.tabs.${tab}`),
      })),
    [t]
  );

  return (
    <DashboardLayout>
      <Breadcrumbs
        title={title}
        items={[
          { label: t('dashboard.title'), path: '/', icon: 'home' },
          { label: t('reports.title'), path: '/reports' },
          { label: title },
        ]}
      />
      <Box sx={{ mt: 3 }}>
        <DataTableCard
          columns={REPORT_COLUMNS}
          data={REPORT_DATA}
          keyExtractor={keyExtractor}
          totalItems={0}
          currentPage={1}
          pageSize={10}
          hidePagination
          hideToolbarWhenEmpty
          tabs={{
            tabs,
            value: activeTab,
            onChange: handleTabChange,
            ariaLabel: t('reports.tabsLabel'),
          }}
          emptyMessage={
            <EmptyState
              title={t('reports.empty.title')}
              description={t('reports.empty.description')}
            />
          }
        />
      </Box>
    </DashboardLayout>
  );
};
