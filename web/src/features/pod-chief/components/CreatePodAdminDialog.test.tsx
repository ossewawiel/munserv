import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { AxiosError, AxiosHeaders } from 'axios';
import { CreatePodAdminDialog } from './CreatePodAdminDialog';

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string) => {
      const translations: Record<string, string> = {
        'podAdministrators.addNew': 'Add Administrator',
        'podAdministrators.form.email': 'Email Address',
        'podAdministrators.form.displayName': 'Display Name',
        'podAdministrators.form.role': 'Role',
        'podAdministrators.form.emailRequired': 'Email is required',
        'podAdministrators.form.emailInvalid': 'Invalid email format',
        'podAdministrators.form.displayNameRequired': 'Display name is required',
        'podAdministrators.errors.emailExists':
          'An administrator with this email already exists',
        'podAdministrators.errors.createFailed': 'Failed to create administrator',
        'common.cancel': 'Cancel',
        'common.loading': 'Loading...',
      };
      return translations[key] ?? key;
    },
  }),
}));

function createConflictError(): AxiosError {
  return new AxiosError(
    'Request failed with status code 409',
    'ERR_BAD_REQUEST',
    undefined,
    undefined,
    {
      status: 409,
      statusText: 'Conflict',
      headers: new AxiosHeaders(),
      config: { headers: new AxiosHeaders() },
      data: { error: { code: 'email_exists', message: 'Email admin@example.com is already registered' } },
    }
  );
}

function createValidationError(message: string): AxiosError {
  return new AxiosError(
    'Request failed with status code 400',
    'ERR_BAD_REQUEST',
    undefined,
    undefined,
    {
      status: 400,
      statusText: 'Bad Request',
      headers: new AxiosHeaders(),
      config: { headers: new AxiosHeaders() },
      data: { error: { code: 'validation_error', message } },
    }
  );
}

function fillRequiredFields(email: string) {
  fireEvent.change(screen.getByLabelText(/email address/i), { target: { value: email } });
  fireEvent.change(screen.getByLabelText(/display name/i), { target: { value: 'New Admin' } });
}

describe('CreatePodAdminDialog', () => {
  it('should show the duplicate email error and keep the dialog open', () => {
    const onSubmit = vi.fn();
    render(
      <CreatePodAdminDialog
        open
        onClose={vi.fn()}
        onSubmit={onSubmit}
        isLoading={false}
        error={createConflictError()}
      />
    );

    expect(
      screen.getByText(/an administrator with this email already exists/i)
    ).toBeInTheDocument();
    expect(screen.getByLabelText(/email address/i)).toBeInTheDocument();
  });

  it('should show a form-level alert for a non-conflict 4xx error', () => {
    render(
      <CreatePodAdminDialog
        open
        onClose={vi.fn()}
        onSubmit={vi.fn()}
        isLoading={false}
        error={createValidationError('Display name is required')}
      />
    );

    expect(screen.getByText('Display name is required')).toBeInTheDocument();
    expect(
      screen.queryByText(/an administrator with this email already exists/i)
    ).not.toBeInTheDocument();
  });

  it('should allow resubmitting after correcting the email', () => {
    const onSubmit = vi.fn();
    render(
      <CreatePodAdminDialog
        open
        onClose={vi.fn()}
        onSubmit={onSubmit}
        isLoading={false}
        error={createConflictError()}
      />
    );

    expect(
      screen.getByText(/an administrator with this email already exists/i)
    ).toBeInTheDocument();

    fillRequiredFields('new-admin@example.com');

    expect(
      screen.queryByText(/an administrator with this email already exists/i)
    ).not.toBeInTheDocument();

    fireEvent.click(screen.getByRole('button', { name: /add administrator/i }));

    expect(onSubmit).toHaveBeenCalledWith(
      expect.objectContaining({ email: 'new-admin@example.com', displayName: 'New Admin' })
    );
  });
});
