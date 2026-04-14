import { StyleSheet, Text, View } from 'react-native';

import { Fonts, Semantic, Radius, Shadows, Spacing, TypeScale } from '@/constants/theme';
import { formatCurrency } from '@/utils/currency';
import type { Quotation, QuotationEstado } from '@/types/api';

interface QuotationSummaryCardProps {
  quotation: Quotation;
}

const ESTADO_BADGE: Record<QuotationEstado, { bg: string; text: string }> = {
  PENDIENTE: { bg: 'rgba(213,154,47,0.18)', text: '#D59A2F' },
  APROBADA: { bg: 'rgba(47,126,115,0.18)', text: '#65B8A6' },
  RECHAZADA: { bg: 'rgba(198,90,90,0.18)', text: '#E38A8A' },
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
    fontFamily: Fonts.medium,
    color: Semantic.secondary,
  },
  badge: {
    paddingHorizontal: Spacing.sm,
    paddingVertical: 2,
    borderRadius: Radius.pill,
  },
  badgeText: {
    fontSize: TypeScale.caption,
    fontFamily: Fonts.bold,
  },
  total: {
    fontSize: TypeScale.title,
    fontFamily: Fonts.display,
    color: Semantic.primary,
  },
  meta: {
    fontSize: TypeScale.caption,
    color: Semantic.textMuted,
    marginTop: 2,
    fontFamily: Fonts.medium,
  },
});
