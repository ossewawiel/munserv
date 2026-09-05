import type { Meta, StoryObj } from '@storybook/react-vite';
import { expect, userEvent, within } from 'storybook/test';

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

export const InvalidPurpose: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement.ownerDocument.body);
    const purposeField = canvas.getByLabelText(/purpose/i);

    await userEvent.type(purposeField, 'too short');
    await userEvent.click(canvas.getByRole('button', { name: /grant access/i }));

    await expect(canvas.getByText(/at least 10 characters/i)).toBeInTheDocument();
  },
};
