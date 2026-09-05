import type { Meta, StoryObj } from '@storybook/react-vite';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import CancelIcon from '@mui/icons-material/Cancel';

import { ActionIconButton } from './ActionIconButton';

const meta = {
  title: 'Atoms/ActionIconButton',
  component: ActionIconButton,
  args: {
    'aria-label': 'Approve',
    children: <CheckCircleIcon />,
  },
} satisfies Meta<typeof ActionIconButton>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Primary: Story = {
  args: { color: 'primary', tooltip: 'Approve' },
};

export const Secondary: Story = {
  args: {
    color: 'secondary',
    tooltip: 'Reject',
    'aria-label': 'Reject',
    children: <CancelIcon />,
  },
};

export const WithoutTooltip: Story = {
  args: { color: 'primary', tooltip: undefined },
};
