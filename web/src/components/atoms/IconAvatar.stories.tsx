import type { Meta, StoryObj } from '@storybook/react-vite';
import BuildIcon from '@mui/icons-material/Build';
import Stack from '@mui/material/Stack';

import { IconAvatar } from './IconAvatar';

const meta = {
  title: 'Atoms/IconAvatar',
  component: IconAvatar,
  args: {
    children: <BuildIcon />,
  },
} satisfies Meta<typeof IconAvatar>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Small: Story = { args: { size: 'small', variant: 'primary' } };
export const Medium: Story = { args: { size: 'medium', variant: 'primary' } };
export const Large: Story = { args: { size: 'large', variant: 'primary' } };

export const AllVariants: Story = {
  render: () => (
    <Stack direction="row" spacing={2}>
      <IconAvatar variant="primary"><BuildIcon /></IconAvatar>
      <IconAvatar variant="secondary"><BuildIcon /></IconAvatar>
      <IconAvatar variant="success"><BuildIcon /></IconAvatar>
      <IconAvatar variant="warning"><BuildIcon /></IconAvatar>
      <IconAvatar variant="error"><BuildIcon /></IconAvatar>
      <IconAvatar variant="info"><BuildIcon /></IconAvatar>
    </Stack>
  ),
};
