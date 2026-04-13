import { useNetworkStore } from '@/stores/network-store';
import { enqueueMutation } from '@/services/sync-engine';

interface OfflineMutationOpts<T> {
  mutationKey: string;
  endpoint: string;
  method: 'POST' | 'PUT';
  payload: unknown;
  /** Called when online — performs the real API call */
  onlineFn: () => Promise<T>;
}

/**
 * Wraps an API mutation for offline-first behaviour.
 *
 * - Online  → calls `onlineFn` normally.
 * - Offline → enqueues the operation and returns `null`.
 */
export async function offlineMutation<T>(
  opts: OfflineMutationOpts<T>,
): Promise<T | null> {
  const { mutationKey, endpoint, method, payload, onlineFn } = opts;

  if (useNetworkStore.getState().isOnline) {
    try {
      return await onlineFn();
    } catch {
      // Network may have dropped mid-request — queue for retry
      await enqueueMutation(mutationKey, endpoint, method, payload);
      return null;
    }
  }

  await enqueueMutation(mutationKey, endpoint, method, payload);
  return null;
}
