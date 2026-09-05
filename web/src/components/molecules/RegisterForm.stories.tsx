import type { Meta, StoryObj } from '@storybook/react-vite';

import type { Sector } from '@/features/auth/types';
import { RegisterForm } from './RegisterForm';

const sectors: Sector[] = [
  { id: 'sector-1', name: 'Ward 42 Central', center: { latitude: -26.2041, longitude: 28.0473 } },
  { id: 'sector-2', name: 'Ward 42 North', center: { latitude: -26.1, longitude: 28.05 } },
];

const meta = {
  title: 'Molecules/RegisterForm',
  component: RegisterForm,
  args: {
    sectors,
    onSubmit: () => {},
  },
} satisfies Meta<typeof RegisterForm>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {};

export const Loading: Story = { args: { isLoading: true } };

export const WithError: Story = { args: { error: 'Registration failed. Please try again.' } };

export const NoSectors: Story = { args: { sectors: [] } };
