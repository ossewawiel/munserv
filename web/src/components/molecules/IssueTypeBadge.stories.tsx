import type { Meta, StoryObj } from '@storybook/react-vite';
import Stack from '@mui/material/Stack';

import type { IssueType } from '@/features/issues/types';
import { IssueTypeBadge } from './IssueTypeBadge';

const meta = {
  title: 'Molecules/IssueTypeBadge',
  component: IssueTypeBadge,
  args: {
    type: 'pothole',
  },
} satisfies Meta<typeof IssueTypeBadge>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Small: Story = { args: { size: 'sm' } };
export const Medium: Story = { args: { size: 'md' } };
export const Large: Story = { args: { size: 'lg' } };
export const WithoutIcon: Story = { args: { showIcon: false } };

const types: IssueType[] = [
  'pothole',
  'water_leak',
  'sewage_leak',
  'traffic_light',
  'street_light',
  'illegal_dumping',
  'other',
];

export const AllTypes: Story = {
  render: () => (
    <Stack spacing={1}>
      {types.map((type) => (
        <IssueTypeBadge key={type} type={type} />
      ))}
    </Stack>
  ),
};
