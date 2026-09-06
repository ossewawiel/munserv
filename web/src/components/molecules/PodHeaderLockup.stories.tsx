import type { Meta, StoryObj } from '@storybook/react-vite';

import { PodHeaderLockup } from './PodHeaderLockup';

const meta = {
  title: 'Molecules/PodHeaderLockup',
  component: PodHeaderLockup,
} satisfies Meta<typeof PodHeaderLockup>;

export default meta;
type Story = StoryObj<typeof meta>;

export const WithLogo: Story = {
  args: { displayName: 'Munserv Pod Ward42', logoUrl: '/assets/app-mark.png' },
};

export const WithoutLogo: Story = {
  args: { displayName: 'Munserv Pod Ward42', logoUrl: null },
};
