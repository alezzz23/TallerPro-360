import { apiGet, apiPost, apiPut } from '@/services/api-client';
import type { Customer, Quotation } from '@/types/api';

// ── Payloads ───────────────────────────────────────────────

export interface QuotationItemPayload {
  finding_id: string;
  part_id?: string | null;
  descripcion: string;
  mano_obra: number;
  costo_repuesto: number;
}

export interface QuotationCreatePayload {
  items: QuotationItemPayload[];
  impuestos_pct: number;
  shop_supplies_pct: number;
  descuento: number;
}

export interface DiscountPayload {
  descuento: number;
  razon?: string;
}

// ── Quotation (nested under orders) ────────────────────────

export async function fetchOrderQuotation(orderId: string) {
  return apiGet<Quotation>(`/orders/${orderId}/quotation`);
}

export async function createQuotation(orderId: string, data: QuotationCreatePayload) {
  return apiPost<Quotation>(`/orders/${orderId}/quotation`, data);
}

// ── Quotation (standalone) ─────────────────────────────────

export async function fetchQuotation(quotationId: string) {
  return apiGet<Quotation>(`/quotations/${quotationId}`);
}

export async function applyDiscount(quotationId: string, data: DiscountPayload) {
  return apiPut<Quotation>(`/quotations/${quotationId}/discount`, data);
}

export async function sendQuotation(quotationId: string) {
  return apiPost<Quotation>(`/quotations/${quotationId}/send`);
}

export async function approveQuotation(quotationId: string) {
  return apiPost<Quotation>(`/quotations/${quotationId}/approve`);
}

export async function rejectQuotation(quotationId: string, razon?: string) {
  return apiPost<Quotation>(`/quotations/${quotationId}/reject`, { razon });
}

// ── Customer ───────────────────────────────────────────────

export async function fetchCustomer(customerId: string) {
  return apiGet<Customer>(`/customers/${customerId}`);
}
