import NetInfo, { type NetInfoState } from '@react-native-community/netinfo';

import { useNetworkStore } from '@/stores/network-store';

/** One-shot check */
export async function isOnline(): Promise<boolean> {
  const state = await NetInfo.fetch();
  return !!(state.isConnected && state.isInternetReachable !== false);
}

/** Subscribe to connectivity changes — returns unsubscribe fn */
export function subscribeToNetwork(
  onStatusChange?: (online: boolean) => void,
): () => void {
  return NetInfo.addEventListener((state: NetInfoState) => {
    const online = !!(state.isConnected && state.isInternetReachable !== false);
    useNetworkStore.getState().setOnline(online);
    onStatusChange?.(online);
  });
}
