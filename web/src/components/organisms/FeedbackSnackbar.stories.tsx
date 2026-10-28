import type { Meta, StoryObj } from '@storybook/react-vite';

import { FeedbackSnackbar } from './FeedbackSnackbar';

const meta = {
  title: 'Organisms/FeedbackSnackbar',
  component: FeedbackSnackbar,
  args: {
    onClose: () => {},
  },
} satisfies Meta<typeof FeedbackSnackbar>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Success: Story = {
  args: {
    feedback: { message: 'Saved. The header now reads “Munserv Pod Ward 42”.', severity: 'success' },
  },
};

export const Error: Story = {
  args: {
    feedback: { message: 'The background refresh failed. Try again shortly.', severity: 'error' },
  },
};
