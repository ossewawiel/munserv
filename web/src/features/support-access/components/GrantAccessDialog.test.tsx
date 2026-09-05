import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent, within } from '@testing-library/react';
import { GrantAccessDialog } from './GrantAccessDialog';

describe('GrantAccessDialog', () => {
  it('should block submit when purpose is shorter than 10 characters', () => {
    const onSubmit = vi.fn();
    render(
      <GrantAccessDialog open onClose={vi.fn()} onSubmit={onSubmit} isLoading={false} />
    );

    fireEvent.change(screen.getByLabelText(/purpose/i), { target: { value: 'too short' } });
    fireEvent.click(screen.getByRole('button', { name: /grant access/i }));

    expect(onSubmit).not.toHaveBeenCalled();
    expect(screen.getByText(/at least 10 characters/i)).toBeInTheDocument();
  });

  it('should submit the selected role and purpose when the form is valid', () => {
    const onSubmit = vi.fn();
    render(
      <GrantAccessDialog open onClose={vi.fn()} onSubmit={onSubmit} isLoading={false} />
    );

    fireEvent.mouseDown(screen.getByLabelText(/role to grant/i));
    const listbox = screen.getByRole('listbox');
    fireEvent.click(within(listbox).getByText('Pod Admin'));

    fireEvent.change(screen.getByLabelText(/purpose/i), {
      target: { value: 'Investigate duplicate issue reports in sector 3' },
    });
    fireEvent.click(screen.getByRole('button', { name: /grant access/i }));

    expect(onSubmit).toHaveBeenCalledWith({
      grantedRole: 'pod_admin',
      purpose: 'Investigate duplicate issue reports in sector 3',
    });
  });

  it('should show the conflict warning when an active grant already exists', () => {
    render(
      <GrantAccessDialog
        open
        onClose={vi.fn()}
        onSubmit={vi.fn()}
        isLoading={false}
        errorCode="active_grant_exists"
      />
    );

    expect(screen.getByText(/already has an active support grant/i)).toBeInTheDocument();
  });
});
