import { useState } from 'react';
import type { Meta, StoryObj } from '@storybook/react-vite';

import { IssueTypeFilterButton } from './IssueTypeFilterButton';

const meta = {
  title: 'Atoms/IssueTypeFilterButton',
  component: IssueTypeFilterButton,
  args: {
    type: 'pothole',
  },
} satisfies Meta<typeof IssueTypeFilterButton>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Inactive: Story = {
  args: { isActive: false, onClick: () => {} },
};

export const Active: Story = {
  args: { isActive: true, onClick: () => {} },
};

function ToggleDemo() {
  const [isActive, setIsActive] = useState(false);
  return (
    <IssueTypeFilterButton
      type="water_leak"
      isActive={isActive}
      onClick={() => setIsActive((prev) => !prev)}
    />
  );
}

export const Toggleable: Story = {
  args: { isActive: false, onClick: () => {} },
  render: () => <ToggleDemo />,
};
