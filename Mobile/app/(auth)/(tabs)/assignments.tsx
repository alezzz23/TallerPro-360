import {
  ActivityIndicator,
  FlatList,
  Pressable,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

import { useOrders, useVehicle } from '@/hooks/use-orders';
import { Fonts, Radius, Semantic, Shadows, Spacing, StatusColors, TypeScale } from '@/constants/theme';
import type { ServiceOrder } from '@/types/api';

export default function AssignmentsScreen() {
  const router = useRouter();
  const { data, isLoading } = useOrders({ estado: 'DIAGNOSTICO' });
  const orders = data?.items ?? [];

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Mis Asignaciones</Text>
        <View style={styles.countBadge}>
          <Text style={styles.countBadgeText}>{orders.length}</Text>
        </View>
      </View>
      <Text style={styles.subtitle}>Órdenes listas para diagnóstico</Text>

      {isLoading ? (
        <View style={styles.center}>
          <ActivityIndicator size="large" color={StatusColors.DIAGNOSTICO} />
        </View>
      ) : (
        <FlatList
          data={orders}
          keyExtractor={(o) => o.id}
          renderItem={({ item }) => (
            <AssignmentCard
              order={item}
              onPress={() =>
                router.push(`/(auth)/diagnosis/${item.id}`)
              }
            />
          )}
          contentContainerStyle={styles.list}
          ListEmptyComponent={
            <View style={styles.center}>
              <Ionicons name="clipboard-outline" size={48} color={Semantic.textMuted} />
              <Text style={styles.emptyText}>
                No hay órdenes en diagnóstico
              </Text>
            </View>
          }
        />
      )}
    </View>
  );
}

function AssignmentCard({
  order,
  onPress,
}: {
  order: ServiceOrder;
  onPress: () => void;
}) {
  const { data: vehicle } = useVehicle(order.vehicle_id);

  return (
    <Pressable
      style={({ pressed }) => [styles.card, pressed && styles.cardPressed]}
      onPress={onPress}
    >
      <View style={styles.cardHeader}>
        <Text style={styles.placa}>{vehicle?.placa ?? '···'}</Text>
        <View style={styles.statusDot} />
      </View>
      {vehicle && (
        <Text style={styles.vehicleInfo}>
          {vehicle.marca} {vehicle.modelo}
        </Text>
      )}
      {order.motivo_ingreso && (
        <Text style={styles.motivo} numberOfLines={2}>
          {order.motivo_ingreso}
        </Text>
      )}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Semantic.background,
    paddingTop: 60,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: Spacing.lg,
    gap: Spacing.sm,
  },
  title: {
    fontSize: TypeScale.title,
    fontFamily: Fonts.display,
    color: Semantic.onSurface,
  },
  subtitle: {
    fontSize: TypeScale.label,
    color: Semantic.secondary,
    fontFamily: Fonts.medium,
    paddingHorizontal: Spacing.lg,
    marginTop: Spacing.xs,
    marginBottom: Spacing.md,
  },
  countBadge: {
    minWidth: 40,
    height: 32,
    borderRadius: Radius.pill,
    paddingHorizontal: Spacing.sm,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Semantic.surface,
    borderWidth: 1,
    borderColor: Semantic.borderLight,
  },
  countBadgeText: {
    color: Semantic.primary,
    fontSize: TypeScale.caption,
    fontFamily: Fonts.bold,
  },
  list: {
    paddingHorizontal: Spacing.md,
    paddingBottom: Spacing.xxl,
  },
  center: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingTop: Spacing.xxl * 2,
  },
  emptyText: {
    fontSize: TypeScale.body,
    fontFamily: Fonts.bold,
    color: Semantic.textMuted,
    marginTop: Spacing.md,
  },
  card: {
    backgroundColor: Semantic.surface,
    borderRadius: Radius.lg,
    borderWidth: 1,
    borderColor: Semantic.borderLight,
    padding: Spacing.md,
    marginBottom: Spacing.sm,
    ...Shadows.elevated,
  },
  cardPressed: {
    ...Shadows.none,
    backgroundColor: Semantic.surfacePress,
    transform: [{ scale: 0.985 }],
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  placa: {
    fontSize: TypeScale.body,
    fontFamily: Fonts.bold,
    color: Semantic.onSurface,
  },
  statusDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: StatusColors.DIAGNOSTICO,
  },
  vehicleInfo: {
    fontSize: TypeScale.label,
    color: Semantic.secondary,
    marginTop: 2,
    fontFamily: Fonts.medium,
  },
  motivo: {
    fontSize: TypeScale.caption,
    color: Semantic.textMuted,
    marginTop: Spacing.xs,
    lineHeight: 18,
    fontFamily: Fonts.medium,
  },
});
