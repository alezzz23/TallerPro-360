import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useRouter } from 'expo-router';

import { useVehicle } from '@/hooks/use-orders';
import { useOrderQuotation } from '@/hooks/use-quotations';
import { StatusColors, Spacing, TypeScale, Shadows, Radius } from '@/constants/theme';
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
    backgroundColor: '#161616',
    borderRadius: Radius.lg,
    borderLeftWidth: 4,
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
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  placa: {
    fontSize: TypeScale.body,
    fontWeight: '700',
    color: '#F5F5F5',
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
    color: '#A3A3A3',
    marginTop: 2,
  },
  motivo: {
    fontSize: TypeScale.caption,
    color: '#525252',
    marginTop: Spacing.xs,
    lineHeight: 18,
  },
  time: {
    fontSize: TypeScale.caption,
    color: '#525252',
    marginTop: Spacing.xs,
    textAlign: 'right',
  },
});
