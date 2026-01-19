import { type FC, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import List from '@mui/material/List';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemText from '@mui/material/ListItemText';
import Skeleton from '@mui/material/Skeleton';
import Typography from '@mui/material/Typography';
import CircleIcon from '@mui/icons-material/Circle';
import MarkEmailReadIcon from '@mui/icons-material/MarkEmailRead';

import type { Message, MessageType } from '@/shared/types/message';
import { formatRelativeTime } from '@/shared/utils/formatters';

/**
 * Get accent color based on message type
 */
function getMessageTypeColor(type: MessageType): string {
  switch (type) {
    case 'ground_admin_application':
    case 'ground_admin_invitation':
      return 'primary.main';
    case 'verify_new_issue':
    case 'verify_fix':
      return 'warning.main';
    case 'member_registration':
      return 'info.main';
    case 'ground_admin_approved':
      return 'success.main';
    case 'ground_admin_declined':
    case 'ground_admin_revocation':
      return 'error.main';
    default:
      return 'text.secondary';
  }
}

interface MessageListProps {
  messages: Message[];
  selectedId?: string;
  onSelect: (message: Message) => void;
  isLoading?: boolean;
}

/**
 * Message list component for the inbox sidebar
 */
export const MessageList: FC<MessageListProps> = ({
  messages,
  selectedId,
  onSelect,
  isLoading = false,
}) => {
  const { t } = useTranslation();

  const sortedMessages = useMemo(
    () =>
      [...messages].sort(
        (a, b) =>
          new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
      ),
    [messages]
  );

  if (isLoading) {
    return (
      <List sx={{ p: 0 }}>
        {[1, 2, 3, 4, 5].map((i) => (
          <Box key={i} sx={{ p: 2, borderBottom: '1px solid', borderColor: 'divider' }}>
            <Skeleton variant="text" width="60%" height={24} />
            <Skeleton variant="text" width="80%" height={18} sx={{ mt: 0.5 }} />
            <Skeleton variant="text" width="40%" height={16} sx={{ mt: 0.5 }} />
          </Box>
        ))}
      </List>
    );
  }

  if (messages.length === 0) {
    return (
      <Box
        sx={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          py: 6,
          px: 2,
        }}
      >
        <MarkEmailReadIcon sx={{ fontSize: 64, color: 'text.disabled', mb: 2 }} />
        <Typography variant="body1" color="text.secondary">
          {t('messages.empty', 'No messages')}
        </Typography>
      </Box>
    );
  }

  return (
    <List sx={{ p: 0, overflow: 'auto' }}>
      {sortedMessages.map((message) => (
        <ListItemButton
          key={message.id}
          selected={message.id === selectedId}
          onClick={() => onSelect(message)}
          sx={{
            py: 2,
            px: 2,
            borderBottom: '1px solid',
            borderColor: 'divider',
            borderLeft: '3px solid',
            borderLeftColor: getMessageTypeColor(message.type),
            bgcolor: message.status === 'unread' ? 'action.hover' : 'transparent',
            '&.Mui-selected': {
              bgcolor: 'primary.light',
              borderLeftColor: 'primary.main',
              '&:hover': {
                bgcolor: 'primary.light',
              },
            },
            '&:hover': {
              bgcolor: 'action.hover',
            },
          }}
        >
          <ListItemText
            primary={
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                {message.status === 'unread' && (
                  <CircleIcon sx={{ fontSize: 8, color: 'primary.main' }} />
                )}
                <Typography
                  variant="body2"
                  fontWeight={message.status === 'unread' ? 600 : 400}
                  noWrap
                  sx={{ flex: 1 }}
                >
                  {message.title}
                </Typography>
              </Box>
            }
            secondary={
              <Box component="span" sx={{ display: 'block', mt: 0.5 }}>
                <Typography
                  variant="caption"
                  color="text.secondary"
                  component="span"
                  sx={{
                    display: 'block',
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                    whiteSpace: 'nowrap',
                  }}
                >
                  {message.body}
                </Typography>
                <Typography
                  variant="caption"
                  color="text.disabled"
                  component="span"
                  sx={{ display: 'block', mt: 0.5 }}
                >
                  {formatRelativeTime(message.createdAt)}
                </Typography>
              </Box>
            }
          />
        </ListItemButton>
      ))}
    </List>
  );
};
