import { apiClient } from '@/services/api-client';
import {
  getPendingSyncItems,
  markSyncing,
  markSynced,
  markFailed,
  removeSynced,
  addToSyncQueue,
} from '@/services/offline-db';
import { useNetworkStore } from '@/stores/network-store';
import { queryClient } from '@/services/query-client';

let isSyncing = false;

/**
 * Process all pending items in the sync queue.
 * Uses last-write-wins: 409 conflicts are dropped and remote state is re-fetched.
 */
export async function processSyncQueue(): Promise<void> {
  if (isSyncing) return;
  if (!useNetworkStore.getState().isOnline) return;

  isSyncing = true;

  try {
    const items = getPendingSyncItems();

    for (const item of items) {
      markSyncing(item.id);

      try {
        const payload = JSON.parse(item.payload);

        await apiClient.request({
          url: item.endpoint,
          method: item.method,
          data: item.method !== 'DELETE' ? payload : undefined,
        });

        markSynced(item.id);
      } catch (error: unknown) {
        const status =
          error && typeof error === 'object' && 'response' in error
            ? (error as { response?: { status?: number } }).response?.status
            : undefined;

        if (status === 409) {
          // Last-write-wins: drop conflicting mutation, server state takes precedence
          markSynced(item.id);
        } else {
          markFailed(item.id);
        }
      }
    }

    // Clean up completed items
    removeSynced();

    // Invalidate stale queries so UI picks up server state
    await queryClient.invalidateQueries();
  } finally {
    isSyncing = false;
  }
}

/**
 * Enqueue a mutation for offline processing.
 * If currently online, attempts immediate sync.
 */
export async function enqueueMutation(
  key: string,
  endpoint: string,
  method: string,
  payload: unknown,
): Promise<void> {
  addToSyncQueue(key, endpoint, method, payload);

  if (useNetworkStore.getState().isOnline) {
    await processSyncQueue();
  }
}
