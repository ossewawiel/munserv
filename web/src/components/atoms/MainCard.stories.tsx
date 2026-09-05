import type { Meta, StoryObj } from '@storybook/react-vite';
import Typography from '@mui/material/Typography';
import IconButton from '@mui/material/IconButton';
import MoreVertIcon from '@mui/icons-material/MoreVert';

import { MainCard } from './MainCard';

const meta = {
  title: 'Atoms/MainCard',
  component: MainCard,
  args: {
    children: <Typography variant="body2">Card content goes here.</Typography>,
  },
} satisfies Meta<typeof MainCard>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  args: { title: 'Recent issues' },
};

export const WithSecondaryAction: Story = {
  args: {
    title: 'Recent issues',
    secondary: (
      <IconButton size="small" aria-label="more">
        <MoreVertIcon fontSize="small" />
      </IconButton>
    ),
  },
};

export const NoTitle: Story = {
  args: { title: undefined },
};

export const NoDivider: Story = {
  args: { title: 'Recent issues', divider: false },
};
