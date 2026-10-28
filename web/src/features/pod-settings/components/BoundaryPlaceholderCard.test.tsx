import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';

import { BoundaryPlaceholderCard } from './BoundaryPlaceholderCard';

describe('BoundaryPlaceholderCard', () => {
  it('should render the coming soon chip', () => {
    render(
      <BoundaryPlaceholderCard title="Pod boundaries" description="Draw the outline." />
    );

    expect(screen.getByText('Coming soon')).toBeInTheDocument();
  });

  it('should render the configure button in a disabled state', () => {
    render(
      <BoundaryPlaceholderCard title="Pod boundaries" description="Draw the outline." />
    );

    const button = screen.getByRole('button', { name: /configure boundaries/i });
    expect(button).toBeDisabled();
  });
});
