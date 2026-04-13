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

import { useOrders } from '@/hooks/use-orders';
import { useVehicle } from '@/hooks/use-orders';
import { Spacing, StatusColors, TypeScale, Shadows, Radius } from '@/constants/theme';
import type { ServiceOrder } from '@/types/api';

export default function AssignmentsScreen() {
  const router = useRouter();
  const { data, isLoading } = useOrders({ estado: 'DIAGNOSTICO' });
  const orders = data?.items ?? [];

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Mis Asignaciones</Text>
      <Text style={styles.subtitle}>Órdenes en Diagnóstico</Text>

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
              <Ionicons name="clipboard-outline" size={48} color="#525252" />
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
    backgroundColor: '#0A0A0A',
    paddingTop: 60,
  },
  title: {
    fontSize: TypeScale.title,
    fontWeight: '800',
    color: '#F5F5F5',
    paddingHorizontal: Spacing.lg,
  },
  subtitle: {
    fontSize: TypeScale.label,
    color: '#22C55E',
    fontWeight: '600',
    paddingHorizontal: Spacing.lg,
    marginTop: Spacing.xs,
    marginBottom: Spacing.md,
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
    fontWeight: '600',
    color: '#525252',
    marginTop: Spacing.md,
  },
  card: {
    backgroundColor: '#161616',
    borderRadius: Radius.lg,
    borderLeftWidth: 4,
    borderLeftColor: StatusColors.DIAGNOSTICO,
    padding: Spacing.md,
    marginBottom: Spacing.sm,
    ...Shadows.extruded,
    borderTopWidth: 1,
    borderTopColor: 'rgba(255,255,255,0.06)',
  },
  cardPressed: {
    ...Shadows.none,
    backgroundColor: '#111111',
    transform: [{ scale: 0.97 }],
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  placa: {
    fontSize: TypeScale.body,
    fontWeight: '700',
    color: '#F5F5F5',
  },
  statusDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: StatusColors.DIAGNOSTICO,
  },
  vehicleInfo: {
    fontSize: TypeScale.label,
    color: '#A3A3A3',
    marginTop: 2,
  },
  motivo: {
    fontSize: TypeScale.caption,
    color: '#525252',
    marginTop: Spacing.xs,
    lineHeight: 18,
  },
});
