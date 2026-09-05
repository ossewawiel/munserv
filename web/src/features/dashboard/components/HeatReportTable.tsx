import { type FC, useMemo, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Avatar from '@mui/material/Avatar';
import Typography from '@mui/material/Typography';
import PeopleIcon from '@mui/icons-material/People';

import { DataTable, type Column } from '@/components/organisms/DataTable';
import { IssueStateBadge } from '@/components/molecules/IssueStateBadge';
import { IssueTypeBadge } from '@/components/molecules/IssueTypeBadge';
import { HeatBadge } from '@/components/molecules/HeatIndicator';
import type { HeatReportItem } from '../types';

interface HeatReportTableProps {
  items: HeatReportItem[];
  onRowClick?: (item: HeatReportItem) => void;
}

export const HeatReportTable: FC<HeatReportTableProps> = ({
  items,
  onRowClick,
}) => {
  const { t } = useTranslation();

  const columns: Column<HeatReportItem & { rank: number }>[] = useMemo(
    () => [
      {
        key: 'rank',
        header: t('heatReport.rank'),
        width: '60px',
        align: 'center',
        render: (item) => (
          <Avatar
            sx={{
              width: 28,
              height: 28,
              bgcolor: 'primary.light',
              color: 'primary.contrastText',
              fontSize: '0.875rem',
              fontWeight: 700,
            }}
          >
            {item.rank}
          </Avatar>
        ),
      },
      {
        key: 'thumbnail',
        header: '',
        width: '64px',
        render: (item) => (
          <Box
            component="img"
            src={item.thumbnailUrl}
            alt={t(`issues.types.${item.type}`)}
            sx={{
              width: 48,
              height: 48,
              borderRadius: 1,
              objectFit: 'cover',
            }}
          />
        ),
      },
      {
        key: 'type',
        header: t('issues.type'),
        render: (item) => <IssueTypeBadge type={item.type} />,
      },
      {
        key: 'state',
        header: t('issues.state'),
        render: (item) => <IssueStateBadge state={item.state} />,
      },
      {
        key: 'heat',
        header: t('issues.heat'),
        width: '100px',
        align: 'center',
        render: (item) => <HeatBadge heat={item.heat} />,
      },
      {
        key: 'daysOpen',
        header: t('heatReport.daysOpen'),
        width: '100px',
        align: 'center',
        render: (item) => (
          <Typography variant="body2" sx={{
            color: "text.secondary"
          }}>
            {item.daysOpen}
          </Typography>
        ),
      },
      {
        key: 'reportCount',
        header: t('issues.reportCount'),
        width: '120px',
        align: 'center',
        render: (item) => (
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, color: 'text.secondary' }}>
            <PeopleIcon sx={{ fontSize: 16 }} />
            <Typography variant="body2">{item.reportCount}</Typography>
          </Box>
        ),
      },
    ],
    [t]
  );

  const rankedItems = useMemo(
    () => items.map((item, index) => ({ ...item, rank: index + 1 })),
    [items]
  );

  const handleRowClick = useCallback(
    (item: HeatReportItem & { rank: number }) => {
      if (onRowClick) {
        onRowClick(item);
      }
    },
    [onRowClick]
  );

  return (
    <DataTable
      columns={columns}
      data={rankedItems}
      keyExtractor={(item) => item.id}
      onRowClick={handleRowClick}
    />
  );
};
