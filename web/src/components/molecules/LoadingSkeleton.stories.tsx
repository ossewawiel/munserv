import type { Meta, StoryObj } from '@storybook/react-vite';

import { LoadingSkeleton, TableSkeleton, CardSkeleton } from './LoadingSkeleton';

const meta = {
  title: 'Molecules/LoadingSkeleton',
  component: LoadingSkeleton,
} satisfies Meta<typeof LoadingSkeleton>;

export default meta;
type Story = StoryObj<typeof meta>;

export const SingleRect: Story = { args: { variant: 'rect', width: 240, height: 40 } };
export const SingleText: Story = { args: { variant: 'text', width: 240 } };
export const SingleCircle: Story = { args: { variant: 'circle', width: 48, height: 48 } };
export const MultipleLines: Story = { args: { variant: 'text', width: 240, count: 4 } };

export const Table: Story = {
  render: () => <TableSkeleton rows={4} columns={4} />,
};

export const Cards: Story = {
  render: () => <CardSkeleton count={4} />,
};
