import { ActivityIndicator, FlatList, Pressable, StyleSheet, Text, View } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { Image } from 'expo-image';

import { useOrder, useVehicle } from '@/hooks/use-orders';
import { useOrderFindings, useTechnicians } from '@/hooks/use-diagnosis';
import { FindingCard } from '@/components/diagnosis/finding-card';
import { STATUS_LABELS } from '@/constants/status';
import { EditorialImages } from '@/constants/visuals';
import { Fonts, Semantic, Shadows, Radius, Spacing, StatusColors, TypeScale } from '@/constants/theme';

export default function OrderDiagnosisScreen() {
  const { orderId } = useLocalSearchParams<{ orderId: string }>();
  const router = useRouter();

  const { data: order } = useOrder(orderId);
  const { data: vehicle } = useVehicle(order?.vehicle_id ?? '');
  const { data: findings, isLoading } = useOrderFindings(orderId);
  const { data: technicians } = useTechnicians();

  const techMap = new Map(technicians?.map((t) => [t.id, t.nombre]));
  const findingCount = findings?.length ?? 0;
  const canCreateQuotation =
    !!order &&
    (order.estado === 'DIAGNOSTICO' || order.estado === 'APROBACION') &&
    findingCount > 0;

  return (
    <View style={styles.container}>
      {isLoading ? (
        <View style={styles.center}>
          <ActivityIndicator size="large" color={Semantic.primary} />
        </View>
      ) : (
        <FlatList
          data={findings}
          keyExtractor={(f) => f.id}
          showsVerticalScrollIndicator={false}
          renderItem={({ item }) => (
            <FindingCard
              finding={item}
              technicianName={techMap.get(item.technician_id)}
            />
          )}
          contentContainerStyle={styles.list}
          ListHeaderComponent={
            <View style={styles.listHeader}>
              <View style={styles.vehicleHeader}>
                <Image
                  source={EditorialImages.diagnosis}
                  style={styles.vehicleHeaderImage}
                  contentFit="cover"
                  transition={250}
                />
                <View style={styles.vehicleHeaderOverlay} />
                <View style={styles.headerTopRow}>
                  <View style={styles.headerStatusPill}>
                    <View style={styles.headerStatusDot} />
                    <Text style={styles.headerStatusText}>
                      {order ? STATUS_LABELS[order.estado] : 'Diagnóstico'}
                    </Text>
                  </View>
                  <View style={styles.headerCountPill}>
                    <Text style={styles.headerCountText}>{findingCount} hallazgos</Text>
                  </View>
                </View>

                <Text style={styles.placa}>{vehicle?.placa ?? 'Orden en proceso'}</Text>
                <Text style={styles.vehicleInfo}>
                  {vehicle
                    ? `${vehicle.marca} ${vehicle.modelo}${vehicle.color ? ` · ${vehicle.color}` : ''}`
                    : 'Sin vehículo cargado'}
                </Text>
                {order?.motivo_ingreso ? (
                  <Text style={styles.motivo}>{order.motivo_ingreso}</Text>
                ) : null}
              </View>
            </View>
          }
          ListEmptyComponent={
            <View style={styles.emptyCard}>
              <View style={styles.emptyIconWrap}>
                <Ionicons name="sparkles-outline" size={28} color={Semantic.primary} />
              </View>
              <Text style={styles.emptyText}>
                Sin hallazgos registrados aún
              </Text>
              <Text style={styles.emptyHint}>
                Agrega el primer hallazgo para documentar el diagnóstico con mejor trazabilidad.
              </Text>
            </View>
          }
        />
      )}

      <View style={styles.fabRow}>
        {canCreateQuotation && (
          <Pressable
            style={({ pressed }) => [
              styles.fab,
              styles.fabQuotation,
              pressed && styles.fabPressed,
            ]}
            onPress={() =>
              router.push(`/(auth)/quotation/create/${orderId}`)
            }
          >
            <View style={styles.fabContent}>
              <Ionicons name="cash-outline" size={18} color={Semantic.onPrimary} />
              <Text style={styles.fabText}>Crear cotización</Text>
            </View>
          </Pressable>
        )}

        <Pressable
          style={({ pressed }) => [
            styles.fab,
            pressed && styles.fabPressed,
          ]}
          onPress={() =>
            router.push(
              `/(auth)/diagnosis/new-finding?orderId=${orderId}&additional=false`,
            )
          }
        >
          <View style={styles.fabContent}>
            <Ionicons name="add" size={18} color={Semantic.onPrimary} />
            <Text style={styles.fabText}>Nuevo hallazgo</Text>
          </View>
        </Pressable>

        <Pressable
          style={({ pressed }) => [
            styles.fab,
            styles.fabSecondary,
            pressed && styles.fabSecondaryPressed,
          ]}
          onPress={() =>
            router.push(
              `/(auth)/diagnosis/new-finding?orderId=${orderId}&additional=true`,
            )
          }
        >
          <View style={styles.fabContent}>
            <Ionicons name="flash-outline" size={18} color={Semantic.onSurface} />
            <Text style={[styles.fabText, styles.fabSecondaryText]}>Hallazgo adicional</Text>
          </View>
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
  listHeader: {
    marginBottom: Spacing.lg,
  },
  vehicleHeader: {
    minHeight: 238,
    borderRadius: Radius.xl,
    overflow: 'hidden',
    padding: Spacing.lg,
    justifyContent: 'space-between',
    ...Shadows.glow,
  },
  vehicleHeaderImage: {
    ...StyleSheet.absoluteFillObject,
  },
  vehicleHeaderOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(14,19,26,0.52)',
  },
  headerTopRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: Spacing.sm,
  },
  headerStatusPill: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.xs,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    borderRadius: Radius.pill,
    backgroundColor: 'rgba(196,122,58,0.18)',
    borderWidth: 1,
    borderColor: 'rgba(224,154,91,0.34)',
  },
  headerStatusDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: StatusColors.DIAGNOSTICO,
  },
  headerStatusText: {
    fontSize: TypeScale.caption,
    color: '#FFF8F0',
    fontFamily: Fonts.bold,
  },
  headerCountPill: {
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    borderRadius: Radius.pill,
    backgroundColor: 'rgba(255,248,240,0.12)',
    borderWidth: 1,
    borderColor: 'rgba(255,248,240,0.14)',
  },
  headerCountText: {
    fontSize: TypeScale.caption,
    color: '#FFF8F0',
    fontFamily: Fonts.medium,
  },
  placa: {
    fontSize: TypeScale.title,
    fontFamily: Fonts.display,
    color: '#FFF8F0',
  },
  vehicleInfo: {
    fontSize: TypeScale.label,
    color: 'rgba(255,248,240,0.78)',
    marginTop: Spacing.xs,
    fontFamily: Fonts.medium,
  },
  motivo: {
    fontSize: TypeScale.body,
    color: 'rgba(255,248,240,0.86)',
    marginTop: Spacing.md,
    fontFamily: Fonts.medium,
    lineHeight: 24,
  },
  list: {
    padding: Spacing.md,
    paddingBottom: 220,
  },
  center: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingTop: Spacing.xxl * 2,
  },
  emptyCard: {
    backgroundColor: Semantic.surface,
    borderRadius: Radius.xl,
    padding: Spacing.xl,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: Semantic.borderLight,
    ...Shadows.elevated,
  },
  emptyIconWrap: {
    width: 64,
    height: 64,
    borderRadius: 32,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Semantic.primaryMuted,
    marginBottom: Spacing.md,
  },
  emptyText: {
    fontSize: TypeScale.subtitle,
    fontFamily: Fonts.bold,
    color: Semantic.onSurface,
    textAlign: 'center',
  },
  emptyHint: {
    fontSize: TypeScale.body,
    color: Semantic.secondary,
    textAlign: 'center',
    marginTop: Spacing.sm,
    fontFamily: Fonts.medium,
    lineHeight: 24,
  },
  fabRow: {
    position: 'absolute',
    bottom: Spacing.lg,
    left: Spacing.md,
    right: Spacing.md,
    gap: Spacing.sm,
    padding: Spacing.sm,
    backgroundColor: 'rgba(24,33,44,0.96)',
    borderRadius: Radius.xl,
    borderWidth: 1,
    borderColor: Semantic.border,
    ...Shadows.elevated,
  },
  fab: {
    backgroundColor: Semantic.primary,
    paddingVertical: Spacing.md,
    borderRadius: Radius.lg,
    alignItems: 'center',
    ...Shadows.soft,
  },
  fabSecondary: {
    backgroundColor: Semantic.surface,
    borderWidth: 1,
    borderColor: Semantic.border,
    ...Shadows.soft,
  },
  fabContent: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.sm,
  },
  fabPressed: {
    ...Shadows.none,
    backgroundColor: Semantic.primaryDark,
    transform: [{ scale: 0.985 }],
  },
  fabSecondaryPressed: {
    ...Shadows.none,
    backgroundColor: Semantic.surfacePress,
    transform: [{ scale: 0.985 }],
  },
  fabText: {
    color: Semantic.onPrimary,
    fontSize: TypeScale.body,
    fontFamily: Fonts.bold,
  },
  fabSecondaryText: {
    color: Semantic.onSurface,
  },
  fabQuotation: {
    backgroundColor: Semantic.primary,
  },
});
