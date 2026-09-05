import type { Meta, StoryObj } from '@storybook/react-vite';

import { Button } from '@/components/atoms/Button';
import { EmptyState } from './EmptyState';

const meta = {
  title: 'Molecules/EmptyState',
  component: EmptyState,
} satisfies Meta<typeof EmptyState>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {};

export const WithDescription: Story = {
  args: {
    title: 'No issues yet',
    description: 'Issues reported by members will appear here.',
  },
};

export const WithAction: Story = {
  args: {
    title: 'No issues yet',
    description: 'Issues reported by members will appear here.',
    action: <Button>Refresh</Button>,
  },
};
