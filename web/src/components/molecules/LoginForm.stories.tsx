import type { Meta, StoryObj } from '@storybook/react-vite';

import { LoginForm } from './LoginForm';

const meta = {
  title: 'Molecules/LoginForm',
  component: LoginForm,
  args: {
    onSubmit: () => {},
  },
} satisfies Meta<typeof LoginForm>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {};

export const Loading: Story = { args: { isLoading: true } };

export const WithError: Story = { args: { error: 'Invalid email or password' } };
