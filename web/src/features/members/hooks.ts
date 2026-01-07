import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/shared/hooks/useAuth';
import { membersApi } from './api';

export function useMembers(params?: { page?: number; limit?: number }) {
  const { admin } = useAuth();

  return useQuery({
    queryKey: ['members', admin?.sectorId, params],
    queryFn: () => membersApi.getAll(admin!.sectorId, params),
    enabled: !!admin?.sectorId,
  });
}
