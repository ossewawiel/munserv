import { type FC, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import FilterAltOffIcon from '@mui/icons-material/FilterAltOff';

import { Select } from '@/components/atoms/Select';
import { ActionButton } from '@/components/atoms/ActionButton';
import type { IssueState, IssueType } from '../types';

interface IssueFiltersProps {
  state?: IssueState;
  type?: IssueType;
  onStateChange: (state: IssueState | undefined) => void;
  onTypeChange: (type: IssueType | undefined) => void;
  onClear: () => void;
}

const STATES: IssueState[] = ['reported', 'confirmed', 'in_progress', 'fixed', 'rejected'];
const TYPES: IssueType[] = [
  'pothole',
  'water_leak',
  'sewage_leak',
  'traffic_light',
  'street_light',
  'illegal_dumping',
  'other',
];

export const IssueFilters: FC<IssueFiltersProps> = ({
  state,
  type,
  onStateChange,
  onTypeChange,
  onClear,
}) => {
  const { t } = useTranslation();

  const handleStateChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const value = e.target.value;
      onStateChange(value ? (value as IssueState) : undefined);
    },
    [onStateChange]
  );

  const handleTypeChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const value = e.target.value;
      onTypeChange(value ? (value as IssueType) : undefined);
    },
    [onTypeChange]
  );

  const stateOptions = STATES.map((s) => ({
    value: s,
    label: t(`issues.states.${s}`),
  }));

  const typeOptions = TYPES.map((tp) => ({
    value: tp,
    label: t(`issues.types.${tp}`),
  }));

  const hasFilters = !!state || !!type;

  return (
    <Box sx={{ display: 'flex', flexWrap: 'wrap', alignItems: 'flex-end', gap: 2 }}>
      <Box sx={{ width: 192 }}>
        <Select
          label={t('issues.state')}
          options={stateOptions}
          value={state || ''}
          onChange={handleStateChange}
          placeholder={t('common.all')}
        />
      </Box>
      <Box sx={{ width: 192 }}>
        <Select
          label={t('issues.type')}
          options={typeOptions}
          value={type || ''}
          onChange={handleTypeChange}
          placeholder={t('common.all')}
        />
      </Box>
      {hasFilters && (
        <ActionButton
          size="small"
          color="primary"
          icon={<FilterAltOffIcon fontSize="small" />}
          onClick={onClear}
        >
          {t('common.clear')}
        </ActionButton>
      )}
    </Box>
  );
};
