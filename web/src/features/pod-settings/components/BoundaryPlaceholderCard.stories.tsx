import type { Meta, StoryObj } from '@storybook/react-vite';
import { userEvent, within } from 'storybook/test';

import { BoundaryPlaceholderCard } from './BoundaryPlaceholderCard';

const meta = {
  title: 'Features/PodSettings/BoundaryPlaceholderCard',
  component: BoundaryPlaceholderCard,
} satisfies Meta<typeof BoundaryPlaceholderCard>;

export default meta;
type Story = StoryObj<typeof meta>;

// Matches the "Ward boundaries" card on Main.dc.html: the pod has wards, so
// PodSettingsPage picks the ward wording from usePodSetup.
export const Default: Story = {
  args: {
    title: 'Ward boundaries',
    description:
      "Draw each ward's outline so a ward chief sees exactly the ground they are responsible for.",
  },
};

// Matches BoundariesSector.dc.html: a pod without wards, sector wording, and
// the tooltip drawn open on the disabled Configure button.
export const SectorWording: Story = {
  args: {
    title: 'Sector boundaries',
    description:
      "Draw each sector's outline so an issue reaches the right sector from the GPS point it was reported at.",
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement.ownerDocument.body);
    const configureButton = canvas.getByRole('button', { name: /configure boundaries/i });
    // The button is disabled and fires no pointer events; the Tooltip
    // listens on the wrapping span instead (see BoundaryPlaceholderCard).
    const tooltipAnchor = configureButton.parentElement;
    if (!tooltipAnchor) {
      throw new Error('Configure button is missing its tooltip-anchoring span.');
    }

    await userEvent.hover(tooltipAnchor);
    await canvas.findByText(/boundary editing is not available yet/i);
  },
};
