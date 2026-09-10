import type { Meta, StoryObj } from '@storybook/react-vite';
import Box from '@mui/material/Box';
import Card from '@mui/material/Card';
import Grid from '@mui/material/Grid';
import Typography from '@mui/material/Typography';

import { MessageList } from './MessageList';
import type { Message } from '@/shared/types/message';

// Matches the mock inbox in web/src/test/mocks/handlers.ts: the admin_welcome
// message is unread and the most recent, so it sorts to the top of the list.
const messages: Message[] = [
  {
    id: 'msg-5',
    type: 'admin_welcome',
    title: 'Welcome to MunServ',
    body: 'Welcome, Jane Ward. Your administrator account is ready. Complete the tasks below to get started.',
    recipientId: 'admin-1',
    recipientType: 'admin',
    senderType: 'system',
    status: 'unread',
    actionType: 'acknowledge',
    metadata: { role: 'pod_admin' },
    createdAt: '2026-01-19T11:00:00Z',
  },
  {
    id: 'msg-1',
    type: 'ground_admin_application',
    title: 'Ground Admin Application',
    body: 'John Smith has applied to become a Ground Admin in your sector.',
    recipientId: 'admin-1',
    recipientType: 'admin',
    senderId: 'member-1',
    senderType: 'member',
    status: 'unread',
    actionType: 'approve_reject',
    createdAt: '2026-01-19T10:00:00Z',
  },
  {
    id: 'msg-2',
    type: 'verify_new_issue',
    title: 'Verify New Issue',
    body: 'A new pothole has been reported at 123 Main Street. Please verify this issue exists.',
    recipientId: 'admin-1',
    recipientType: 'admin',
    senderType: 'system',
    status: 'unread',
    actionType: 'confirm_verify',
    createdAt: '2026-01-19T09:30:00Z',
  },
];

const meta = {
  title: 'Features/Messages/MessageList',
  component: MessageList,
} satisfies Meta<typeof MessageList>;

export default meta;
type Story = StoryObj<typeof meta>;

// Matches WelcomeMessageList.dc.html: the inbox on arrival, the welcome
// message unread and auto-selected at the top (primary.light background,
// primary.main accent, still unread) while the detail pane is loading. The
// row itself is unchanged: no per-type icon, no type label, default
// text.secondary left accent.
export const WelcomeMessageList: Story = {
  args: {
    messages,
    selectedId: 'msg-5',
    onSelect: () => {},
  },
  render: () => (
    <Grid container spacing={3} sx={{ width: 1132, height: 700 }}>
      <Grid size={4}>
        <Card sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
          <Box sx={{ flex: 1, overflow: 'auto' }}>
            <MessageList messages={messages} selectedId="msg-5" onSelect={() => {}} />
          </Box>
        </Card>
      </Grid>
      <Grid size={8}>
        <Card sx={{ height: '100%' }}>
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              height: '100%',
            }}
          >
            <Typography sx={{ color: 'text.secondary' }}>Loading...</Typography>
          </Box>
        </Card>
      </Grid>
    </Grid>
  ),
};
