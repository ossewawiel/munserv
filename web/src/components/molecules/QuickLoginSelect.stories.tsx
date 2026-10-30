import type { Meta, StoryObj } from '@storybook/react-vite';
import { userEvent, within } from 'storybook/test';

import { QuickLoginSelect } from './QuickLoginSelect';
import { ADMIN_ROLES } from '@/shared/types/admin';
import type { DemoAccount } from '@/shared/types/demoAccount';

const accounts: readonly DemoAccount[] = [
  ...ADMIN_ROLES.map((group, index): DemoAccount => ({
    group,
    name: index === 0 ? '' : `Tester ${index}`,
    email: `${group}@example.test`,
    password: 'example-password',
  })),
];

const meta = {
  title: 'Molecules/QuickLoginSelect',
  component: QuickLoginSelect,
  args: { accounts, onPick: () => {} },
} satisfies Meta<typeof QuickLoginSelect>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Closed: Story = {};

export const Open: Story = {
  play: async ({ canvasElement }) => {
    await userEvent.click(within(canvasElement).getByRole('combobox'));
    // The menu text is the first use of some font faces; the browser loads them lazily,
    // so wait for them before the story counts as settled.
    await document.fonts.ready;
  },
};
