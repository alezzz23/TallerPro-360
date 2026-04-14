import { useEffect, useRef } from 'react';
import { Animated, StyleSheet, Text, View, Platform } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

import { useNetworkStore } from '@/stores/network-store';
import { getSyncQueueCount } from '@/services/offline-db';
import { Fonts, Semantic, Spacing, TypeScale } from '@/constants/theme';

const BANNER_BG = '#18212C';
const BANNER_TEXT = Semantic.primary;
const BANNER_HEIGHT = 44;

export function NetworkBanner() {
  const isOnline = useNetworkStore((s) => s.isOnline);
  const translateY = useRef(new Animated.Value(-BANNER_HEIGHT)).current;
  const pendingCount = isOnline ? 0 : getSyncQueueCount();

  useEffect(() => {
    Animated.timing(translateY, {
      toValue: isOnline ? -BANNER_HEIGHT : 0,
      duration: 300,
      useNativeDriver: true,
    }).start();
  }, [isOnline, translateY]);

  // Don't render anything on web — SQLite is not available
  if (Platform.OS === 'web') return null;

  return (
    <Animated.View
      style={[styles.container, { transform: [{ translateY }] }]}
      accessibilityRole="alert"
      accessibilityLiveRegion="polite"
    >
      <View style={styles.inner}>
        <Ionicons name="cloud-offline-outline" size={18} color={BANNER_TEXT} />
        <Text style={styles.text}>
          {pendingCount > 0
            ? `Sin conexión — ${pendingCount} operación${pendingCount > 1 ? 'es' : ''} pendiente${pendingCount > 1 ? 's' : ''}`
            : 'Sin conexión — modo offline'}
        </Text>
      </View>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    height: BANNER_HEIGHT,
    backgroundColor: BANNER_BG,
    zIndex: 1000,
    justifyContent: 'center',
    borderBottomWidth: 1,
    borderBottomColor: Semantic.borderStrong,
  },
  inner: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: Spacing.sm,
    paddingHorizontal: Spacing.md,
  },
  text: {
    color: BANNER_TEXT,
    fontSize: TypeScale.label,
    fontFamily: Fonts.bold,
  },
});
