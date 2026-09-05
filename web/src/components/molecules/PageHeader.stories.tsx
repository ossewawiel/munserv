import type { Meta, StoryObj } from '@storybook/react-vite';

import { Button } from '@/components/atoms/Button';
import { PageHeader } from './PageHeader';

const meta = {
  title: 'Molecules/PageHeader',
  component: PageHeader,
  args: {
    title: 'Issues',
  },
} satisfies Meta<typeof PageHeader>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {};

export const WithSubtitle: Story = {
  args: { subtitle: 'All reported issues across your sectors' },
};

export const WithActions: Story = {
  args: {
    subtitle: 'All reported issues across your sectors',
    actions: <Button>Export</Button>,
  },
};
