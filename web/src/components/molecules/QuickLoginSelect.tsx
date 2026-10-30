import { type FC, type ReactElement } from 'react';
import { useTranslation } from 'react-i18next';
import TextField from '@mui/material/TextField';
import MenuItem from '@mui/material/MenuItem';
import ListSubheader from '@mui/material/ListSubheader';

import { DEMO_ACCOUNT_GROUP_ORDER, type DemoAccount } from '@/shared/types/demoAccount';

interface QuickLoginSelectProps {
  readonly accounts: readonly DemoAccount[];
  readonly onPick: (account: DemoAccount) => void;
  readonly disabled?: boolean;
}

/**
 * Select clones every child with role="option" and click handlers. This wrapper
 * drops those props so the heading stays a non-selectable group label.
 */
const GroupHeading: FC<{ readonly children: string }> = ({ children }) => (
  <ListSubheader role="presentation">{children}</ListSubheader>
);

export const QuickLoginSelect: FC<QuickLoginSelectProps> = ({
  accounts,
  onPick,
  disabled = false,
}) => {
  const { t } = useTranslation();

  const items = DEMO_ACCOUNT_GROUP_ORDER.flatMap((group): ReactElement[] => {
    const inGroup = accounts.filter((account) => account.group === group);
    if (inGroup.length === 0) return [];
    const role = t(`roles.${group}`);
    return [
      <GroupHeading key={`group-${group}`}>{role}</GroupHeading>,
      ...inGroup.map((account) => (
        <MenuItem key={account.email} value={account.email}>
          {account.name ? t('auth.quickLogin.option', { role, name: account.name }) : role}
        </MenuItem>
      )),
    ];
  });

  return (
    <TextField
      select
      fullWidth
      size="small"
      label={t('auth.quickLogin.label')}
      value=""
      disabled={disabled}
      onChange={(e) => {
        const picked = accounts.find((account) => account.email === e.target.value);
        if (picked) onPick(picked);
      }}
      slotProps={{
        inputLabel: { shrink: true },
        select: {
          displayEmpty: true,
          renderValue: () => (
            <span>{t('auth.quickLogin.placeholder')}</span>
          ),
        },
      }}
      sx={{ '& .MuiSelect-select > span': { color: 'text.secondary' } }}
    >
      {items}
    </TextField>
  );
};
