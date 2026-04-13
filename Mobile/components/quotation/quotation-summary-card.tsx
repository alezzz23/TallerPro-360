import { StyleSheet, Text, View } from 'react-native';

import { Semantic, Radius, Shadows, Spacing, StatusColors, TypeScale } from '@/constants/theme';
import { formatCurrency } from '@/utils/currency';
import type { Quotation, QuotationEstado } from '@/types/api';

interface QuotationSummaryCardProps {
  quotation: Quotation;
}

const ESTADO_BADGE: Record<QuotationEstado, { bg: string; text: string }> = {
  PENDIENTE: { bg: '#1C1C00', text: '#EAB308' },
  APROBADA: { bg: '#052E16', text: '#22C55E' },
  RECHAZADA: { bg: '#2A1215', text: '#EF4444' },
};

export function QuotationSummaryCard({ quotation }: QuotationSummaryCardProps) {
  const badge = ESTADO_BADGE[quotation.estado];

  return (
    <View style={styles.card}>
      <View style={styles.header}>
        <Text style={styles.label}>Cotización</Text>
        <View style={[styles.badge, { backgroundColor: badge.bg }]}>
          <Text style={[styles.badgeText, { color: badge.text }]}>
            {quotation.estado}
          </Text>
        </View>
      </View>
      <Text style={styles.total}>{formatCurrency(quotation.total)}</Text>
      <Text style={styles.meta}>
        {quotation.items.length} ítem{quotation.items.length !== 1 ? 'es' : ''}
        {quotation.descuento > 0
          ? ` · Desc. ${formatCurrency(quotation.descuento)}`
          : ''}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: Semantic.surface,
    borderRadius: Radius.lg,
    padding: Spacing.md,
    borderLeftWidth: 4,
    borderLeftColor: Semantic.primary,
    borderTopWidth: 1,
    borderTopColor: Semantic.borderLight,
    ...Shadows.extruded,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: Spacing.xs,
  },
  label: {
    fontSize: TypeScale.label,
    fontWeight: '600',
    color: Semantic.secondary,
  },
  badge: {
    paddingHorizontal: Spacing.sm,
    paddingVertical: 2,
    borderRadius: Radius.pill,
  },
  badgeText: {
    fontSize: TypeScale.caption,
    fontWeight: '700',
  },
  total: {
    fontSize: TypeScale.title,
    fontWeight: '800',
    color: Semantic.primary,
  },
  meta: {
    fontSize: TypeScale.caption,
    color: Semantic.textMuted,
    marginTop: 2,
  },
});
