import { QueryClient, onlineManager } from '@tanstack/react-query';

import { useNetworkStore } from '@/stores/network-store';

// Keep React Query's online manager in sync with our Zustand store
onlineManager.setEventListener((setOnline) => {
  return useNetworkStore.subscribe((state) => {
    setOnline(state.isOnline);
  });
});

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 2, // 2 minutes
      retry: 2,
      refetchOnWindowFocus: false,
    },
    mutations: {
      retry: 0,
      networkMode: 'offlineFirst',
    },
  },
});
