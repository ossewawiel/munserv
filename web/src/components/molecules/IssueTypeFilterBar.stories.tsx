import { useState } from 'react';
import type { Meta, StoryObj } from '@storybook/react-vite';

import type { IssueType } from '@/features/issues/types';
import { IssueTypeFilterBar } from './IssueTypeFilterBar';

const meta = {
  title: 'Molecules/IssueTypeFilterBar',
  component: IssueTypeFilterBar,
} satisfies Meta<typeof IssueTypeFilterBar>;

export default meta;
type Story = StoryObj<typeof meta>;

export const NoneActive: Story = {
  args: { activeTypes: new Set(), onToggle: () => {} },
};

export const SomeActive: Story = {
  args: {
    activeTypes: new Set<IssueType>(['pothole', 'water_leak']),
    onToggle: () => {},
  },
};

function InteractiveDemo() {
  const [activeTypes, setActiveTypes] = useState<Set<IssueType>>(new Set());

  const handleToggle = (type: IssueType) => {
    setActiveTypes((prev) => {
      const next = new Set(prev);
      if (next.has(type)) {
        next.delete(type);
      } else {
        next.add(type);
      }
      return next;
    });
  };

  return <IssueTypeFilterBar activeTypes={activeTypes} onToggle={handleToggle} />;
}

export const Interactive: Story = {
  args: { activeTypes: new Set(), onToggle: () => {} },
  render: () => <InteractiveDemo />,
};
