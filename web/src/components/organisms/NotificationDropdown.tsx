import { type FC, useState, useCallback, useMemo } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Avatar from '@mui/material/Avatar';
import Badge from '@mui/material/Badge';
import Box from '@mui/material/Box';
import ButtonBase from '@mui/material/ButtonBase';
import ClickAwayListener from '@mui/material/ClickAwayListener';
import Divider from '@mui/material/Divider';
import Fade from '@mui/material/Fade';
import List from '@mui/material/List';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemText from '@mui/material/ListItemText';
import Paper from '@mui/material/Paper';
import Popper from '@mui/material/Popper';
import Typography from '@mui/material/Typography';
import NotificationsIcon from '@mui/icons-material/Notifications';
import MarkEmailReadIcon from '@mui/icons-material/MarkEmailRead';

import { useMessages, useMarkAsRead, useUnreadCount } from '@/features/messages/hooks';
import type { Message, MessageType } from '@/shared/types/message';
import { commonAvatar, mediumAvatar } from '@/theme';
import { formatRelativeTime } from '@/shared/utils/formatters';

/**
 * Get icon color based on message type
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

/**
 * Notification dropdown for the header - shows unread messages
 */
export const NotificationDropdown: FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [anchorEl, setAnchorEl] = useState<HTMLButtonElement | null>(null);
  const open = Boolean(anchorEl);

  const { data: unreadCount = 0 } = useUnreadCount();
  const { data: messagesData } = useMessages({ status: 'unread', size: 5 });
  const markAsRead = useMarkAsRead();

  const messages = useMemo(() => messagesData?.items ?? [], [messagesData]);

  const handleToggle = useCallback(
    (event: React.MouseEvent<HTMLButtonElement>) => {
      setAnchorEl(anchorEl ? null : event.currentTarget);
    },
    [anchorEl]
  );

  const handleClose = useCallback(() => {
    setAnchorEl(null);
  }, []);

  const handleMessageClick = useCallback(
    (message: Message) => {
      // Mark as read if unread
      if (message.status === 'unread') {
        markAsRead.mutate(message.id);
      }
      handleClose();
      navigate(`/messages/${message.id}`);
    },
    [markAsRead, handleClose, navigate]
  );

  const handleViewAll = useCallback(() => {
    handleClose();
    navigate('/messages');
  }, [handleClose, navigate]);

  return (
    <>
      {/* Notification Bell Button */}
      <ButtonBase
        sx={{ borderRadius: '12px' }}
        aria-controls={open ? 'notification-menu' : undefined}
        aria-haspopup="true"
        aria-expanded={open}
        aria-label={t('messages.notifications', 'Notifications')}
        onClick={handleToggle}
      >
        <Badge
          badgeContent={unreadCount}
          color="error"
          max={99}
          sx={{
            '& .MuiBadge-badge': {
              fontSize: '0.65rem',
              height: 16,
              minWidth: 16,
            },
          }}
        >
          <Avatar
            variant="rounded"
            sx={{
              ...commonAvatar,
              ...mediumAvatar,
              transition: 'all .2s ease-in-out',
              bgcolor: open
                ? 'var(--munserv-palette-secondary-main)'
                : 'var(--munserv-palette-secondary-light)',
              color: open
                ? 'var(--munserv-palette-secondary-contrastText)'
                : 'var(--munserv-palette-secondary-dark)',
              '&:hover': {
                bgcolor: 'var(--munserv-palette-secondary-main)',
                color: 'var(--munserv-palette-secondary-contrastText)',
              },
            }}
          >
            <NotificationsIcon fontSize="small" />
          </Avatar>
        </Badge>
      </ButtonBase>

      {/* Notification Dropdown */}
      <Popper
        placement="bottom-end"
        open={open}
        anchorEl={anchorEl}
        role={undefined}
        transition
        disablePortal
        modifiers={[
          {
            name: 'offset',
            options: {
              offset: [0, 14],
            },
          },
        ]}
      >
        {({ TransitionProps }) => (
          <ClickAwayListener onClickAway={handleClose}>
            <Fade {...TransitionProps} timeout={350}>
              <Paper
                id="notification-menu"
                elevation={16}
                sx={{
                  borderRadius: 2,
                  overflow: 'hidden',
                  minWidth: 320,
                  maxWidth: 400,
                }}
              >
                {open && (
                  <>
                    {/* Header */}
                    <Box
                      sx={{
                        p: 2,
                        bgcolor: 'primary.main',
                        color: 'primary.contrastText',
                      }}
                    >
                      <Typography variant="subtitle1" fontWeight={600}>
                        {t('messages.title', 'Messages')}
                      </Typography>
                      {unreadCount > 0 && (
                        <Typography variant="caption">
                          {t('messages.unreadCount', '{{count}} unread', {
                            count: unreadCount,
                          })}
                        </Typography>
                      )}
                    </Box>

                    {/* Messages List */}
                    {messages.length > 0 ? (
                      <List sx={{ p: 0, maxHeight: 300, overflow: 'auto' }}>
                        {messages.map((message) => (
                          <ListItemButton
                            key={message.id}
                            onClick={() => handleMessageClick(message)}
                            sx={{
                              py: 1.5,
                              px: 2,
                              borderLeft: '3px solid',
                              borderLeftColor: getMessageTypeColor(message.type),
                              '&:hover': {
                                bgcolor: 'action.hover',
                              },
                            }}
                          >
                            <ListItemText
                              primary={
                                <Typography
                                  variant="body2"
                                  fontWeight={message.status === 'unread' ? 600 : 400}
                                  noWrap
                                >
                                  {message.title}
                                </Typography>
                              }
                              secondary={
                                <Box
                                  component="span"
                                  sx={{
                                    display: 'flex',
                                    justifyContent: 'space-between',
                                    alignItems: 'center',
                                    mt: 0.5,
                                  }}
                                >
                                  <Typography
                                    variant="caption"
                                    color="text.secondary"
                                    noWrap
                                    sx={{ maxWidth: '60%' }}
                                  >
                                    {message.body}
                                  </Typography>
                                  <Typography variant="caption" color="text.disabled">
                                    {formatRelativeTime(message.createdAt)}
                                  </Typography>
                                </Box>
                              }
                            />
                          </ListItemButton>
                        ))}
                      </List>
                    ) : (
                      <Box sx={{ p: 3, textAlign: 'center' }}>
                        <MarkEmailReadIcon
                          sx={{ fontSize: 48, color: 'text.disabled', mb: 1 }}
                        />
                        <Typography variant="body2" color="text.secondary">
                          {t('messages.empty', 'No messages')}
                        </Typography>
                      </Box>
                    )}

                    <Divider />

                    {/* View All Link */}
                    <Box sx={{ p: 1 }}>
                      <ListItemButton
                        component={Link}
                        to="/messages"
                        onClick={handleViewAll}
                        sx={{
                          borderRadius: 1,
                          justifyContent: 'center',
                        }}
                      >
                        <Typography variant="body2" color="primary">
                          {t('messages.viewAll', 'View all messages')}
                        </Typography>
                      </ListItemButton>
                    </Box>
                  </>
                )}
              </Paper>
            </Fade>
          </ClickAwayListener>
        )}
      </Popper>
    </>
  );
};
