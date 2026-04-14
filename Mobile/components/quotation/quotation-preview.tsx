import {
  ActivityIndicator,
  Alert,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import * as Linking from 'expo-linking';
import { Ionicons } from '@expo/vector-icons';

import { Radius, Semantic, Shadows, Spacing, TypeScale } from '@/constants/theme';
import { formatCurrency } from '@/utils/currency';
import { QuotationItemRow } from '@/components/quotation/quotation-item-row';
import { DiscountForm } from '@/components/quotation/discount-form';
import {
  useApplyDiscount,
  useApproveQuotation,
  useRejectQuotation,
  useSendQuotation,
  useCustomer,
} from '@/hooks/use-quotations';
import { useVehicle } from '@/hooks/use-orders';
import type { Quotation, QuotationEstado } from '@/types/api';

interface QuotationPreviewProps {
  quotation: Quotation;
  vehicleId: string;
  criticalFindingIds?: Set<string>;
  onNavigateCreateNew?: () => void;
}

const ESTADO_BADGE: Record<QuotationEstado, { bg: string; text: string; label: string }> = {
  PENDIENTE: { bg: 'rgba(213,154,47,0.18)', text: '#D59A2F', label: 'Pendiente' },
  APROBADA: { bg: 'rgba(47,126,115,0.18)', text: '#65B8A6', label: 'Aprobada' },
  RECHAZADA: { bg: 'rgba(198,90,90,0.18)', text: '#E38A8A', label: 'Rechazada' },
};

export function QuotationPreview({
  quotation,
  vehicleId,
  criticalFindingIds,
  onNavigateCreateNew,
}: QuotationPreviewProps) {
  const { data: vehicle } = useVehicle(vehicleId);
  const { data: customer } = useCustomer(vehicle?.customer_id ?? '');

  const sendMutation = useSendQuotation();
  const approveMutation = useApproveQuotation();
  const rejectMutation = useRejectQuotation();
  const discountMutation = useApplyDiscount();

  const badge = ESTADO_BADGE[quotation.estado];
  const isPending = quotation.estado === 'PENDIENTE';
  const isRejected = quotation.estado === 'RECHAZADA';
  const isApproved = quotation.estado === 'APROBADA';

  const handleSendWhatsApp = async () => {
    // Mark as sent on the server
    await sendMutation.mutateAsync(quotation.id);

    const phone = customer?.whatsapp ?? customer?.telefono ?? '';
    if (!phone) {
      Alert.alert('Sin teléfono', 'El cliente no tiene número de WhatsApp registrado.');
      return;
    }

    const itemLines = quotation.items
      .map((it, i) => `${i + 1}. ${it.descripcion}: ${formatCurrency(it.precio_final)}`)
      .join('\n');

    const message = [
      `🔧 *Cotización TallerPro 360*`,
      vehicle ? `Vehículo: ${vehicle.placa} · ${vehicle.marca} ${vehicle.modelo}` : '',
      '',
      itemLines,
      '',
      `Subtotal: ${formatCurrency(quotation.subtotal)}`,
      quotation.shop_supplies > 0 ? `Shop Supplies: ${formatCurrency(quotation.shop_supplies)}` : '',
      quotation.descuento > 0 ? `Descuento: -${formatCurrency(quotation.descuento)}` : '',
      `Impuestos: ${formatCurrency(quotation.impuestos)}`,
      `*TOTAL: ${formatCurrency(quotation.total)}*`,
    ]
      .filter(Boolean)
      .join('\n');

    const url = `whatsapp://send?phone=${encodeURIComponent(phone)}&text=${encodeURIComponent(message)}`;

    const supported = await Linking.canOpenURL(url);
    if (supported) {
      await Linking.openURL(url);
    } else {
      Alert.alert('WhatsApp', 'No se pudo abrir WhatsApp. Verifique que esté instalado.');
    }
  };

  const handleApprove = () => {
    Alert.alert('Aprobar cotización', '¿Confirmar aprobación de esta cotización?', [
      { text: 'Cancelar', style: 'cancel' },
      {
        text: 'Aprobar',
        onPress: () => approveMutation.mutate(quotation.id),
      },
    ]);
  };

  const handleReject = () => {
    Alert.alert('Rechazar cotización', '¿Confirmar rechazo de esta cotización?', [
      { text: 'Cancelar', style: 'cancel' },
      {
        text: 'Rechazar',
        style: 'destructive',
        onPress: () =>
          rejectMutation.mutate({ quotationId: quotation.id }),
      },
    ]);
  };

  const handleApplyDiscount = (descuento: number, razon?: string) => {
    discountMutation.mutate({
      quotationId: quotation.id,
      data: { descuento, razon },
    });
  };

  const anyLoading =
    sendMutation.isPending ||
    approveMutation.isPending ||
    rejectMutation.isPending;

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      {/* Status badge */}
      <View style={styles.statusRow}>
        <View style={[styles.badge, { backgroundColor: badge.bg }]}>
          <Text style={[styles.badgeText, { color: badge.text }]}>
            {badge.label}
          </Text>
        </View>
        {quotation.fecha_envio && (
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
            <Ionicons name="checkmark" size={14} color={Semantic.success} />
            <Text style={styles.sentDate}>Enviada</Text>
          </View>
        )}
      </View>

      {isApproved && (
        <View style={styles.approvedBanner}>
          <Ionicons name="checkmark-circle" size={24} color={Semantic.success} />
          <Text style={styles.approvedBannerText}>
            Cotización aprobada — Orden en reparación
          </Text>
        </View>
      )}

      {/* Items */}
      <Text style={styles.sectionTitle}>Ítems</Text>
      {quotation.items.map((item) => (
        <QuotationItemRow
          key={item.id}
          item={item}
          isCritical={criticalFindingIds?.has(item.finding_id)}
        />
      ))}

      {/* Totals */}
      <View style={styles.totalsCard}>
        <View style={styles.totalLine}>
          <Text style={styles.totalLabel}>Subtotal</Text>
          <Text style={styles.totalValue}>{formatCurrency(quotation.subtotal)}</Text>
        </View>
        {quotation.shop_supplies > 0 && (
          <View style={styles.totalLine}>
            <Text style={styles.totalLabel}>Shop Supplies</Text>
            <Text style={styles.totalValue}>{formatCurrency(quotation.shop_supplies)}</Text>
          </View>
        )}
        {quotation.descuento > 0 && (
          <View style={styles.totalLine}>
            <Text style={[styles.totalLabel, { color: Semantic.danger }]}>Descuento</Text>
            <Text style={[styles.totalValue, { color: Semantic.danger }]}>
              -{formatCurrency(quotation.descuento)}
            </Text>
          </View>
        )}
        <View style={styles.totalLine}>
          <Text style={styles.totalLabel}>Impuestos</Text>
          <Text style={styles.totalValue}>{formatCurrency(quotation.impuestos)}</Text>
        </View>
        <View style={[styles.totalLine, styles.grandTotalLine]}>
          <Text style={styles.grandTotalLabel}>TOTAL</Text>
          <Text style={styles.grandTotalValue}>{formatCurrency(quotation.total)}</Text>
        </View>
      </View>

      {/* Actions */}
      {isPending && (
        <View style={styles.actionGroup}>
          <Pressable
            style={({ pressed }) => [
              styles.actionBtn,
              styles.whatsappBtn,
              pressed && styles.actionBtnPressed,
            ]}
            onPress={handleSendWhatsApp}
            disabled={anyLoading}
          >
            {sendMutation.isPending ? (
              <ActivityIndicator color={Semantic.onPrimary} />
            ) : (
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                <Ionicons name="logo-whatsapp" size={18} color="#0A0A0A" />
                <Text style={styles.actionBtnText}>Enviar por WhatsApp</Text>
              </View>
            )}
          </Pressable>

          <View style={styles.actionRow}>
            <Pressable
              style={({ pressed }) => [
                styles.actionBtn,
                styles.approveBtn,
                { flex: 1 },
                pressed && styles.actionBtnPressed,
              ]}
              onPress={handleApprove}
              disabled={anyLoading}
            >
              {approveMutation.isPending ? (
                <ActivityIndicator color={Semantic.onPrimary} />
              ) : (
                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                  <Ionicons name="checkmark" size={18} color="#fff" />
                  <Text style={styles.actionBtnText}>Aprobar</Text>
                </View>
              )}
            </Pressable>

            <Pressable
              style={({ pressed }) => [
                styles.actionBtn,
                styles.rejectBtn,
                { flex: 1 },
                pressed && styles.actionBtnPressed,
              ]}
              onPress={handleReject}
              disabled={anyLoading}
            >
              {rejectMutation.isPending ? (
                <ActivityIndicator color={Semantic.onPrimary} />
              ) : (
                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                  <Ionicons name="close" size={18} color="#fff" />
                  <Text style={styles.actionBtnText}>Rechazar</Text>
                </View>
              )}
            </Pressable>
          </View>
        </View>
      )}

      {isRejected && (
        <View style={styles.rejectedSection}>
          <Text style={styles.rejectedTitle}>Cotización Rechazada</Text>
          <Text style={styles.rejectedHint}>
            Aplique un descuento y reenvíe, o cree una nueva cotización.
          </Text>

          <DiscountForm
            currentTotal={quotation.total}
            currentDescuento={quotation.descuento}
            isSubmitting={discountMutation.isPending}
            onApply={handleApplyDiscount}
          />

          {onNavigateCreateNew && (
            <Pressable
              style={({ pressed }) => [
                styles.actionBtn,
                styles.newQuotationBtn,
                pressed && styles.actionBtnPressed,
              ]}
              onPress={onNavigateCreateNew}
            >
              <Text style={styles.newQuotationBtnText}>
                + Crear Nueva Cotización
              </Text>
            </Pressable>
          )}
        </View>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Semantic.background },
  content: { padding: Spacing.md, paddingBottom: 100 },
  statusRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: Spacing.md,
  },
  badge: {
    paddingHorizontal: Spacing.sm + 4,
    paddingVertical: Spacing.xs,
    borderRadius: Radius.pill,
  },
  badgeText: {
    fontSize: TypeScale.label,
    fontWeight: '700',
  },
  sentDate: {
    fontSize: TypeScale.caption,
    color: Semantic.success,
    fontWeight: '600',
  },
  approvedBanner: {
    backgroundColor: '#052E16',
    flexDirection: 'row',
    alignItems: 'center',
    padding: Spacing.md,
    borderRadius: Radius.md,
    marginBottom: Spacing.md,
    gap: Spacing.sm,
  },
  approvedBannerText: {
    fontSize: TypeScale.body,
    fontWeight: '600',
    color: Semantic.success,
    flex: 1,
  },
  sectionTitle: {
    fontSize: TypeScale.subtitle,
    fontWeight: '700',
    color: Semantic.onSurface,
    marginBottom: Spacing.sm,
  },
  totalsCard: {
    backgroundColor: Semantic.surface,
    borderRadius: Radius.lg,
    padding: Spacing.md,
    marginTop: Spacing.md,
    borderTopWidth: 1,
    borderLeftWidth: 1,
    borderTopColor: Semantic.borderLight,
    borderLeftColor: Semantic.borderLight,
    ...Shadows.extruded,
  },
  totalLine: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Spacing.xs,
  },
  totalLabel: {
    fontSize: TypeScale.label,
    color: Semantic.secondary,
  },
  totalValue: {
    fontSize: TypeScale.label,
    fontWeight: '600',
    color: Semantic.onSurface,
    textAlign: 'right',
  },
  grandTotalLine: {
    borderTopWidth: 2,
    borderTopColor: Semantic.primary,
    marginTop: Spacing.sm,
    paddingTop: Spacing.sm,
  },
  grandTotalLabel: {
    fontSize: TypeScale.title,
    fontWeight: '800',
    color: Semantic.onSurface,
  },
  grandTotalValue: {
    fontSize: TypeScale.title,
    fontWeight: '800',
    color: Semantic.primary,
  },
  actionGroup: {
    marginTop: Spacing.lg,
    gap: Spacing.sm,
  },
  actionRow: {
    flexDirection: 'row',
    gap: Spacing.sm,
  },
  actionBtn: {
    paddingVertical: Spacing.md,
    borderRadius: Radius.pill,
    alignItems: 'center',
    ...Shadows.extruded,
  },
  actionBtnPressed: {
    ...Shadows.none,
    transform: [{ scale: 0.97 }],
  },
  actionBtnText: {
    color: '#fff',
    fontSize: TypeScale.body,
    fontWeight: '700',
  },
  whatsappBtn: {
    backgroundColor: '#25D366',
  },
  approveBtn: {
    backgroundColor: Semantic.success,
  },
  rejectBtn: {
    backgroundColor: Semantic.danger,
  },
  rejectedSection: {
    marginTop: Spacing.lg,
  },
  rejectedTitle: {
    fontSize: TypeScale.subtitle,
    fontWeight: '700',
    color: Semantic.danger,
    marginBottom: Spacing.xs,
  },
  rejectedHint: {
    fontSize: TypeScale.label,
    color: Semantic.secondary,
    marginBottom: Spacing.sm,
  },
  newQuotationBtn: {
    backgroundColor: Semantic.surface,
    borderWidth: 2,
    borderColor: Semantic.primary,
    marginTop: Spacing.md,
  },
  newQuotationBtnText: {
    color: Semantic.primary,
    fontSize: TypeScale.body,
    fontWeight: '700',
  },
});
