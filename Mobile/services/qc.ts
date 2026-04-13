import { apiGet, apiPost, apiPut } from '@/services/api-client';
import type { QualityCheck, ReceptionChecklist } from '@/types/api';

// ── Payloads ───────────────────────────────────────────────

export interface QCCreatePayload {
  inspector_id: string;
  items_verificados: Record<string, boolean>;
  kilometraje_salida?: number | null;
  nivel_aceite_salida?: string | null;
  nivel_refrigerante_salida?: string | null;
  nivel_frenos_salida?: string | null;
  aprobado?: boolean;
}

// ── QC endpoints ───────────────────────────────────────────

export async function createOrUpdateQC(orderId: string, data: QCCreatePayload) {
  return apiPost<QualityCheck>(`/orders/${orderId}/qc`, data);
}

export async function fetchQC(orderId: string) {
  return apiGet<QualityCheck>(`/orders/${orderId}/qc`);
}

export async function approveQC(orderId: string) {
  return apiPut<QualityCheck>(`/orders/${orderId}/qc/approve`);
}

// ── Reception checklist (for ingreso comparison) ───────────

export async function fetchReceptionChecklist(orderId: string) {
  return apiGet<ReceptionChecklist>(`/orders/${orderId}/reception-checklist`);
}
