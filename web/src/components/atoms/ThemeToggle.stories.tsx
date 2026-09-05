import type { Meta, StoryObj } from '@storybook/react-vite';

import { ThemeToggle } from './ThemeToggle';

const meta = {
  title: 'Atoms/ThemeToggle',
  component: ThemeToggle,
} satisfies Meta<typeof ThemeToggle>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {};

export const Small: Story = { args: { size: 'small' } };

export const Large: Story = { args: { size: 'large' } };
