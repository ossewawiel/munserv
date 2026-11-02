import { type FC, useId } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Checkbox from '@mui/material/Checkbox';
import FormControl from '@mui/material/FormControl';
import FormControlLabel from '@mui/material/FormControlLabel';
import FormGroup from '@mui/material/FormGroup';
import FormLabel from '@mui/material/FormLabel';
import InputLabel from '@mui/material/InputLabel';
import MenuItem from '@mui/material/MenuItem';
import Select from '@mui/material/Select';

import { ADMIN_ROLES, ADMIN_ROLE_LABELS, type AdminRole } from '@/shared/types/admin';

interface PodAdministratorFiltersProps {
  readonly roles: readonly AdminRole[];
  readonly wardId: string | null;
  readonly wards: readonly { readonly id: string; readonly name: string }[];
  readonly onRolesChange: (roles: readonly AdminRole[]) => void;
  readonly onWardChange: (wardId: string | null) => void;
}

/** Highest role first, as drawn on the approved filter-panel artboard. */
const ROLES_HIGHEST_FIRST: readonly AdminRole[] = [...ADMIN_ROLES].reverse();

/**
 * Body of the Pod Administrators filter drawer: role checkboxes and a ward select.
 */
export const PodAdministratorFilters: FC<PodAdministratorFiltersProps> = ({
  roles,
  wardId,
  wards,
  onRolesChange,
  onWardChange,
}) => {
  const { t } = useTranslation();
  const labelId = useId();

  const toggleRole = (role: AdminRole, checked: boolean): void => {
    onRolesChange(checked ? [...roles, role] : roles.filter((r) => r !== role));
  };

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
      <FormControl component="fieldset">
        <FormLabel component="legend">{t('podAdministrators.filters.role')}</FormLabel>
        <FormGroup>
          {ROLES_HIGHEST_FIRST.map((role) => (
            <FormControlLabel
              key={role}
              label={ADMIN_ROLE_LABELS[role]}
              control={
                <Checkbox
                  checked={roles.includes(role)}
                  onChange={(event) => toggleRole(role, event.target.checked)}
                />
              }
            />
          ))}
        </FormGroup>
      </FormControl>

      <FormControl fullWidth size="small">
        <InputLabel id={labelId} shrink>
          {t('podAdministrators.filters.assignedTo')}
        </InputLabel>
        <Select
          labelId={labelId}
          label={t('podAdministrators.filters.assignedTo')}
          value={wardId ?? ''}
          displayEmpty
          notched
          onChange={(event) => onWardChange(event.target.value || null)}
        >
          <MenuItem value="">{t('podAdministrators.filters.allAssignments')}</MenuItem>
          {wards.map((ward) => (
            <MenuItem key={ward.id} value={ward.id}>
              {ward.name}
            </MenuItem>
          ))}
        </Select>
      </FormControl>
    </Box>
  );
};
