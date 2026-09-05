import type { Meta, StoryObj } from '@storybook/react-vite';

import { GrantAccessDialog } from './GrantAccessDialog';

const meta = {
  title: 'Features/SupportAccess/GrantAccessDialog',
  component: GrantAccessDialog,
  args: {
    open: true,
    onClose: () => {},
    onSubmit: () => {},
    isLoading: false,
  },
} satisfies Meta<typeof GrantAccessDialog>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {};

export const Loading: Story = {
  args: { isLoading: true },
};

export const ActiveGrantConflict: Story = {
  args: { errorCode: 'active_grant_exists' },
};
