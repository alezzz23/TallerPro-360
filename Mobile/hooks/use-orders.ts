import { useQuery } from '@tanstack/react-query';

import { fetchOrders, fetchOrder, fetchVehicle } from '@/services/orders';
import type { OrderFilters } from '@/services/orders';

export function useOrders(filters?: OrderFilters) {
  return useQuery({
    queryKey: ['orders', filters],
    queryFn: () => fetchOrders(filters),
  });
}

export function useOrder(id: string) {
  return useQuery({
    queryKey: ['order', id],
    queryFn: () => fetchOrder(id),
    enabled: !!id,
  });
}

export function useVehicle(id: string) {
  return useQuery({
    queryKey: ['vehicle', id],
    queryFn: () => fetchVehicle(id),
    enabled: !!id,
  });
}
