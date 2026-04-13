import { apiGet, apiPost, apiPut } from '@/services/api-client';
import type { DiagnosticFinding, Part, Technician } from '@/types/api';

// ── Finding payloads ───────────────────────────────────────

export interface FindingCreatePayload {
  technician_id: string;
  motivo_ingreso: string;
  descripcion?: string;
  tiempo_estimado?: number;
  es_hallazgo_adicional: boolean;
  es_critico_seguridad: boolean;
}

export interface FindingUpdatePayload {
  technician_id?: string;
  descripcion?: string;
  tiempo_estimado?: number;
  es_critico_seguridad?: boolean;
}

export interface PartCreatePayload {
  nombre: string;
  origen: 'STOCK' | 'PEDIDO';
  costo: number;
  margen: number;
  proveedor?: string;
}

// ── Findings (nested under orders) ─────────────────────────

export async function fetchOrderFindings(orderId: string) {
  return apiGet<DiagnosticFinding[]>(`/orders/${orderId}/findings`);
}

export async function createFinding(orderId: string, data: FindingCreatePayload) {
  return apiPost<DiagnosticFinding>(`/orders/${orderId}/findings`, data);
}

// ── Findings (standalone) ──────────────────────────────────

export async function updateFinding(findingId: string, data: FindingUpdatePayload) {
  return apiPut<DiagnosticFinding>(`/findings/${findingId}`, data);
}

export async function addFindingPhoto(findingId: string, fotoUrl: string) {
  return apiPost<{ foto_url: string }>(`/findings/${findingId}/photos`, {
    foto_url: fotoUrl,
  });
}

// ── Parts ──────────────────────────────────────────────────

export async function fetchParts(findingId: string) {
  return apiGet<Part[]>(`/findings/${findingId}/parts`);
}

export async function addPart(findingId: string, data: PartCreatePayload) {
  return apiPost<Part>(`/findings/${findingId}/parts`, data);
}

// ── Technicians ────────────────────────────────────────────

export async function fetchTechnicians() {
  return apiGet<Technician[]>('/users/technicians');
}
