import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useCallback, useRef, useState } from 'react';

import {
  searchVehicles,
  createOrder,
  saveChecklist,
  addDamage,
  getDamages,
  uploadPerimeterPhoto,
  getPerimeterPhotos,
  submitSignature,
  advanceOrder,
  uploadMedia,
} from '@/services/reception';
import type {
  CreateOrderPayload,
  ChecklistPayload,
  DamagePayload,
} from '@/services/reception';
import type { AnguloFoto } from '@/types/api';

// ── Vehicle Search with debounce ───────────────────────────
export function useVehicleSearch(query: string) {
  return useQuery({
    queryKey: ['vehicles', 'search', query],
    queryFn: () => searchVehicles(query),
    enabled: query.length >= 2,
    staleTime: 30_000,
  });
}

export function useDebouncedSearch(delay = 400) {
  const [debouncedQuery, setDebouncedQuery] = useState('');
  const timerRef = useRef<ReturnType<typeof setTimeout>>(undefined);

  const setQuery = useCallback(
    (text: string) => {
      if (timerRef.current) clearTimeout(timerRef.current);
      timerRef.current = setTimeout(() => setDebouncedQuery(text), delay);
    },
    [delay],
  );

  return { debouncedQuery, setQuery };
}

// ── Create Order ───────────────────────────────────────────
export function useCreateOrder() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateOrderPayload) => createOrder(data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['orders'] }),
  });
}

// ── Checklist ──────────────────────────────────────────────
export function useSaveChecklist() {
  return useMutation({
    mutationFn: ({ orderId, data }: { orderId: string; data: ChecklistPayload }) =>
      saveChecklist(orderId, data),
  });
}

// ── Damages ────────────────────────────────────────────────
export function useDamages(orderId: string) {
  return useQuery({
    queryKey: ['damages', orderId],
    queryFn: () => getDamages(orderId),
    enabled: !!orderId,
  });
}

export function useAddDamage() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ orderId, data }: { orderId: string; data: DamagePayload }) =>
      addDamage(orderId, data),
    onSuccess: (_data, vars) =>
      qc.invalidateQueries({ queryKey: ['damages', vars.orderId] }),
  });
}

// ── Perimeter Photos ───────────────────────────────────────
export function usePerimeterPhotos(orderId: string) {
  return useQuery({
    queryKey: ['perimeterPhotos', orderId],
    queryFn: () => getPerimeterPhotos(orderId),
    enabled: !!orderId,
  });
}

export function useUploadPerimeterPhoto() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({
      orderId,
      angulo,
      fotoUrl,
    }: {
      orderId: string;
      angulo: AnguloFoto;
      fotoUrl: string;
    }) => uploadPerimeterPhoto(orderId, angulo, fotoUrl),
    onSuccess: (_data, vars) =>
      qc.invalidateQueries({ queryKey: ['perimeterPhotos', vars.orderId] }),
  });
}

// ── Signature ──────────────────────────────────────────────
export function useSubmitSignature() {
  return useMutation({
    mutationFn: ({ orderId, firmaUrl }: { orderId: string; firmaUrl: string }) =>
      submitSignature(orderId, firmaUrl),
  });
}

// ── Advance Order ──────────────────────────────────────────
export function useAdvanceOrder() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (orderId: string) => advanceOrder(orderId),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['orders'] }),
  });
}

// ── Upload Media ───────────────────────────────────────────
export function useUploadMedia() {
  return useMutation({
    mutationFn: ({
      uri,
      category,
    }: {
      uri: string;
      category: 'reception' | 'diagnosis' | 'signature';
    }) => uploadMedia(uri, category),
  });
}
