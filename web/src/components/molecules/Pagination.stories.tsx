import type { Meta, StoryObj } from '@storybook/react-vite';

import { Pagination } from './Pagination';

const meta = {
  title: 'Molecules/Pagination',
  component: Pagination,
  args: {
    currentPage: 1,
    totalPages: 5,
    totalItems: 48,
    pageSize: 10,
    onPageChange: () => {},
  },
} satisfies Meta<typeof Pagination>;

export default meta;
type Story = StoryObj<typeof meta>;

export const FirstPage: Story = {};

export const MiddlePage: Story = { args: { currentPage: 3 } };

export const LastPage: Story = { args: { currentPage: 5 } };
