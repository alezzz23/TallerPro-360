import { apiClient, apiGet, apiPost, apiPut } from '@/services/api-client';
import type {
  AnguloFoto,
  DamageRecord,
  MediaUploadResponse,
  PaginatedResponse,
  PerimeterPhoto,
  ReceptionChecklist,
  ServiceOrder,
  Vehicle,
} from '@/types/api';

// ── Vehicle search ─────────────────────────────────────────
export async function searchVehicles(query: string) {
  return apiGet<PaginatedResponse<Vehicle>>(`/vehicles?q=${encodeURIComponent(query)}&limit=20`);
}

// ── Service Order ──────────────────────────────────────────
export interface CreateOrderPayload {
  vehicle_id: string;
  advisor_id: string;
  kilometraje_ingreso?: number;
  motivo_ingreso?: string;
}

export async function createOrder(data: CreateOrderPayload) {
  return apiPost<ServiceOrder>('/orders', data);
}

// ── Reception Checklist ────────────────────────────────────
export interface ChecklistPayload {
  nivel_aceite?: string;
  nivel_refrigerante?: string;
  nivel_frenos?: string;
  llanta_repuesto: boolean;
  kit_carretera: boolean;
  botiquin: boolean;
  extintor: boolean;
  documentos_recibidos?: string;
  firma_cliente_url?: string;
}

export async function saveChecklist(orderId: string, data: ChecklistPayload) {
  return apiPost<ReceptionChecklist>(`/orders/${orderId}/reception-checklist`, data);
}

// ── Damage Records ─────────────────────────────────────────
export interface DamagePayload {
  ubicacion: string;
  descripcion?: string;
  foto_url?: string;
  reconocido_por_cliente: boolean;
}

export async function addDamage(orderId: string, data: DamagePayload) {
  return apiPost<DamageRecord>(`/orders/${orderId}/damages`, data);
}

export async function getDamages(orderId: string) {
  return apiGet<DamageRecord[]>(`/orders/${orderId}/damages`);
}

// ── Perimeter Photos ───────────────────────────────────────
export async function uploadPerimeterPhoto(
  orderId: string,
  angulo: AnguloFoto,
  fotoUrl: string,
) {
  return apiPost<PerimeterPhoto>(`/orders/${orderId}/perimeter-photos`, {
    angulo,
    foto_url: fotoUrl,
  });
}

export async function getPerimeterPhotos(orderId: string) {
  return apiGet<PerimeterPhoto[]>(`/orders/${orderId}/perimeter-photos`);
}

// ── Client Signature ───────────────────────────────────────
export async function submitSignature(orderId: string, firmaUrl: string) {
  return apiPost<{ firma_cliente_url: string }>(`/orders/${orderId}/client-signature`, {
    firma_cliente_url: firmaUrl,
  });
}

// ── Advance Order ──────────────────────────────────────────
export async function advanceOrder(orderId: string) {
  return apiPut<ServiceOrder>(`/orders/${orderId}/advance`);
}

// ── File Upload (multipart) ────────────────────────────────
export async function uploadMedia(
  uri: string,
  category: 'reception' | 'diagnosis' | 'signature',
) {
  const formData = new FormData();
  const filename = uri.split('/').pop() || 'photo.jpg';
  formData.append('file', { uri, name: filename, type: 'image/jpeg' } as any);
  formData.append('category', category);
  const { data } = await apiClient.post<MediaUploadResponse>('/uploads', formData, {
    headers: { 'Content-Type': 'multipart/form-data' },
  });
  return data;
}
