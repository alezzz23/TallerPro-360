import { useCallback } from 'react';
import {
  ActivityIndicator,
  Alert,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

import { useOrder, useVehicle } from '@/hooks/use-orders';
import { useOrderQuotation } from '@/hooks/use-quotations';
import { useQC } from '@/hooks/use-qc';
import { useInvoice, useNPS, useCloseOrder } from '@/hooks/use-billing';
import { useAuthStore } from '@/stores/auth-store';

import { DeliveryProgress } from '@/components/billing/delivery-progress';
import { InvoiceForm } from '@/components/billing/invoice-form';
import { InvoiceSummary } from '@/components/billing/invoice-summary';
import { NPSForm } from '@/components/billing/nps-form';
import { NPSSummary } from '@/components/billing/nps-summary';

import { Semantic, Shadows, Radius, Spacing, StatusColors, TypeScale } from '@/constants/theme';

export default function DeliveryScreen() {
  const { orderId } = useLocalSearchParams<{ orderId: string }>();
  const router = useRouter();
  const user = useAuthStore((s) => s.user);

  const { data: order, isLoading: orderLoading } = useOrder(orderId);
  const { data: vehicle } = useVehicle(order?.vehicle_id ?? '');
  const { data: quotation } = useOrderQuotation(orderId);
  const { data: qc } = useQC(orderId);
  const { data: invoice, isLoading: invoiceLoading } = useInvoice(orderId);
  const { data: nps, isLoading: npsLoading } = useNPS(orderId);

  const closeOrderMut = useCloseOrder();

  const qcApproved = qc?.aprobado === true;
  const invoiceCreated = !!invoice;
  const npsCompleted = !!nps;
  const orderClosed = order?.estado === 'CERRADA';
  const canClose =
    qcApproved &&
    invoiceCreated &&
    npsCompleted &&
    !orderClosed &&
    (user?.rol === 'ASESOR' || user?.rol === 'JEFE_TALLER' || user?.rol === 'ADMIN');

  const montoTotal = quotation?.total ?? 0;

  const handleClose = useCallback(() => {
    Alert.alert(
      'Cerrar Orden',
      '¿Confirma el cierre de esta orden? Esta acción es irreversible.',
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Cerrar Orden',
          style: 'destructive',
          onPress: async () => {
            try {
              await closeOrderMut.mutateAsync(orderId);
              Alert.alert('Orden cerrada', 'La orden fue cerrada exitosamente.');
              router.back();
            } catch (e: any) {
              Alert.alert(
                'Error',
                e?.response?.data?.detail ?? 'No se pudo cerrar la orden.',
              );
            }
          },
        },
      ],
    );
  }, [orderId, closeOrderMut, router]);

  if (orderLoading) {
    return (
      <View style={styles.center}>
          <ActivityIndicator size="large" color={Semantic.primary} />
      </View>
    );
  }

  const isBusy = closeOrderMut.isPending;

  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.scroll}>
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

        {/* Closed banner */}
        {orderClosed && (
          <View style={styles.closedBanner}>
            <Ionicons name="checkmark-circle" size={32} color={Semantic.primary} />
            <Text style={styles.closedText}>Orden Cerrada</Text>
          </View>
        )}

        {/* Progress */}
        <DeliveryProgress
          qcApproved={qcApproved}
          invoiceCreated={invoiceCreated}
          npsCompleted={npsCompleted}
          orderClosed={orderClosed}
        />

        {/* Invoice section */}
        {invoiceLoading ? (
          <View style={styles.loadingSection}>
            <ActivityIndicator color={Semantic.primary} />
          </View>
        ) : invoiceCreated ? (
          <InvoiceSummary invoice={invoice} />
        ) : !orderClosed ? (
          <InvoiceForm orderId={orderId} montoTotal={montoTotal} />
        ) : null}

        {/* NPS section */}
        {npsLoading ? (
          <View style={styles.loadingSection}>
            <ActivityIndicator color={Semantic.primary} />
          </View>
        ) : npsCompleted ? (
          <NPSSummary survey={nps} />
        ) : !orderClosed ? (
          <NPSForm orderId={orderId} />
        ) : null}

        {/* Spacer for button */}
        <View style={{ height: 100 }} />
      </ScrollView>

      {/* Close Order button */}
      {canClose && (
        <View style={styles.bottomBar}>
          <Pressable
            style={[styles.closeBtn, isBusy && styles.btnDisabled]}
            onPress={handleClose}
            disabled={isBusy}
          >
            {isBusy ? (
              <ActivityIndicator color="#fff" size="small" />
            ) : (
              <Text style={styles.closeBtnText}>Cerrar Orden</Text>
            )}
          </Pressable>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Semantic.background,
  },
  scroll: {
    paddingBottom: Spacing.xxl,
  },
  center: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
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
    fontSize: TypeScale.caption,
    color: Semantic.textMuted,
    marginTop: Spacing.xs,
  },
  closedBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Semantic.surface,
    marginHorizontal: Spacing.md,
    marginTop: Spacing.md,
    borderRadius: Radius.lg,
    paddingVertical: Spacing.sm,
    gap: Spacing.sm,
    borderWidth: 1,
    borderColor: Semantic.border,
    ...Shadows.soft,
  },
  closedText: {
    fontSize: TypeScale.body,
    fontWeight: '700',
    color: Semantic.onSurface,
  },
  loadingSection: {
    padding: Spacing.xl,
    alignItems: 'center',
  },
  bottomBar: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    padding: Spacing.md,
    backgroundColor: Semantic.surface,
    borderTopWidth: 1,
    borderTopColor: Semantic.borderLight,
  },
  closeBtn: {
    backgroundColor: Semantic.primary,
    borderRadius: Radius.pill,
    paddingVertical: 16,
    alignItems: 'center',
    ...Shadows.extruded,
  },
  btnDisabled: {
    opacity: 0.5,
  },
  closeBtnText: {
    color: Semantic.onPrimary,
    fontSize: TypeScale.subtitle,
    fontWeight: '700',
  },
});
