import type { Meta, StoryObj } from '@storybook/react-vite';

import { ErrorState } from './ErrorState';

const meta = {
  title: 'Molecules/ErrorState',
  component: ErrorState,
} satisfies Meta<typeof ErrorState>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {};

export const WithDescription: Story = {
  args: {
    title: 'Could not load issues',
    description: 'The server did not respond. Check your connection and try again.',
  },
};

export const WithRetry: Story = {
  args: {
    title: 'Could not load issues',
    description: 'The server did not respond. Check your connection and try again.',
    onRetry: () => {},
  },
};
