import { StyleSheet, Text, TextInput, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

import { Radius, Semantic, Shadows, Spacing, StatusColors, TypeScale } from '@/constants/theme';
import { formatCurrency } from '@/utils/currency';
import type { QuotationItem } from '@/types/api';

interface QuotationItemRowProps {
  item: QuotationItem;
  editable?: boolean;
  isCritical?: boolean;
  onManoObraChange?: (value: number) => void;
  onCostoRepuestoChange?: (value: number) => void;
}

export function QuotationItemRow({
  item,
  editable = false,
  isCritical = false,
  onManoObraChange,
  onCostoRepuestoChange,
}: QuotationItemRowProps) {
  return (
    <View style={[styles.row, isCritical && styles.criticalRow]}>
      <View style={styles.descriptionSection}>
        {isCritical && (
          <View style={styles.criticalBadge}>
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
              <Ionicons name="warning" size={12} color="#fff" />
              <Text style={styles.criticalBadgeText}>SEGURIDAD</Text>
            </View>
          </View>
        )}
        <Text style={styles.descripcion} numberOfLines={2}>
          {item.descripcion}
        </Text>
      </View>

      <View style={styles.valuesSection}>
        <View style={styles.valueRow}>
          <Text style={styles.valueLabel}>Mano de obra</Text>
          {editable ? (
            <TextInput
              style={styles.valueInput}
              keyboardType="numeric"
              defaultValue={String(item.mano_obra)}
              onEndEditing={(e) => {
                const val = parseFloat(e.nativeEvent.text) || 0;
                onManoObraChange?.(val);
              }}
              placeholder="0"
              placeholderTextColor={Semantic.textMuted}
            />
          ) : (
            <Text style={styles.valueAmount}>
              {formatCurrency(item.mano_obra)}
            </Text>
          )}
        </View>

        <View style={styles.valueRow}>
          <Text style={styles.valueLabel}>Repuesto</Text>
          {editable ? (
            <TextInput
              style={styles.valueInput}
              keyboardType="numeric"
              defaultValue={String(item.costo_repuesto)}
              onEndEditing={(e) => {
                const val = parseFloat(e.nativeEvent.text) || 0;
                onCostoRepuestoChange?.(val);
              }}
              placeholder="0"
              placeholderTextColor={Semantic.textMuted}
            />
          ) : (
            <Text style={styles.valueAmount}>
              {formatCurrency(item.costo_repuesto)}
            </Text>
          )}
        </View>

        <View style={[styles.valueRow, styles.totalRow]}>
          <Text style={styles.totalLabel}>Precio</Text>
          <Text style={styles.totalAmount}>
            {formatCurrency(item.mano_obra + item.costo_repuesto)}
          </Text>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    backgroundColor: Semantic.surface,
    borderRadius: Radius.lg,
    padding: Spacing.md,
    marginBottom: Spacing.sm,
    borderLeftWidth: 4,
    borderLeftColor: StatusColors.APROBACION,
    borderTopWidth: 1,
    borderTopColor: Semantic.borderLight,
    ...Shadows.extruded,
  },
  criticalRow: {
    borderLeftColor: Semantic.danger,
    backgroundColor: '#2A1215',
  },
  descriptionSection: {
    marginBottom: Spacing.sm,
  },
  criticalBadge: {
    backgroundColor: Semantic.danger,
    alignSelf: 'flex-start',
    paddingHorizontal: Spacing.sm,
    paddingVertical: 2,
    borderRadius: Radius.pill,
    marginBottom: Spacing.xs,
  },
  criticalBadgeText: {
    fontSize: TypeScale.caption,
    fontWeight: '700',
    color: '#fff',
  },
  descripcion: {
    fontSize: TypeScale.body,
    fontWeight: '600',
    color: Semantic.onSurface,
    lineHeight: 22,
  },
  valuesSection: {
    gap: Spacing.xs,
  },
  valueRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  valueLabel: {
    fontSize: TypeScale.label,
    color: Semantic.secondary,
  },
  valueAmount: {
    fontSize: TypeScale.label,
    fontWeight: '600',
    color: Semantic.onSurface,
    textAlign: 'right',
  },
  valueInput: {
    fontSize: TypeScale.label,
    fontWeight: '600',
    color: Semantic.onSurface,
    textAlign: 'right',
    borderBottomWidth: 1,
    borderBottomColor: Semantic.primary,
    minWidth: 100,
    paddingVertical: Spacing.xs,
  },
  totalRow: {
    borderTopWidth: 1,
    borderTopColor: Semantic.border,
    paddingTop: Spacing.xs,
    marginTop: Spacing.xs,
  },
  totalLabel: {
    fontSize: TypeScale.label,
    fontWeight: '700',
    color: Semantic.onSurface,
  },
  totalAmount: {
    fontSize: TypeScale.body,
    fontWeight: '800',
    color: Semantic.primary,
    textAlign: 'right',
  },
});
