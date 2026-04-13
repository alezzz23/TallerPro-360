import { useQuery } from '@tanstack/react-query';

import { fetchOrders, fetchOrder, fetchVehicle } from '@/services/orders';
import type { OrderFilters } from '@/services/orders';
import { useNetworkStore } from '@/stores/network-store';
import {
  cacheOrders,
  cacheOrder,
  cacheVehicle,
  getCachedOrders,
  getCachedOrder,
  getCachedVehicle,
} from '@/services/offline-db';

/**
 * Offline-aware version of `useOrders`.
 * Online  → fetches from API and caches to SQLite.
 * Offline → returns cached data from SQLite.
 */
export function useOfflineOrders(filters?: OrderFilters) {
  const isOnline = useNetworkStore((s) => s.isOnline);

  return useQuery({
    queryKey: ['orders', filters],
    queryFn: async () => {
      if (!isOnline) {
        return { items: getCachedOrders(), total: 0, limit: 100, offset: 0 };
      }
      const response = await fetchOrders(filters);
      cacheOrders(response.items);
      return response;
    },
    // Keep stale data visible while offline
    staleTime: isOnline ? 1000 * 60 * 2 : Infinity,
  });
}

/**
 * Offline-aware version of `useOrder`.
 */
export function useOfflineOrder(id: string) {
  const isOnline = useNetworkStore((s) => s.isOnline);

  return useQuery({
    queryKey: ['order', id],
    queryFn: async () => {
      if (!isOnline) {
        const cached = getCachedOrder(id);
        if (cached) return cached;
        throw new Error('Order not available offline');
      }
      const order = await fetchOrder(id);
      cacheOrder(order);
      return order;
    },
    enabled: !!id,
    staleTime: isOnline ? 1000 * 60 * 2 : Infinity,
  });
}

/**
 * Offline-aware version of `useVehicle`.
 */
export function useOfflineVehicle(id: string) {
  const isOnline = useNetworkStore((s) => s.isOnline);

  return useQuery({
    queryKey: ['vehicle', id],
    queryFn: async () => {
      if (!isOnline) {
        const cached = getCachedVehicle(id);
        if (cached) return cached;
        throw new Error('Vehicle not available offline');
      }
      const vehicle = await fetchVehicle(id);
      cacheVehicle(vehicle);
      return vehicle;
    },
    enabled: !!id,
    staleTime: isOnline ? 1000 * 60 * 2 : Infinity,
  });
}
