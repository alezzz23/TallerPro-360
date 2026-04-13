import { apiGet, apiPost, apiPut } from '@/services/api-client';
import type { Invoice, MetodoPago, NPSSurvey, ServiceOrder } from '@/types/api';

// ── Payloads ───────────────────────────────────────────────

export interface InvoiceCreatePayload {
  metodo_pago: MetodoPago;
  es_credito: boolean;
  saldo_pendiente: number;
}

export interface NPSCreatePayload {
  atencion: number;
  instalaciones: number;
  tiempos: number;
  precios: number;
  recomendacion: number;
  comentarios?: string;
}

// ── Invoice endpoints ──────────────────────────────────────

export async function createInvoice(orderId: string, data: InvoiceCreatePayload) {
  return apiPost<Invoice>(`/orders/${orderId}/invoice`, data);
}

export async function fetchInvoice(orderId: string) {
  return apiGet<Invoice>(`/orders/${orderId}/invoice`);
}

// ── NPS endpoints ──────────────────────────────────────────

export async function createNPS(orderId: string, data: NPSCreatePayload) {
  return apiPost<NPSSurvey>(`/orders/${orderId}/nps`, data);
}

export async function fetchNPS(orderId: string) {
  return apiGet<NPSSurvey>(`/orders/${orderId}/nps`);
}

// ── Close order ────────────────────────────────────────────

export async function closeOrder(orderId: string) {
  return apiPut<ServiceOrder>(`/orders/${orderId}/close`);
}
