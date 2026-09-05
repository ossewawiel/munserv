import { useState } from 'react';
import type { Meta, StoryObj } from '@storybook/react-vite';
import Typography from '@mui/material/Typography';

import { Button } from './Button';
import { Modal } from './Modal';

const meta = {
  title: 'Atoms/Modal',
  component: Modal,
} satisfies Meta<typeof Modal>;

export default meta;
type Story = StoryObj<typeof meta>;

function ModalDemo({ size }: { size?: 'sm' | 'md' | 'lg' }) {
  const [isOpen, setIsOpen] = useState(true);

  return (
    <>
      <Button onClick={() => setIsOpen(true)}>Open modal</Button>
      <Modal isOpen={isOpen} onClose={() => setIsOpen(false)} title="Issue details" size={size}>
        <Typography variant="body2">
          A pothole was reported on Main Street two days ago.
        </Typography>
      </Modal>
    </>
  );
}

const noop = () => {};

export const WithTitle: Story = {
  args: { isOpen: true, onClose: noop, children: null },
  render: () => <ModalDemo size="md" />,
};

export const Large: Story = {
  args: { isOpen: true, onClose: noop, children: null },
  render: () => <ModalDemo size="lg" />,
};

function ModalWithoutTitleDemo() {
  const [isOpen, setIsOpen] = useState(true);

  return (
    <>
      <Button onClick={() => setIsOpen(true)}>Open modal</Button>
      <Modal isOpen={isOpen} onClose={() => setIsOpen(false)}>
        <Typography variant="body2">No title, no close button in the header.</Typography>
      </Modal>
    </>
  );
}

export const WithoutTitle: Story = {
  args: { isOpen: true, onClose: noop, children: null },
  render: () => <ModalWithoutTitleDemo />,
};
