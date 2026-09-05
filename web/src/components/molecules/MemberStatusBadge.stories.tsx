import type { Meta, StoryObj } from '@storybook/react-vite';

import { MemberStatusBadge } from './MemberStatusBadge';

const meta = {
  title: 'Molecules/MemberStatusBadge',
  component: MemberStatusBadge,
} satisfies Meta<typeof MemberStatusBadge>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Active: Story = { args: { status: 'active' } };
export const PendingApproval: Story = { args: { status: 'pending_approval' } };
export const Suspended: Story = { args: { status: 'suspended' } };
