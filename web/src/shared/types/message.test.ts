import { describe, it, expect } from 'vitest';
import { getWelcomeTasks } from './message';
import type { Message } from './message';

const createMessage = (overrides: Partial<Message> = {}): Message => ({
  id: 'msg-1',
  type: 'admin_welcome',
  title: 'Welcome to MunServ',
  body: 'Welcome, Jane Ward. Your administrator account is ready.',
  recipientId: 'admin-1',
  recipientType: 'admin',
  senderType: 'system',
  status: 'unread',
  actionType: 'acknowledge',
  createdAt: '2026-01-19T10:00:00Z',
  ...overrides,
});

describe('getWelcomeTasks', () => {
  it('should return the tasks of an admin welcome message', () => {
    const message = createMessage({
      metadata: {
        tasks: [
          'Change your temporary password.',
          'Complete your profile (optional, you can skip it).',
          'Open Messages to see what needs your attention.',
        ],
        role: 'pod_admin',
      },
    });

    expect(getWelcomeTasks(message)).toEqual([
      'Change your temporary password.',
      'Complete your profile (optional, you can skip it).',
      'Open Messages to see what needs your attention.',
    ]);
  });

  it('should return an empty list when metadata has no task array', () => {
    expect(getWelcomeTasks(createMessage({ metadata: { role: 'pod_admin' } }))).toEqual([]);
    expect(getWelcomeTasks(createMessage({ metadata: undefined }))).toEqual([]);
    expect(getWelcomeTasks(createMessage({ metadata: { tasks: 'not-an-array' } }))).toEqual([]);
    expect(getWelcomeTasks(createMessage({ metadata: { tasks: [1, 2, 3] } }))).toEqual([]);
  });
});
