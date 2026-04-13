import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

import {
  fetchQC,
  createOrUpdateQC,
  approveQC,
  fetchReceptionChecklist,
} from '@/services/qc';
import type { QCCreatePayload } from '@/services/qc';

// ── Queries ────────────────────────────────────────────────

export function useQC(orderId: string) {
  return useQuery({
    queryKey: ['qc', orderId],
    queryFn: () => fetchQC(orderId),
    enabled: !!orderId,
    retry: (count, error: any) => {
      if (error?.response?.status === 404) return false;
      return count < 2;
    },
  });
}

export function useReceptionChecklist(orderId: string) {
  return useQuery({
    queryKey: ['receptionChecklist', orderId],
    queryFn: () => fetchReceptionChecklist(orderId),
    enabled: !!orderId,
  });
}

// ── Mutations ──────────────────────────────────────────────

export function useCreateQC() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ orderId, data }: { orderId: string; data: QCCreatePayload }) =>
      createOrUpdateQC(orderId, data),
    onSuccess: (_d, vars) => {
      qc.invalidateQueries({ queryKey: ['qc', vars.orderId] });
      qc.invalidateQueries({ queryKey: ['orders'] });
      qc.invalidateQueries({ queryKey: ['order', vars.orderId] });
    },
  });
}

export function useApproveQC() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (orderId: string) => approveQC(orderId),
    onSuccess: (_d, orderId) => {
      qc.invalidateQueries({ queryKey: ['qc', orderId] });
      qc.invalidateQueries({ queryKey: ['orders'] });
      qc.invalidateQueries({ queryKey: ['order', orderId] });
    },
  });
}
