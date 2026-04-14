import { DarkTheme, ThemeProvider } from '@react-navigation/native';
import { QueryClientProvider } from '@tanstack/react-query';
import {
  Nunito_400Regular,
  Nunito_600SemiBold,
  Nunito_700Bold,
  Nunito_800ExtraBold,
  useFonts,
} from '@expo-google-fonts/nunito';
import { Stack } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { StatusBar } from 'expo-status-bar';
import { useEffect, useRef } from 'react';
import { View, StyleSheet } from 'react-native';
import 'react-native-reanimated';

import { NetworkBanner } from '@/components/network-banner';
import { Semantic } from '@/constants/theme';
import { initDatabase } from '@/services/offline-db';
import { subscribeToNetwork } from '@/services/network';
import { processSyncQueue } from '@/services/sync-engine';
import { queryClient } from '@/services/query-client';
import { useAuthStore } from '@/stores/auth-store';

void SplashScreen.preventAutoHideAsync();

const navigationTheme = {
  ...DarkTheme,
  colors: {
    ...DarkTheme.colors,
    background: Semantic.background,
    card: Semantic.surface,
    text: Semantic.onSurface,
    border: Semantic.border,
    primary: Semantic.primary,
    notification: Semantic.primary,
  },
};

export default function RootLayout() {
  const restoreSession = useAuthStore((s) => s.restoreSession);
  const dbInitialized = useRef(false);
  const [fontsLoaded, fontError] = useFonts({
    Nunito_400Regular,
    Nunito_600SemiBold,
    Nunito_700Bold,
    Nunito_800ExtraBold,
  });

  useEffect(() => {
    if (fontsLoaded || fontError) {
      SplashScreen.hideAsync();
    }
  }, [fontError, fontsLoaded]);

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

  if (!fontsLoaded && !fontError) {
    return null;
  }

  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider value={navigationTheme}>
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
  root: { flex: 1, backgroundColor: Semantic.background },
});
