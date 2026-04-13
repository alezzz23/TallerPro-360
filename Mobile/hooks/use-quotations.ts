import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

import {
  fetchOrderQuotation,
  createQuotation,
  fetchQuotation,
  applyDiscount,
  sendQuotation,
  approveQuotation,
  rejectQuotation,
  fetchCustomer,
} from '@/services/quotations';
import type { QuotationCreatePayload, DiscountPayload } from '@/services/quotations';

// ── Queries ────────────────────────────────────────────────

export function useOrderQuotation(orderId: string) {
  return useQuery({
    queryKey: ['quotation', 'order', orderId],
    queryFn: () => fetchOrderQuotation(orderId),
    enabled: !!orderId,
  });
}

export function useQuotation(quotationId: string) {
  return useQuery({
    queryKey: ['quotation', quotationId],
    queryFn: () => fetchQuotation(quotationId),
    enabled: !!quotationId,
  });
}

export function useCustomer(customerId: string) {
  return useQuery({
    queryKey: ['customer', customerId],
    queryFn: () => fetchCustomer(customerId),
    enabled: !!customerId,
  });
}

// ── Mutations ──────────────────────────────────────────────

export function useCreateQuotation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ orderId, data }: { orderId: string; data: QuotationCreatePayload }) =>
      createQuotation(orderId, data),
    onSuccess: (_d, vars) => {
      qc.invalidateQueries({ queryKey: ['quotation', 'order', vars.orderId] });
      qc.invalidateQueries({ queryKey: ['orders'] });
    },
  });
}

export function useApplyDiscount() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ quotationId, data }: { quotationId: string; data: DiscountPayload }) =>
      applyDiscount(quotationId, data),
    onSuccess: (result) => {
      qc.invalidateQueries({ queryKey: ['quotation', result.id] });
      qc.invalidateQueries({ queryKey: ['quotation', 'order', result.order_id] });
    },
  });
}

export function useSendQuotation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (quotationId: string) => sendQuotation(quotationId),
    onSuccess: (result) => {
      qc.invalidateQueries({ queryKey: ['quotation', result.id] });
      qc.invalidateQueries({ queryKey: ['quotation', 'order', result.order_id] });
    },
  });
}

export function useApproveQuotation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (quotationId: string) => approveQuotation(quotationId),
    onSuccess: (result) => {
      qc.invalidateQueries({ queryKey: ['quotation', result.id] });
      qc.invalidateQueries({ queryKey: ['quotation', 'order', result.order_id] });
      qc.invalidateQueries({ queryKey: ['orders'] });
    },
  });
}

export function useRejectQuotation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ quotationId, razon }: { quotationId: string; razon?: string }) =>
      rejectQuotation(quotationId, razon),
    onSuccess: (result) => {
      qc.invalidateQueries({ queryKey: ['quotation', result.id] });
      qc.invalidateQueries({ queryKey: ['quotation', 'order', result.order_id] });
      qc.invalidateQueries({ queryKey: ['orders'] });
    },
  });
}
