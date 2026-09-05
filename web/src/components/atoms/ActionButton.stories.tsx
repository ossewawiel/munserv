import type { Meta, StoryObj } from '@storybook/react-vite';
import AddIcon from '@mui/icons-material/Add';
import PrintIcon from '@mui/icons-material/Print';

import { ActionButton } from './ActionButton';

const meta = {
  title: 'Atoms/ActionButton',
  component: ActionButton,
  args: {
    children: 'Add',
    icon: <AddIcon />,
  },
} satisfies Meta<typeof ActionButton>;

export default meta;
type Story = StoryObj<typeof meta>;

export const PrimaryFilled: Story = {
  args: { color: 'primary', variant: 'filled' },
};

export const SecondaryFilled: Story = {
  args: { color: 'secondary', variant: 'filled', children: 'Remove' },
};

export const PrimaryOutlined: Story = {
  args: { color: 'primary', variant: 'outlined', icon: <PrintIcon />, children: 'Print' },
};

export const SecondaryOutlined: Story = {
  args: { color: 'secondary', variant: 'outlined', children: 'Cancel' },
};
