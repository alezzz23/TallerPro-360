import { useNetworkStore } from '@/stores/network-store';
import { getSyncQueueCount } from '@/services/offline-db';

export function useNetwork() {
  const isOnline = useNetworkStore((s) => s.isOnline);
  return { isOnline };
}

export function usePendingSyncCount() {
  const isOnline = useNetworkStore((s) => s.isOnline);
  // Re-read count whenever online status changes (triggers re-render)
  const count = getSyncQueueCount();
  return { count, isOnline };
}
