import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useRouter } from 'expo-router';

import { useVehicle } from '@/hooks/use-orders';
import { useOrderQuotation } from '@/hooks/use-quotations';
import { Fonts, Radius, Semantic, Shadows, Spacing, StatusColors, TypeScale } from '@/constants/theme';
import type { ServiceOrder } from '@/types/api';

interface OrderCardProps {
  order: ServiceOrder;
}

function relativeTime(dateStr: string): string {
  const now = Date.now();
  const then = new Date(dateStr).getTime();
  const diffMs = now - then;
  const mins = Math.floor(diffMs / 60_000);
  if (mins < 1) return 'ahora';
  if (mins < 60) return `hace ${mins}m`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `hace ${hrs}h`;
  const days = Math.floor(hrs / 24);
  return `hace ${days}d`;
}

export function OrderCard({ order }: OrderCardProps) {
  const { data: vehicle } = useVehicle(order.vehicle_id);
  const statusColor = StatusColors[order.estado];
  const router = useRouter();
  const { data: quotation } = useOrderQuotation(
    order.estado === 'APROBACION' ? order.id : '',
  );

  const handlePress = () => {
    if (order.estado === 'DIAGNOSTICO') {
      router.push(`/(auth)/diagnosis/${order.id}`);
    } else if (order.estado === 'APROBACION' && quotation) {
      router.push(`/(auth)/quotation/${quotation.id}`);
    } else if (order.estado === 'REPARACION' || order.estado === 'QC') {
      router.push(`/(auth)/qc/${order.id}`);
    } else if (order.estado === 'ENTREGA' || order.estado === 'CERRADA') {
      router.push(`/(auth)/delivery/${order.id}`);
    } else {
      console.log('Navigate to order', order.id);
    }
  };

  return (
    <Pressable
      style={({ pressed }) => [
        styles.card,
        { borderLeftColor: statusColor },
        pressed && styles.cardPressed,
      ]}
      onPress={handlePress}
    >
      <View style={[styles.accentStripe, { backgroundColor: statusColor }]} />

      <View style={styles.header}>
        <Text style={styles.placa} numberOfLines={1}>
          {vehicle?.placa ?? '···'}
        </Text>
        <View style={[styles.dot, { backgroundColor: statusColor }]} />
      </View>

      {vehicle && (
        <Text style={styles.vehicleInfo} numberOfLines={1}>
          {vehicle.marca} {vehicle.modelo}
        </Text>
      )}

      {order.motivo_ingreso ? (
        <Text style={styles.motivo} numberOfLines={2}>
          {order.motivo_ingreso}
        </Text>
      ) : null}

      <Text style={styles.time}>{relativeTime(order.fecha_ingreso)}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
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
  accentStripe: {
    width: 42,
    height: 4,
    borderRadius: Radius.pill,
    marginBottom: Spacing.md,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  placa: {
    fontSize: TypeScale.body,
    fontFamily: Fonts.bold,
    color: Semantic.onSurface,
    flexShrink: 1,
  },
  dot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    marginLeft: Spacing.sm,
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
  time: {
    fontSize: TypeScale.caption,
    color: Semantic.textMuted,
    marginTop: Spacing.xs,
    textAlign: 'right',
    fontFamily: Fonts.medium,
  },
});
