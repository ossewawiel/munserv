import { describe, it, expect, vi } from 'vitest';
import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { QuickLoginSelect } from './QuickLoginSelect';
import type { DemoAccount } from '@/shared/types/demoAccount';

i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        auth: {
          quickLogin: {
            label: 'Quick login',
            placeholder: 'Choose an account',
            option: '{{role}} · {{name}}',
          },
        },
        roles: {
          sector_admin: 'Sector Admin',
          sector_chief: 'Sector Chief',
          ward_admin: 'Ward Admin',
          ward_chief: 'Ward Chief',
          pod_admin: 'Pod Admin',
          pod_chief: 'Pod Chief',
        },
      },
    },
  },
});

const accounts: readonly DemoAccount[] = [
  { group: 'sector_admin', name: '', email: 's@example.test', password: 'pw' },
  { group: 'pod_chief', name: 'Thandi', email: 'p@example.test', password: 'pw' },
];

async function open(onPick = vi.fn()) {
  render(
    <ThemeProvider theme={createTheme()}>
      <I18nextProvider i18n={i18n}>
        <QuickLoginSelect accounts={accounts} onPick={onPick} />
      </I18nextProvider>
    </ThemeProvider>
  );
  await userEvent.click(screen.getByRole('combobox'));
  return onPick;
}

describe('QuickLoginSelect', () => {
  it('should list the role headings highest first', async () => {
    await open();
    const listbox = screen.getByRole('listbox');
    const headings = within(listbox)
      .getAllByRole('presentation')
      .map((el) => el.textContent);
    expect(headings).toEqual(['Pod Chief', 'Sector Admin']);
  });

  it('should show the name after the role when there is one', async () => {
    await open();
    expect(screen.getByRole('option', { name: 'Pod Chief · Thandi' })).toBeInTheDocument();
  });

  it('should show the role alone when there is no name', async () => {
    await open();
    expect(screen.getByRole('option', { name: 'Sector Admin' })).toBeInTheDocument();
  });

  it('should call onPick with the chosen account', async () => {
    const onPick = await open();
    await userEvent.click(screen.getByRole('option', { name: 'Pod Chief · Thandi' }));
    expect(onPick).toHaveBeenCalledWith(accounts[1]);
  });
});
