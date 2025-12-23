import { useQuery } from '@tanstack/react-query';
import { membersApi } from './api';

export function useMembers(params?: { page?: number; limit?: number }) {
  return useQuery({
    queryKey: ['members', params],
    queryFn: () => membersApi.getAll(params),
  });
}
