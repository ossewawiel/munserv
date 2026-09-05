import type { Meta, StoryObj } from '@storybook/react-vite';

import { Select } from './Select';

const options = [
  { value: 'reported', label: 'Reported' },
  { value: 'confirmed', label: 'Confirmed' },
  { value: 'in_progress', label: 'In progress' },
  { value: 'fixed', label: 'Fixed' },
];

const meta = {
  title: 'Atoms/Select',
  component: Select,
  args: {
    label: 'State',
    options,
  },
} satisfies Meta<typeof Select>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = { args: { value: 'reported' } };

export const WithPlaceholder: Story = {
  args: { value: '', placeholder: 'Select a state' },
};

export const WithError: Story = {
  args: { value: '', error: 'State is required' },
};

export const Disabled: Story = {
  args: { value: 'reported', disabled: true },
};
