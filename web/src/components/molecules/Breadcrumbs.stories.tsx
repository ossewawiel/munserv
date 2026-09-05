import type { Meta, StoryObj } from '@storybook/react-vite';

import { Breadcrumbs } from './Breadcrumbs';

const meta = {
  title: 'Molecules/Breadcrumbs',
  component: Breadcrumbs,
  args: {
    title: 'Members',
  },
} satisfies Meta<typeof Breadcrumbs>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  args: {
    items: [
      { label: 'Dashboard', path: '/', icon: 'home' },
      { label: 'Members' },
    ],
  },
};

export const WithSubtitle: Story = {
  args: {
    subtitle: 'Manage community member accounts',
    items: [
      { label: 'Dashboard', path: '/', icon: 'home' },
      { label: 'Members', path: '/members' },
      { label: 'Jane Doe' },
    ],
  },
};
