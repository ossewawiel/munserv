import type { Meta, StoryObj } from '@storybook/react-vite';
import Typography from '@mui/material/Typography';

import { ConfirmDialog } from './ConfirmDialog';

const meta = {
  title: 'Molecules/ConfirmDialog',
  component: ConfirmDialog,
  args: {
    open: true,
    title: 'Remove member',
    onClose: () => {},
    onConfirm: () => {},
    children: (
      <Typography variant="body2">
        This will revoke the member&apos;s access. This action cannot be undone.
      </Typography>
    ),
  },
} satisfies Meta<typeof ConfirmDialog>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {};

export const Warning: Story = { args: { variant: 'warning' } };

export const Loading: Story = { args: { isLoading: true } };
