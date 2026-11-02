import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent, within } from '@testing-library/react';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { PodAdministratorFilters } from './PodAdministratorFilters';
import { ADMIN_ROLES } from '@/shared/types/admin';

i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        podAdministrators: {
          filters: { role: 'Role', assignedTo: 'Assigned to', allAssignments: 'All assignments' },
        },
      },
    },
  },
});

const wards = [
  { id: 'ward-1', name: 'Test Ward North' },
  { id: 'ward-2', name: 'Test Ward South' },
];

function renderFilters(overrides: Partial<Parameters<typeof PodAdministratorFilters>[0]> = {}) {
  const props = {
    roles: [] as const,
    wardId: null,
    wards,
    onRolesChange: vi.fn(),
    onWardChange: vi.fn(),
    ...overrides,
  };
  render(
    <I18nextProvider i18n={i18n}>
      <PodAdministratorFilters {...props} />
    </I18nextProvider>
  );
  return props;
}

describe('PodAdministratorFilters', () => {
  it('should render a checkbox for every admin role', () => {
    renderFilters();

    expect(screen.getAllByRole('checkbox')).toHaveLength(ADMIN_ROLES.length);
  });

  it('should check the roles it is given', () => {
    renderFilters({ roles: ['ward_chief'] });

    expect(screen.getByRole('checkbox', { name: 'Ward Chief' })).toBeChecked();
    expect(screen.getByRole('checkbox', { name: 'Ward Admin' })).not.toBeChecked();
  });

  it('should add a role when an unchecked box is clicked', () => {
    const props = renderFilters({ roles: ['ward_chief'] });

    fireEvent.click(screen.getByRole('checkbox', { name: 'Ward Admin' }));

    expect(props.onRolesChange).toHaveBeenCalledWith(['ward_chief', 'ward_admin']);
  });

  it('should remove a role when a checked box is clicked', () => {
    const props = renderFilters({ roles: ['ward_chief', 'ward_admin'] });

    fireEvent.click(screen.getByRole('checkbox', { name: 'Ward Chief' }));

    expect(props.onRolesChange).toHaveBeenCalledWith(['ward_admin']);
  });

  it('should list every ward under all assignments', () => {
    renderFilters();

    fireEvent.mouseDown(screen.getByRole('combobox'));
    const listbox = screen.getByRole('listbox');

    expect(within(listbox).getAllByRole('option').map((o) => o.textContent)).toEqual([
      'All assignments',
      'Test Ward North',
      'Test Ward South',
    ]);
  });

  it('should report null when all assignments is chosen', () => {
    const props = renderFilters({ wardId: 'ward-1' });

    fireEvent.mouseDown(screen.getByRole('combobox'));
    fireEvent.click(screen.getByRole('option', { name: 'All assignments' }));

    expect(props.onWardChange).toHaveBeenCalledWith(null);
  });
});
