import { type FC, useState, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Stack from '@mui/material/Stack';

import { Modal } from '@/components/atoms/Modal';
import { Select } from '@/components/atoms/Select';
import { Input } from '@/components/atoms/Input';
import { Button } from '@/components/atoms/Button';
import type { IssueState } from '../types';

interface StateChangeModalProps {
  isOpen: boolean;
  onClose: () => void;
  currentState: IssueState;
  onSubmit: (state: IssueState, note?: string) => void;
  isLoading?: boolean;
}

const STATES: IssueState[] = ['reported', 'confirmed', 'in_progress', 'fixed', 'rejected'];

export const StateChangeModal: FC<StateChangeModalProps> = ({
  isOpen,
  onClose,
  currentState,
  onSubmit,
  isLoading = false,
}) => {
  const { t } = useTranslation();
  const availableStates = STATES.filter((s) => s !== currentState);
  const [selectedState, setSelectedState] = useState<IssueState | ''>(availableStates[0] || '');
  const [note, setNote] = useState('');

  const handleStateChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      setSelectedState(e.target.value as IssueState);
    },
    []
  );

  const handleNoteChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      setNote(e.target.value);
    },
    []
  );

  const handleSubmit = useCallback(
    (e: React.FormEvent) => {
      e.preventDefault();
      if (selectedState) {
        onSubmit(selectedState, note || undefined);
      }
    },
    [selectedState, note, onSubmit]
  );

  const stateOptions = availableStates.map((s) => ({
    value: s,
    label: t(`issues.states.${s}`),
  }));

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={t('issues.changeState')}>
      <Box component="form" onSubmit={handleSubmit} sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
        <Select
          label={t('issues.state')}
          options={stateOptions}
          value={selectedState}
          onChange={handleStateChange}
        />
        <Input
          label={t('issues.note')}
          value={note}
          onChange={handleNoteChange}
          placeholder={t('issues.notePlaceholder')}
        />
        <Stack direction="row" spacing={1} justifyContent="flex-end" sx={{ pt: 2 }}>
          <Button
            type="button"
            variant="secondary"
            onClick={onClose}
            disabled={isLoading}
          >
            {t('common.cancel')}
          </Button>
          <Button
            type="submit"
            disabled={!selectedState || isLoading}
            isLoading={isLoading}
          >
            {t('common.confirm')}
          </Button>
        </Stack>
      </Box>
    </Modal>
  );
};
