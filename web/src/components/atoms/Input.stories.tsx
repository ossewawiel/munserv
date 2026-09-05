import type { Meta, StoryObj } from '@storybook/react-vite';

import { Input } from './Input';

const meta = {
  title: 'Atoms/Input',
  component: Input,
  args: {
    label: 'Email',
    placeholder: 'admin@example.com',
  },
} satisfies Meta<typeof Input>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {};

export const WithError: Story = {
  args: { error: 'Email is required' },
};

export const Disabled: Story = {
  args: { disabled: true, value: 'admin@example.com' },
};
