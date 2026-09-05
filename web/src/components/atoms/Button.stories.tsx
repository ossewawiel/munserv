import type { Meta, StoryObj } from '@storybook/react-vite';
import SaveIcon from '@mui/icons-material/Save';

import { Button } from './Button';

const meta = {
  title: 'Atoms/Button',
  component: Button,
  args: {
    children: 'Save issue',
  },
} satisfies Meta<typeof Button>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Primary: Story = {
  args: { variant: 'primary' },
};

export const Secondary: Story = {
  args: { variant: 'secondary' },
};

export const Danger: Story = {
  args: { variant: 'danger', children: 'Delete issue' },
};

export const Ghost: Story = {
  args: { variant: 'ghost' },
};

export const Loading: Story = {
  args: { variant: 'primary', isLoading: true },
};

export const Disabled: Story = {
  args: { variant: 'primary', disabled: true },
};

export const WithIcon: Story = {
  args: { variant: 'primary', startIcon: <SaveIcon /> },
};
