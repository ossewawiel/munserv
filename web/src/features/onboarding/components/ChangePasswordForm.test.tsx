import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { ChangePasswordForm } from './ChangePasswordForm';

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        onboarding: {
          newPassword: 'New Password',
          confirmPassword: 'Confirm New Password',
          passwordsMustMatch: 'Passwords must match',
          changePasswordButton: 'Change Password',
          passwordRequirements: 'Password Requirements',
          requirements: {
            minLength: 'At least 8 characters',
            uppercase: 'At least one uppercase letter',
            lowercase: 'At least one lowercase letter',
            number: 'At least one number',
          },
        },
      },
    },
  },
});

const theme = createTheme();

const renderWithWrapper = (props: {
  onSubmit: (password: string) => void;
  isLoading?: boolean;
  error?: string | null;
}) => {
  return render(
    <ThemeProvider theme={theme}>
      <I18nextProvider i18n={i18n}>
        <ChangePasswordForm {...props} />
      </I18nextProvider>
    </ThemeProvider>
  );
};

// Helper to get password inputs - MUI password inputs don't have role="textbox"
function getPasswordInputs() {
  const passwordInputs = document.querySelectorAll('input[type="password"]');
  return Array.from(passwordInputs) as HTMLInputElement[];
}

describe('ChangePasswordForm', () => {
  it('should render password fields', () => {
    renderWithWrapper({ onSubmit: vi.fn() });

    // Use exact label text to avoid multiple element issues
    const passwordInputs = getPasswordInputs();
    expect(passwordInputs).toHaveLength(2);
    expect(screen.getByRole('button', { name: /change password/i })).toBeInTheDocument();
  });

  it('should show password requirements', () => {
    renderWithWrapper({ onSubmit: vi.fn() });

    expect(screen.getByText('Password Requirements')).toBeInTheDocument();
    expect(screen.getByText('At least 8 characters')).toBeInTheDocument();
    expect(screen.getByText('At least one uppercase letter')).toBeInTheDocument();
    expect(screen.getByText('At least one lowercase letter')).toBeInTheDocument();
    expect(screen.getByText('At least one number')).toBeInTheDocument();
  });

  it('should have submit button disabled when password does not meet requirements', () => {
    renderWithWrapper({ onSubmit: vi.fn() });

    const submitButton = screen.getByRole('button', { name: /change password/i });
    expect(submitButton).toBeDisabled();
  });

  it('should enable submit button when password meets all requirements and matches confirmation', async () => {
    renderWithWrapper({ onSubmit: vi.fn() });

    const [newPasswordInput, confirmPasswordInput] = getPasswordInputs();
    const submitButton = screen.getByRole('button', { name: /change password/i });

    // Enter valid password
    await fireEvent.change(newPasswordInput, { target: { value: 'Password123' } });
    await fireEvent.change(confirmPasswordInput, { target: { value: 'Password123' } });

    expect(submitButton).not.toBeDisabled();
  });

  it('should show error when passwords do not match', async () => {
    renderWithWrapper({ onSubmit: vi.fn() });

    const [newPasswordInput, confirmPasswordInput] = getPasswordInputs();

    // Enter mismatched passwords
    await fireEvent.change(newPasswordInput, { target: { value: 'Password123' } });
    await fireEvent.change(confirmPasswordInput, { target: { value: 'Password456' } });
    await fireEvent.blur(confirmPasswordInput);

    expect(screen.getByText(/passwords must match/i)).toBeInTheDocument();
  });

  it('should call onSubmit with password when form is submitted', async () => {
    const onSubmit = vi.fn();
    renderWithWrapper({ onSubmit });

    const [newPasswordInput, confirmPasswordInput] = getPasswordInputs();

    // Enter valid password
    await fireEvent.change(newPasswordInput, { target: { value: 'Password123' } });
    await fireEvent.change(confirmPasswordInput, { target: { value: 'Password123' } });

    // Submit form
    const form = newPasswordInput.closest('form');
    await fireEvent.submit(form!);

    expect(onSubmit).toHaveBeenCalledWith('Password123');
  });

  it('should display error message when error prop is provided', () => {
    renderWithWrapper({
      onSubmit: vi.fn(),
      error: 'Failed to change password',
    });

    expect(screen.getByText('Failed to change password')).toBeInTheDocument();
  });

  it('should disable inputs when loading', () => {
    renderWithWrapper({ onSubmit: vi.fn(), isLoading: true });

    const [newPasswordInput, confirmPasswordInput] = getPasswordInputs();
    expect(newPasswordInput).toBeDisabled();
    expect(confirmPasswordInput).toBeDisabled();
  });

  it('should toggle password visibility', async () => {
    renderWithWrapper({ onSubmit: vi.fn() });

    const [newPasswordInput] = getPasswordInputs();
    expect(newPasswordInput).toHaveAttribute('type', 'password');

    // Click visibility toggle
    const visibilityButtons = screen.getAllByRole('button', { name: /toggle.*password/i });
    await fireEvent.click(visibilityButtons[0]);

    expect(newPasswordInput).toHaveAttribute('type', 'text');
  });
});
