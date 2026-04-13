import { ActivityIndicator, FlatList, Pressable, StyleSheet, Text, View } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

import { useOrder, useVehicle } from '@/hooks/use-orders';
import { useOrderFindings, useTechnicians } from '@/hooks/use-diagnosis';
import { FindingCard } from '@/components/diagnosis/finding-card';
import { Semantic, Shadows, Radius, Spacing, StatusColors, TypeScale } from '@/constants/theme';

export default function OrderDiagnosisScreen() {
  const { orderId } = useLocalSearchParams<{ orderId: string }>();
  const router = useRouter();

  const { data: order } = useOrder(orderId);
  const { data: vehicle } = useVehicle(order?.vehicle_id ?? '');
  const { data: findings, isLoading } = useOrderFindings(orderId);
  const { data: technicians } = useTechnicians();

  const techMap = new Map(technicians?.map((t) => [t.id, t.nombre]));

  return (
    <View style={styles.container}>
      {/* Vehicle header */}
      {vehicle && (
        <View style={styles.vehicleHeader}>
          <Text style={styles.placa}>{vehicle.placa}</Text>
          <Text style={styles.vehicleInfo}>
            {vehicle.marca} {vehicle.modelo}
            {vehicle.color ? ` · ${vehicle.color}` : ''}
          </Text>
          {order?.motivo_ingreso ? (
            <Text style={styles.motivo}>{order.motivo_ingreso}</Text>
          ) : null}
        </View>
      )}

      {/* Findings list */}
      {isLoading ? (
        <View style={styles.center}>
          <ActivityIndicator size="large" color={Semantic.primary} />
        </View>
      ) : (
        <FlatList
          data={findings}
          keyExtractor={(f) => f.id}
          renderItem={({ item }) => (
            <FindingCard
              finding={item}
              technicianName={techMap.get(item.technician_id)}
            />
          )}
          contentContainerStyle={styles.list}
          ListEmptyComponent={
            <View style={styles.center}>
              <Ionicons name="search-outline" size={48} color={Semantic.textMuted} />
              <Text style={styles.emptyText}>
                Sin hallazgos registrados aún
              </Text>
              <Text style={styles.emptyHint}>
                Presione el botón para agregar el primer hallazgo
              </Text>
            </View>
          }
        />
      )}

      {/* FABs */}
      <View style={styles.fabRow}>
        {/* Cotización button — visible when there are findings */}
        {order && (order.estado === 'DIAGNOSTICO' || order.estado === 'APROBACION') && findings && findings.length > 0 && (
          <Pressable
            style={({ pressed }) => [
              styles.fab,
              styles.fabQuotation,
              pressed && { ...Shadows.none, backgroundColor: '#111111', transform: [{ scale: 0.97 }] },
            ]}
            onPress={() =>
              router.push(`/(auth)/quotation/create/${orderId}`)
            }
          >
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
              <Ionicons name="cash-outline" size={18} color={Semantic.onPrimary} />
              <Text style={[styles.fabText, { color: Semantic.onPrimary }]}>Crear Cotización</Text>
            </View>
          </Pressable>
        )}

        <Pressable
          style={({ pressed }) => [
            styles.fab,
            pressed && { ...Shadows.none, backgroundColor: '#111111', transform: [{ scale: 0.97 }] },
          ]}
          onPress={() =>
            router.push(
              `/(auth)/diagnosis/new-finding?orderId=${orderId}&additional=false`,
            )
          }
        >
          <Text style={styles.fabText}>+ Nuevo Hallazgo</Text>
        </Pressable>

        <Pressable
          style={({ pressed }) => [
            styles.fab,
            styles.fabSecondary,
            pressed && { ...Shadows.none, backgroundColor: '#111111', transform: [{ scale: 0.97 }] },
          ]}
          onPress={() =>
            router.push(
              `/(auth)/diagnosis/new-finding?orderId=${orderId}&additional=true`,
            )
          }
        >
          <Text style={[styles.fabText, styles.fabSecondaryText]}>
            + Hallazgo Adicional
          </Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Semantic.background,
  },
  vehicleHeader: {
    backgroundColor: Semantic.surface,
    padding: Spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: Semantic.borderLight,
    borderTopWidth: 1,
    borderTopColor: Semantic.borderLight,
    borderLeftWidth: 1,
    borderLeftColor: Semantic.borderLight,
    ...Shadows.extruded,
  },
  placa: {
    fontSize: TypeScale.title,
    fontWeight: '800',
    color: Semantic.onSurface,
  },
  vehicleInfo: {
    fontSize: TypeScale.label,
    color: Semantic.secondary,
    marginTop: 2,
  },
  motivo: {
    fontSize: TypeScale.label,
    color: Semantic.textMuted,
    marginTop: Spacing.xs,
    fontWeight: '500',
  },
  list: {
    padding: Spacing.md,
    paddingBottom: 120,
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
    color: Semantic.textMuted,
    textAlign: 'center',
    marginTop: Spacing.md,
  },
  emptyHint: {
    fontSize: TypeScale.label,
    color: Semantic.textMuted,
    textAlign: 'center',
    marginTop: Spacing.xs,
  },
  fabRow: {
    position: 'absolute',
    bottom: Spacing.lg,
    left: Spacing.md,
    right: Spacing.md,
    gap: Spacing.sm,
  },
  fab: {
    backgroundColor: Semantic.primary,
    paddingVertical: Spacing.md,
    borderRadius: Radius.pill,
    alignItems: 'center',
    ...Shadows.extruded,
  },
  fabSecondary: {
    backgroundColor: Semantic.surface,
    borderWidth: 1,
    borderColor: Semantic.border,
    ...Shadows.soft,
  },
  fabText: {
    color: Semantic.onPrimary,
    fontSize: TypeScale.body,
    fontWeight: '700',
  },
  fabSecondaryText: {
    color: Semantic.onSurface,
  },
  fabQuotation: {
    backgroundColor: Semantic.primary,
  },
});
