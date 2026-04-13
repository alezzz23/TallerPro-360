import { useCallback, useMemo, useState } from 'react';
import {
  ActivityIndicator,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';

import { Semantic, Radius, Shadows, Spacing, StatusColors, TypeScale } from '@/constants/theme';
import { formatCurrency, formatPercent } from '@/utils/currency';
import { QuotationItemRow } from '@/components/quotation/quotation-item-row';
import type { DiagnosticFinding, QuotationItem } from '@/types/api';
import type { QuotationCreatePayload, QuotationItemPayload } from '@/services/quotations';

interface QuotationBuilderProps {
  findings: DiagnosticFinding[];
  isSubmitting: boolean;
  onSubmit: (data: QuotationCreatePayload) => void;
}

interface EditableItem extends QuotationItem {
  isCritical: boolean;
}

export function QuotationBuilder({ findings, isSubmitting, onSubmit }: QuotationBuilderProps) {
  // Build editable items from findings
  const initialItems = useMemo<EditableItem[]>(() => {
    return findings.map((f) => {
      const costoRepuesto = f.parts.reduce((sum, p) => sum + p.precio_venta, 0);
      return {
        id: f.id,
        quotation_id: '',
        finding_id: f.id,
        part_id: f.parts[0]?.id ?? null,
        descripcion: [f.motivo_ingreso, f.descripcion].filter(Boolean).join(' — '),
        mano_obra: 0,
        costo_repuesto: costoRepuesto,
        precio_final: costoRepuesto,
        isCritical: f.es_critico_seguridad,
      };
    });
  }, [findings]);

  const [items, setItems] = useState<EditableItem[]>(initialItems);
  const [impuestosPct, setImpuestosPct] = useState(0.16);
  const [shopSuppliesPct, setShopSuppliesPct] = useState(0.015);
  const [descuento, setDescuento] = useState(0);

  const updateItem = useCallback(
    (idx: number, field: 'mano_obra' | 'costo_repuesto', value: number) => {
      setItems((prev) =>
        prev.map((it, i) =>
          i === idx
            ? { ...it, [field]: value, precio_final: field === 'mano_obra' ? value + it.costo_repuesto : it.mano_obra + value }
            : it,
        ),
      );
    },
    [],
  );

  const subtotal = items.reduce((s, it) => s + it.mano_obra + it.costo_repuesto, 0);
  const shopSupplies = subtotal * shopSuppliesPct;
  const impuestos = (subtotal + shopSupplies - descuento) * impuestosPct;
  const total = subtotal + shopSupplies + impuestos - descuento;

  const handleSubmit = () => {
    const payload: QuotationCreatePayload = {
      items: items.map<QuotationItemPayload>((it) => ({
        finding_id: it.finding_id,
        part_id: it.part_id,
        descripcion: it.descripcion,
        mano_obra: it.mano_obra,
        costo_repuesto: it.costo_repuesto,
      })),
      impuestos_pct: impuestosPct,
      shop_supplies_pct: shopSuppliesPct,
      descuento,
    };
    onSubmit(payload);
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.sectionTitle}>Ítems de Cotización</Text>

      {items.map((item, idx) => (
        <QuotationItemRow
          key={item.finding_id}
          item={item}
          editable
          isCritical={item.isCritical}
          onManoObraChange={(v) => updateItem(idx, 'mano_obra', v)}
          onCostoRepuestoChange={(v) => updateItem(idx, 'costo_repuesto', v)}
        />
      ))}

      {/* Rates */}
      <View style={styles.ratesCard}>
        <Text style={styles.sectionTitle}>Tasas</Text>
        <View style={styles.rateRow}>
          <Text style={styles.rateLabel}>Impuestos (%)</Text>
          <TextInput
            style={styles.rateInput}
            keyboardType="numeric"
            defaultValue={String(impuestosPct * 100)}
            onEndEditing={(e) => {
              const v = parseFloat(e.nativeEvent.text) || 0;
              setImpuestosPct(Math.min(Math.max(v / 100, 0), 1));
            }}
          />
        </View>
        <View style={styles.rateRow}>
          <Text style={styles.rateLabel}>Shop Supplies (%)</Text>
          <TextInput
            style={styles.rateInput}
            keyboardType="numeric"
            defaultValue={String(shopSuppliesPct * 100)}
            onEndEditing={(e) => {
              const v = parseFloat(e.nativeEvent.text) || 0;
              setShopSuppliesPct(Math.min(Math.max(v / 100, 0), 1));
            }}
          />
        </View>
      </View>

      {/* Totals breakdown */}
      <View style={styles.totalsCard}>
        <Text style={styles.sectionTitle}>Resumen</Text>
        <View style={styles.totalLine}>
          <Text style={styles.totalLabel}>Subtotal</Text>
          <Text style={styles.totalValue}>{formatCurrency(subtotal)}</Text>
        </View>
        <View style={styles.totalLine}>
          <Text style={styles.totalLabel}>
            Shop Supplies ({formatPercent(shopSuppliesPct)})
          </Text>
          <Text style={styles.totalValue}>{formatCurrency(shopSupplies)}</Text>
        </View>
        <View style={styles.totalLine}>
          <Text style={styles.totalLabel}>Descuento</Text>
          <TextInput
            style={[styles.totalValue, styles.discountInput]}
            keyboardType="numeric"
            defaultValue={String(descuento)}
            onEndEditing={(e) => {
              setDescuento(Math.max(parseFloat(e.nativeEvent.text) || 0, 0));
            }}
            placeholder="0"
            placeholderTextColor={Semantic.textMuted}
          />
        </View>
        <View style={styles.totalLine}>
          <Text style={styles.totalLabel}>
            Impuestos ({formatPercent(impuestosPct)})
          </Text>
          <Text style={styles.totalValue}>{formatCurrency(impuestos)}</Text>
        </View>
        <View style={[styles.totalLine, styles.grandTotalLine]}>
          <Text style={styles.grandTotalLabel}>TOTAL</Text>
          <Text style={styles.grandTotalValue}>{formatCurrency(total)}</Text>
        </View>
      </View>

      {/* Submit */}
      <Pressable
        style={({ pressed }) => [
          styles.submitBtn,
          pressed && styles.submitBtnPressed,
          isSubmitting && styles.submitBtnDisabled,
        ]}
        onPress={handleSubmit}
        disabled={isSubmitting}
      >
        {isSubmitting ? (
          <ActivityIndicator color={Semantic.onPrimary} />
        ) : (
          <Text style={styles.submitBtnText}>Crear Cotización</Text>
        )}
      </Pressable>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Semantic.background },
  content: { padding: Spacing.md, paddingBottom: 100 },
  sectionTitle: {
    fontSize: TypeScale.subtitle,
    fontWeight: '700',
    color: Semantic.onSurface,
    marginBottom: Spacing.sm,
    marginTop: Spacing.sm,
  },
  ratesCard: {
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
  rateRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Spacing.xs,
  },
  rateLabel: {
    fontSize: TypeScale.label,
    color: Semantic.secondary,
  },
  rateInput: {
    fontSize: TypeScale.label,
    fontWeight: '600',
    color: Semantic.onSurface,
    textAlign: 'right',
    borderBottomWidth: 1,
    borderBottomColor: Semantic.primary,
    minWidth: 60,
    paddingVertical: Spacing.xs,
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
  discountInput: {
    borderBottomWidth: 1,
    borderBottomColor: Semantic.danger,
    minWidth: 80,
    paddingVertical: Spacing.xs,
    color: Semantic.onSurface,
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
  submitBtn: {
    backgroundColor: Semantic.primary,
    paddingVertical: Spacing.md,
    borderRadius: Radius.pill,
    alignItems: 'center',
    marginTop: Spacing.lg,
    ...Shadows.extruded,
  },
  submitBtnPressed: {
    ...Shadows.none,
    backgroundColor: Semantic.primaryDark,
    transform: [{ scale: 0.97 }],
  },
  submitBtnDisabled: { opacity: 0.6 },
  submitBtnText: {
    color: Semantic.onPrimary,
    fontSize: TypeScale.body,
    fontWeight: '700',
  },
});
