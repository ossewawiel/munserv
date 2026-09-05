import type { Meta, StoryObj } from '@storybook/react-vite';
import ReportProblemIcon from '@mui/icons-material/ReportProblem';

import { StatCard } from './StatCard';

const meta = {
  title: 'Molecules/StatCard',
  component: StatCard,
  args: {
    title: 'Open issues',
    value: 42,
    icon: <ReportProblemIcon />,
  },
} satisfies Meta<typeof StatCard>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = { args: { variant: 'primary' } };

export const Colored: Story = { args: { variant: 'secondary', colored: true } };

export const WithPositiveTrend: Story = {
  args: { trend: { value: 12, isPositive: true } },
};

export const WithNegativeTrend: Story = {
  args: { trend: { value: 8, isPositive: false } },
};

export const WithSubtitle: Story = {
  args: { subtitle: 'Across all sectors' },
};
