import type { Meta, StoryObj } from '@storybook/react-vite';

import { PhotoGallery } from './PhotoGallery';

// Inline SVG data URIs so the story never depends on network access.
function placeholder(fill: string, label: string): string {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">
    <rect width="200" height="200" fill="${fill}" />
    <text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" fill="#FFFFFF" font-size="20">${label}</text>
  </svg>`;
  return `data:image/svg+xml;utf8,${encodeURIComponent(svg)}`;
}

const meta = {
  title: 'Molecules/PhotoGallery',
  component: PhotoGallery,
} satisfies Meta<typeof PhotoGallery>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Empty: Story = { args: { photos: [] } };

export const SinglePhoto: Story = {
  args: { photos: [placeholder('#0C2721', '1')] },
};

export const MultiplePhotos: Story = {
  args: {
    photos: [
      placeholder('#0C2721', '1'),
      placeholder('#A2391A', '2'),
      placeholder('#2196F3', '3'),
    ],
  },
};
