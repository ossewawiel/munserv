import type { ComponentProps } from 'react';
import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { LoginForm } from './LoginForm';
import type { DemoAccount } from '@/shared/types/demoAccount';

i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        auth: {
          email: 'Email',
          password: 'Password',
          loginButton: 'Sign In',
          loggingIn: 'Signing in...',
          quickLogin: { label: 'Quick login', placeholder: 'Choose an account', option: '{{role}} · {{name}}' },
        },
        roles: { sector_admin: 'Sector Admin' },
      },
    },
  },
});

const accounts: readonly DemoAccount[] = [
  { group: 'sector_admin', name: '', email: 's@example.test', password: 'pw123' },
];

function renderForm(props: Partial<ComponentProps<typeof LoginForm>> = {}) {
  const onSubmit = vi.fn();
  render(
    <ThemeProvider theme={createTheme()}>
      <I18nextProvider i18n={i18n}>
        <LoginForm onSubmit={onSubmit} {...props} />
      </I18nextProvider>
    </ThemeProvider>
  );
  return onSubmit;
}

describe('LoginForm quick login', () => {
  it('should not render quick login without accounts', () => {
    renderForm();
    expect(screen.queryByText('Quick login')).not.toBeInTheDocument();
  });

  it('should fill the fields and submit when an account is picked', async () => {
    const onSubmit = renderForm({ quickLoginAccounts: accounts });
    await userEvent.click(screen.getByRole('combobox'));
    await userEvent.click(screen.getByRole('option', { name: 'Sector Admin' }));
    expect(onSubmit).toHaveBeenCalledWith('s@example.test', 'pw123');
    expect(screen.getByLabelText('Email')).toHaveValue('s@example.test');
  });
});
