import type { Meta, StoryObj } from '@storybook/react-vite';

import type { IssueState } from '@/features/issues/types';
import { IssueStateBadge } from './IssueStateBadge';

const meta = {
  title: 'Molecules/IssueStateBadge',
  component: IssueStateBadge,
} satisfies Meta<typeof IssueStateBadge>;

export default meta;
type Story = StoryObj<typeof meta>;

const states: IssueState[] = ['reported', 'confirmed', 'in_progress', 'fixed', 'rejected'];

export const Reported: Story = { args: { state: states[0] } };
export const Confirmed: Story = { args: { state: states[1] } };
export const InProgress: Story = { args: { state: states[2] } };
export const Fixed: Story = { args: { state: states[3] } };
export const Rejected: Story = { args: { state: states[4] } };
