import { apiGet } from '@/services/api-client';
import type { PaginatedResponse, ServiceOrder, Vehicle } from '@/types/api';

export interface OrderFilters {
  estado?: string;
  vehicle_id?: string;
  advisor_id?: string;
  limit?: number;
  offset?: number;
}

export async function fetchOrders(filters?: OrderFilters) {
  const params = new URLSearchParams();
  if (filters?.estado) params.set('estado', filters.estado);
  if (filters?.vehicle_id) params.set('vehicle_id', filters.vehicle_id);
  if (filters?.advisor_id) params.set('advisor_id', filters.advisor_id);
  params.set('limit', String(filters?.limit ?? 100));
  params.set('offset', String(filters?.offset ?? 0));

  const qs = params.toString();
  return apiGet<PaginatedResponse<ServiceOrder>>(`/orders?${qs}`);
}

export async function fetchOrder(id: string) {
  return apiGet<ServiceOrder>(`/orders/${id}`);
}

export async function fetchVehicle(id: string) {
  return apiGet<Vehicle>(`/vehicles/${id}`);
}
