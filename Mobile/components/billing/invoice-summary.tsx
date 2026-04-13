import { StyleSheet, Text, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

import { Radius, Semantic, Shadows, Spacing, TypeScale } from '@/constants/theme';
import { METODO_PAGO_OPTIONS } from '@/schemas/billing';
import { formatCurrency } from '@/utils/currency';
import type { Invoice } from '@/types/api';

interface InvoiceSummaryProps {
  invoice: Invoice;
}

export function InvoiceSummary({ invoice }: InvoiceSummaryProps) {
  const method = METODO_PAGO_OPTIONS.find((o) => o.value === invoice.metodo_pago);
  const fecha = new Date(invoice.fecha).toLocaleDateString('es-CO', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  });

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.sectionTitle}>Factura</Text>
        <View style={styles.badge}>
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
            <Ionicons name="checkmark" size={12} color={Semantic.primary} />
            <Text style={styles.badgeText}>Facturado</Text>
          </View>
        </View>
      </View>

      {/* Total */}
      <View style={styles.totalBox}>
        <Text style={styles.totalLabel}>Total facturado</Text>
        <Text style={styles.totalAmount}>{formatCurrency(invoice.monto_total)}</Text>
      </View>

      {/* Details */}
      <View style={styles.row}>
        <Text style={styles.label}>Método de pago</Text>
        <View style={styles.methodBadge}>
          {method && (
            <Ionicons
              name={method.icon as any}
              size={16}
              color={Semantic.onSurface}
              style={{ marginRight: 4 }}
            />
          )}
          <Text style={styles.methodText}>{method?.label ?? invoice.metodo_pago}</Text>
        </View>
      </View>

      {invoice.es_credito && (
        <View style={styles.row}>
          <Text style={styles.label}>Saldo pendiente</Text>
          <Text style={styles.value}>{formatCurrency(invoice.saldo_pendiente)}</Text>
        </View>
      )}

      <View style={styles.row}>
        <Text style={styles.label}>Fecha</Text>
        <Text style={styles.value}>{fecha}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: Semantic.surface,
    borderRadius: Radius.lg,
    marginHorizontal: Spacing.md,
    marginTop: Spacing.md,
    padding: Spacing.md,
    borderTopWidth: 1,
    borderLeftWidth: 1,
    borderTopColor: Semantic.borderLight,
    borderLeftColor: Semantic.borderLight,
    ...Shadows.extruded,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: Spacing.md,
  },
  sectionTitle: {
    fontSize: TypeScale.subtitle,
    fontWeight: '700',
    color: Semantic.onSurface,
  },
  badge: {
    backgroundColor: '#052E16',
    borderRadius: Radius.pill,
    paddingHorizontal: 12,
    paddingVertical: 4,
  },
  badgeText: {
    fontSize: TypeScale.caption,
    fontWeight: '700',
    color: Semantic.primary,
  },
  totalBox: {
    backgroundColor: Semantic.primaryMuted,
    borderRadius: Radius.md,
    padding: Spacing.md,
    alignItems: 'center',
    marginBottom: Spacing.md,
  },
  totalLabel: {
    fontSize: TypeScale.label,
    color: Semantic.primary,
    fontWeight: '600',
  },
  totalAmount: {
    fontSize: TypeScale.headline,
    fontWeight: '800',
    color: Semantic.primary,
    marginTop: Spacing.xs,
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Spacing.sm,
    borderTopWidth: 1,
    borderTopColor: Semantic.border,
  },
  label: {
    fontSize: TypeScale.label,
    color: Semantic.secondary,
  },
  value: {
    fontSize: TypeScale.body,
    fontWeight: '600',
    color: Semantic.onSurface,
  },
  methodBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Semantic.surfaceElevated,
    borderRadius: Radius.sm,
    paddingHorizontal: 10,
    paddingVertical: 4,
  },
  methodText: {
    fontSize: TypeScale.label,
    fontWeight: '600',
    color: Semantic.onSurface,
  },
});
