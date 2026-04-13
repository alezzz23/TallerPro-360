import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

import {
  fetchOrderFindings,
  createFinding,
  updateFinding,
  addFindingPhoto,
  addPart,
  fetchParts,
  fetchTechnicians,
} from '@/services/diagnosis';
import type {
  FindingCreatePayload,
  FindingUpdatePayload,
  PartCreatePayload,
} from '@/services/diagnosis';

// ── Queries ────────────────────────────────────────────────

export function useOrderFindings(orderId: string) {
  return useQuery({
    queryKey: ['findings', orderId],
    queryFn: () => fetchOrderFindings(orderId),
    enabled: !!orderId,
  });
}

export function useTechnicians() {
  return useQuery({
    queryKey: ['technicians'],
    queryFn: fetchTechnicians,
    staleTime: 5 * 60_000, // 5 min — technician list changes rarely
  });
}

export function useParts(findingId: string) {
  return useQuery({
    queryKey: ['parts', findingId],
    queryFn: () => fetchParts(findingId),
    enabled: !!findingId,
  });
}

// ── Mutations ──────────────────────────────────────────────

export function useCreateFinding() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ orderId, data }: { orderId: string; data: FindingCreatePayload }) =>
      createFinding(orderId, data),
    onSuccess: (_d, vars) =>
      qc.invalidateQueries({ queryKey: ['findings', vars.orderId] }),
  });
}

export function useUpdateFinding(orderId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ findingId, data }: { findingId: string; data: FindingUpdatePayload }) =>
      updateFinding(findingId, data),
    onSuccess: () =>
      qc.invalidateQueries({ queryKey: ['findings', orderId] }),
  });
}

export function useAddFindingPhoto(orderId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ findingId, fotoUrl }: { findingId: string; fotoUrl: string }) =>
      addFindingPhoto(findingId, fotoUrl),
    onSuccess: () =>
      qc.invalidateQueries({ queryKey: ['findings', orderId] }),
  });
}

export function useAddPart(orderId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ findingId, data }: { findingId: string; data: PartCreatePayload }) =>
      addPart(findingId, data),
    onSuccess: () =>
      qc.invalidateQueries({ queryKey: ['findings', orderId] }),
  });
}
