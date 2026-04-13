import { useMemo } from 'react';
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
import { Spacing, StatusColors, TypeScale, Shadows, Radius } from '@/constants/theme';
import type { ServiceOrder } from '@/types/api';

function OrderRow({ order }: { order: ServiceOrder }) {
  const { data: vehicle } = useVehicle(order.vehicle_id);
  const router = useRouter();
  const isQC = order.estado === 'QC';

  return (
    <Pressable
      style={({ pressed }) => [styles.card, pressed && styles.cardPressed]}
      onPress={() => router.push(`/(auth)/qc/${order.id}`)}
    >
      <View style={styles.cardHeader}>
        <View style={[styles.statusDot, { backgroundColor: StatusColors[order.estado] }]} />
        <Text style={styles.placa}>{vehicle?.placa ?? '···'}</Text>
        <View style={[styles.tag, isQC ? styles.tagQC : styles.tagPending]}>
          <Text style={styles.tagText}>
            {isQC ? 'QC en revisión' : 'Pendiente de QC'}
          </Text>
        </View>
      </View>

      {vehicle && (
        <Text style={styles.vehicleInfo}>
          {vehicle.marca} {vehicle.modelo}
          {vehicle.color ? ` · ${vehicle.color}` : ''}
        </Text>
      )}

      {order.motivo_ingreso ? (
        <Text style={styles.motivo} numberOfLines={1}>
          {order.motivo_ingreso}
        </Text>
      ) : null}
    </Pressable>
  );
}

export default function QCScreen() {
  const { data: repData, isLoading: repLoading } = useOrders({ estado: 'REPARACION' });
  const { data: qcData, isLoading: qcLoading } = useOrders({ estado: 'QC' });

  const orders = useMemo(() => {
    const rep = repData?.items ?? [];
    const qc = qcData?.items ?? [];
    return [...rep, ...qc];
  }, [repData, qcData]);

  const isLoading = repLoading || qcLoading;

  return (
    <View style={styles.container}>
      <View style={styles.headerSection}>
        <Text style={styles.title}>Control de Calidad</Text>
        <Text style={styles.subtitle}>
          {orders.length} orden{orders.length !== 1 ? 'es' : ''}
        </Text>
      </View>

      {isLoading ? (
        <View style={styles.center}>
          <ActivityIndicator size="large" color={StatusColors.QC} />
        </View>
      ) : (
        <FlatList
          data={orders}
          keyExtractor={(o) => o.id}
          renderItem={({ item }) => <OrderRow order={item} />}
          contentContainerStyle={styles.list}
          ListEmptyComponent={
            <View style={styles.center}>
              <Ionicons name="shield-checkmark-outline" size={48} color="#525252" />
              <Text style={styles.emptyText}>No hay órdenes pendientes de QC</Text>
              <Text style={styles.emptyHint}>
                Las órdenes en Reparación aparecerán aquí
              </Text>
            </View>
          }
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0A0A0A',
  },
  headerSection: {
    paddingTop: 60,
    paddingHorizontal: Spacing.lg,
    paddingBottom: Spacing.md,
    backgroundColor: '#161616',
    borderBottomWidth: 1,
    borderBottomColor: '#2A2A2A',
  },
  title: {
    fontSize: TypeScale.title,
    fontWeight: '800',
    color: '#F5F5F5',
  },
  subtitle: {
    fontSize: TypeScale.label,
    color: '#A3A3A3',
    marginTop: 4,
  },
  list: {
    padding: Spacing.md,
    paddingBottom: Spacing.xxl,
  },
  card: {
    backgroundColor: '#161616',
    borderRadius: Radius.lg,
    borderLeftWidth: 4,
    borderLeftColor: StatusColors.QC,
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
    gap: Spacing.sm,
  },
  statusDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
  },
  placa: {
    fontSize: TypeScale.body,
    fontWeight: '700',
    color: '#F5F5F5',
    flex: 1,
  },
  tag: {
    paddingHorizontal: Spacing.sm,
    paddingVertical: 3,
    borderRadius: 10,
  },
  tagPending: {
    backgroundColor: '#14532D',
  },
  tagQC: {
    backgroundColor: '#166534',
  },
  tagText: {
    fontSize: TypeScale.caption,
    fontWeight: '700',
    color: '#F5F5F5',
  },
  vehicleInfo: {
    fontSize: TypeScale.label,
    color: '#A3A3A3',
    marginTop: 4,
    marginLeft: 18,
  },
  motivo: {
    fontSize: TypeScale.caption,
    color: '#525252',
    marginTop: Spacing.xs,
    marginLeft: 18,
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
    textAlign: 'center',
    marginTop: Spacing.md,
  },
  emptyHint: {
    fontSize: TypeScale.label,
    color: '#525252',
    textAlign: 'center',
    marginTop: Spacing.xs,
  },
});
