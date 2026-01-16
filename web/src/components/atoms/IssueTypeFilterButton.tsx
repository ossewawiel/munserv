import { type FC } from 'react';
import IconButton from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';
import SvgIcon from '@mui/material/SvgIcon';
import { useTranslation } from 'react-i18next';
import { alpha } from '@mui/material/styles';

import type { IssueType } from '@/features/issues/types';
import { issueTypeColors } from '@/theme/colors';

// SVG paths for issue type icons (same as IssueTypeBadge)
const typeIcons: Record<IssueType, string> = {
  pothole: 'M3 15a4 4 0 004 4h9a5 5 0 10-.1-9.999 5.002 5.002 0 10-9.78 2.096A4.001 4.001 0 003 15z',
  water_leak: 'M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707',
  sewage_leak: 'M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z',
  traffic_light: 'M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h10a2 2 0 012 2v14a2 2 0 01-2 2z',
  street_light: 'M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z',
  illegal_dumping: 'M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16',
  other: 'M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z',
};

interface IssueTypeFilterButtonProps {
  type: IssueType;
  isActive: boolean;
  onClick: () => void;
}

export const IssueTypeFilterButton: FC<IssueTypeFilterButtonProps> = ({
  type,
  isActive,
  onClick,
}) => {
  const { t } = useTranslation();
  const color = issueTypeColors[type];

  return (
    <Tooltip title={t(`issues.types.${type}`)} placement="left">
      <IconButton
        onClick={onClick}
        sx={{
          width: 40,
          height: 40,
          borderRadius: '50%',
          transition: 'all 0.2s ease-in-out',
          ...(isActive
            ? {
                bgcolor: color,
                color: 'white',
                '&:hover': {
                  bgcolor: color,
                  opacity: 0.9,
                },
              }
            : {
                bgcolor: alpha(color, 0.15),
                color: color,
                '&:hover': {
                  bgcolor: alpha(color, 0.25),
                },
              }),
        }}
      >
        <SvgIcon viewBox="0 0 24 24" sx={{ fontSize: 20 }}>
          <path
            fill="none"
            stroke="currentColor"
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d={typeIcons[type]}
          />
        </SvgIcon>
      </IconButton>
    </Tooltip>
  );
};
