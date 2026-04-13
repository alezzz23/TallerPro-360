import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

import {
  fetchInvoice,
  createInvoice,
  fetchNPS,
  createNPS,
  closeOrder,
} from '@/services/billing';
import type { InvoiceCreatePayload, NPSCreatePayload } from '@/services/billing';

// ── Invoice ────────────────────────────────────────────────

export function useInvoice(orderId: string) {
  return useQuery({
    queryKey: ['invoice', orderId],
    queryFn: () => fetchInvoice(orderId),
    enabled: !!orderId,
    retry: (count, error: any) => {
      if (error?.response?.status === 404) return false;
      return count < 2;
    },
  });
}

export function useCreateInvoice() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ orderId, data }: { orderId: string; data: InvoiceCreatePayload }) =>
      createInvoice(orderId, data),
    onSuccess: (_d, vars) => {
      qc.invalidateQueries({ queryKey: ['invoice', vars.orderId] });
      qc.invalidateQueries({ queryKey: ['orders'] });
      qc.invalidateQueries({ queryKey: ['order', vars.orderId] });
    },
  });
}

// ── NPS ────────────────────────────────────────────────────

export function useNPS(orderId: string) {
  return useQuery({
    queryKey: ['nps', orderId],
    queryFn: () => fetchNPS(orderId),
    enabled: !!orderId,
    retry: (count, error: any) => {
      if (error?.response?.status === 404) return false;
      return count < 2;
    },
  });
}

export function useCreateNPS() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ orderId, data }: { orderId: string; data: NPSCreatePayload }) =>
      createNPS(orderId, data),
    onSuccess: (_d, vars) => {
      qc.invalidateQueries({ queryKey: ['nps', vars.orderId] });
    },
  });
}

// ── Close Order ────────────────────────────────────────────

export function useCloseOrder() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (orderId: string) => closeOrder(orderId),
    onSuccess: (_d, orderId) => {
      qc.invalidateQueries({ queryKey: ['orders'] });
      qc.invalidateQueries({ queryKey: ['order', orderId] });
    },
  });
}
