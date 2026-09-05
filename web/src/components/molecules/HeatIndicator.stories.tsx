import type { Meta, StoryObj } from '@storybook/react-vite';

import { HeatIndicator } from './HeatIndicator';

const meta = {
  title: 'Molecules/HeatIndicator',
  component: HeatIndicator,
} satisfies Meta<typeof HeatIndicator>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Minimal: Story = { args: { heat: 0 } };
export const Low: Story = { args: { heat: 25 } };
export const Medium: Story = { args: { heat: 50 } };
export const High: Story = { args: { heat: 75 } };
export const Critical: Story = { args: { heat: 100 } };
export const WithoutValue: Story = { args: { heat: 60, showValue: false } };
