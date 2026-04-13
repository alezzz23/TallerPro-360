import { DarkTheme, ThemeProvider } from '@react-navigation/native';
import { QueryClientProvider } from '@tanstack/react-query';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useEffect, useRef } from 'react';
import { View, StyleSheet } from 'react-native';
import 'react-native-reanimated';

import { NetworkBanner } from '@/components/network-banner';
import { initDatabase } from '@/services/offline-db';
import { subscribeToNetwork } from '@/services/network';
import { processSyncQueue } from '@/services/sync-engine';
import { queryClient } from '@/services/query-client';
import { useAuthStore } from '@/stores/auth-store';

export default function RootLayout() {
  const restoreSession = useAuthStore((s) => s.restoreSession);
  const dbInitialized = useRef(false);

  // Initialise offline infrastructure once
  useEffect(() => {
    if (dbInitialized.current) return;
    dbInitialized.current = true;

    initDatabase().then(() => {
      // After DB is ready, subscribe to network changes
      const unsubscribe = subscribeToNetwork((online) => {
        if (online) {
          processSyncQueue();
        }
      });

      return unsubscribe;
    });
  }, []);

  useEffect(() => {
    restoreSession();
  }, [restoreSession]);

  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider value={DarkTheme}>
        <View style={styles.root}>
          <NetworkBanner />
          <Stack screenOptions={{ headerShown: false }}>
            <Stack.Screen name="login" />
            <Stack.Screen name="(auth)" />
            <Stack.Screen name="modal" options={{ presentation: 'modal', title: 'Modal', headerShown: true }} />
          </Stack>
        </View>
        <StatusBar style="light" />
      </ThemeProvider>
    </QueryClientProvider>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#0A0A0A' },
});
