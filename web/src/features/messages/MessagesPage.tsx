import { type FC, useState, useCallback, useEffect, useMemo } from 'react';
import { useParams, useNavigate, useSearchParams } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Card from '@mui/material/Card';
import FormControl from '@mui/material/FormControl';
import Grid from '@mui/material/Grid';
import InputLabel from '@mui/material/InputLabel';
import MenuItem from '@mui/material/MenuItem';
import Select, { type SelectChangeEvent } from '@mui/material/Select';
import Typography from '@mui/material/Typography';
import useMediaQuery from '@mui/material/useMediaQuery';
import { useTheme } from '@mui/material/styles';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';

import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { Breadcrumbs } from '@/components/molecules/Breadcrumbs';
import { MessageList } from './components/MessageList';
import { MessageDetail } from './components/MessageDetail';
import { useMessages, useMessage, useMarkAsRead, useMessageAction } from './hooks';
import type { Message, MessageStatus } from '@/shared/types/message';

/**
 * Messages page with email-style inbox layout
 */
export const MessagesPage: FC = () => {
  const { t } = useTranslation();
  const theme = useTheme();
  const navigate = useNavigate();
  const { id: messageIdFromUrl } = useParams<{ id?: string }>();
  const [searchParams, setSearchParams] = useSearchParams();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));

  // Filter state from URL
  const statusFilter = (searchParams.get('status') as MessageStatus | 'all') || 'all';

  // Local state for user-selected message
  const [userSelectedId, setUserSelectedId] = useState<string | undefined>(messageIdFromUrl);

  // Queries
  const { data: messagesData, isLoading: isLoadingMessages } = useMessages({
    status: statusFilter === 'all' ? undefined : statusFilter,
    page: 1,
    size: 50,
  });

  // Mutations
  const markAsRead = useMarkAsRead();
  const messageAction = useMessageAction();

  const messages = useMemo(() => messagesData?.items ?? [], [messagesData]);

  // Compute effective selected ID: user selection, URL param, or first message on desktop
  const effectiveSelectedId = useMemo(() => {
    if (userSelectedId) return userSelectedId;
    if (messageIdFromUrl) return messageIdFromUrl;
    if (!isMobile && messages.length > 0) return messages[0].id;
    return undefined;
  }, [userSelectedId, messageIdFromUrl, isMobile, messages]);

  // Query the selected message
  const { data: selectedMessage, isLoading: isLoadingMessage } = useMessage(
    effectiveSelectedId ?? ''
  );

  // Mark message as read when selected
  useEffect(() => {
    if (selectedMessage && selectedMessage.status === 'unread') {
      markAsRead.mutate(selectedMessage.id);
    }
  }, [selectedMessage, markAsRead]);

  // Sync URL with selected message (only when user explicitly selects)
  useEffect(() => {
    if (userSelectedId && userSelectedId !== messageIdFromUrl) {
      navigate(`/messages/${userSelectedId}`, { replace: true });
    }
  }, [userSelectedId, messageIdFromUrl, navigate]);

  const handleMessageSelect = useCallback((message: Message) => {
    setUserSelectedId(message.id);
  }, []);

  const handleStatusFilterChange = useCallback(
    (event: SelectChangeEvent) => {
      const value = event.target.value as MessageStatus | 'all';
      setSearchParams((prev) => {
        if (value === 'all') {
          prev.delete('status');
        } else {
          prev.set('status', value);
        }
        return prev;
      });
    },
    [setSearchParams]
  );

  const handleAction = useCallback(
    (action: string, note?: string) => {
      if (!effectiveSelectedId) return;
      messageAction.mutate(
        { id: effectiveSelectedId, action: { action, note } },
        {
          onSuccess: () => {
            // Optionally move to next message or refresh
          },
        }
      );
    },
    [effectiveSelectedId, messageAction]
  );

  const handleBackToList = useCallback(() => {
    setUserSelectedId(undefined);
    navigate('/messages');
  }, [navigate]);

  // Mobile: show either list or detail
  if (isMobile) {
    if (effectiveSelectedId && selectedMessage) {
      return (
        <DashboardLayout>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
            <Button
              startIcon={<ArrowBackIcon />}
              onClick={handleBackToList}
              size="small"
            >
              {t('common.buttons.back', 'Back')}
            </Button>
          </Box>
          <Breadcrumbs
            title={t('messages.title', 'Messages')}
            items={[
              { label: t('dashboard.title', 'Dashboard'), path: '/', icon: 'home' },
              { label: t('messages.title', 'Messages') },
            ]}
          />
          <Card sx={{ minHeight: 400, mt: 3 }}>
            <MessageDetail
              message={selectedMessage}
              onAction={handleAction}
              isActioning={messageAction.isPending}
            />
          </Card>
        </DashboardLayout>
      );
    }

    return (
      <DashboardLayout>
        <Breadcrumbs
          title={t('messages.title', 'Messages')}
          items={[
            { label: t('dashboard.title', 'Dashboard'), path: '/', icon: 'home' },
            { label: t('messages.title', 'Messages') },
          ]}
        />
        <Card sx={{ mt: 3 }}>
          <Box sx={{ p: 2, borderBottom: '1px solid', borderColor: 'divider' }}>
            <FormControl size="small" sx={{ minWidth: 150 }}>
              <InputLabel>{t('messages.filterByStatus', 'Status')}</InputLabel>
              <Select
                value={statusFilter}
                label={t('messages.filterByStatus', 'Status')}
                onChange={handleStatusFilterChange}
              >
                <MenuItem value="all">{t('common.all', 'All')}</MenuItem>
                <MenuItem value="unread">{t('messages.status.unread', 'Unread')}</MenuItem>
                <MenuItem value="read">{t('messages.status.read', 'Read')}</MenuItem>
                <MenuItem value="actioned">{t('messages.status.actioned', 'Actioned')}</MenuItem>
              </Select>
            </FormControl>
          </Box>
          <MessageList
            messages={messages}
            selectedId={effectiveSelectedId}
            onSelect={handleMessageSelect}
            isLoading={isLoadingMessages}
          />
        </Card>
      </DashboardLayout>
    );
  }

  // Desktop: side-by-side layout
  return (
    <DashboardLayout>
      <Breadcrumbs
        title={t('messages.title', 'Messages')}
        items={[
          { label: t('dashboard.title', 'Dashboard'), path: '/', icon: 'home' },
          { label: t('messages.title', 'Messages') },
        ]}
      />
      <Grid container spacing={3} sx={{ height: 'calc(100vh - 200px)', mt: 3 }}>
        {/* Message List Sidebar */}
        <Grid size={{ xs: 12, md: 4 }}>
          <Card sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
            <Box sx={{ p: 2, borderBottom: '1px solid', borderColor: 'divider' }}>
              <FormControl size="small" fullWidth>
                <InputLabel>{t('messages.filterByStatus', 'Status')}</InputLabel>
                <Select
                  value={statusFilter}
                  label={t('messages.filterByStatus', 'Status')}
                  onChange={handleStatusFilterChange}
                >
                  <MenuItem value="all">{t('common.all', 'All')}</MenuItem>
                  <MenuItem value="unread">{t('messages.status.unread', 'Unread')}</MenuItem>
                  <MenuItem value="read">{t('messages.status.read', 'Read')}</MenuItem>
                  <MenuItem value="actioned">
                    {t('messages.status.actioned', 'Actioned')}
                  </MenuItem>
                </Select>
              </FormControl>
            </Box>
            <Box sx={{ flex: 1, overflow: 'auto' }}>
              <MessageList
                messages={messages}
                selectedId={effectiveSelectedId}
                onSelect={handleMessageSelect}
                isLoading={isLoadingMessages}
              />
            </Box>
          </Card>
        </Grid>

        {/* Message Detail */}
        <Grid size={{ xs: 12, md: 8 }}>
          <Card sx={{ height: '100%' }}>
            {selectedMessage ? (
              <MessageDetail
                message={selectedMessage}
                onAction={handleAction}
                isActioning={messageAction.isPending}
              />
            ) : isLoadingMessage ? (
              <Box
                sx={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  height: '100%',
                }}
              >
                <Typography color="text.secondary">
                  {t('common.loading', 'Loading...')}
                </Typography>
              </Box>
            ) : (
              <Box
                sx={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  height: '100%',
                }}
              >
                <Typography color="text.secondary">
                  {t('messages.selectMessage', 'Select a message to view')}
                </Typography>
              </Box>
            )}
          </Card>
        </Grid>
      </Grid>
    </DashboardLayout>
  );
};
