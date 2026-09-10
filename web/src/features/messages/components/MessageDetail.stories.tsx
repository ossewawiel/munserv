import type { Meta, StoryObj } from '@storybook/react-vite';
import Card from '@mui/material/Card';

import { MessageDetail } from './MessageDetail';
import type { Message } from '@/shared/types/message';

// The welcome message body, task list and metadata are B10's, server-owned copy
// (see design/canvases/pod-chief-mvp/messages). The card here matches the 739px
// detail column of the two-card inbox layout in MessagesPage.
const welcomeMessage: Message = {
  id: 'msg-5',
  type: 'admin_welcome',
  title: 'Welcome to MunServ',
  body: 'Welcome, Jane Ward. Your administrator account is ready. Complete the tasks below to get started.',
  recipientId: 'admin-1',
  recipientType: 'admin',
  senderType: 'system',
  status: 'read',
  actionType: 'acknowledge',
  metadata: {
    tasks: [
      'Change your temporary password.',
      'Complete your profile (optional, you can skip it).',
      'Open Messages to see what needs your attention.',
    ],
    role: 'pod_admin',
  },
  createdAt: '2026-01-19T11:00:00Z',
  readAt: '2026-01-19T11:00:05Z',
};

const meta = {
  title: 'Features/Messages/MessageDetail',
  component: MessageDetail,
  decorators: [
    (Story) => (
      <Card sx={{ width: 739, height: 700 }}>
        <Story />
      </Card>
    ),
  ],
} satisfies Meta<typeof MessageDetail>;

export default meta;
type Story = StoryObj<typeof meta>;

// Matches Main.dc.html (WelcomeMessageDetail): body, task list, Additional
// Information carrying role only, Dismiss action.
export const WelcomeMessageDetail: Story = {
  args: {
    message: welcomeMessage,
    onAction: () => {},
  },
};

// Matches WelcomeMessageDetailNoTasks.dc.html: same message shape but no task
// array in metadata, so no task list is rendered.
export const WelcomeMessageNoTasks: Story = {
  args: {
    message: {
      ...welcomeMessage,
      metadata: { role: 'pod_admin' },
    },
    onAction: () => {},
  },
};
