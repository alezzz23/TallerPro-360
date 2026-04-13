import { useState } from 'react';
import {
  ActivityIndicator,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';

import { Semantic, Radius, Shadows, Spacing, TypeScale } from '@/constants/theme';
import { formatCurrency } from '@/utils/currency';

interface DiscountFormProps {
  currentTotal: number;
  currentDescuento: number;
  isSubmitting: boolean;
  onApply: (descuento: number, razon?: string) => void;
}

export function DiscountForm({
  currentTotal,
  currentDescuento,
  isSubmitting,
  onApply,
}: DiscountFormProps) {
  const [descuento, setDescuento] = useState(String(currentDescuento));
  const [razon, setRazon] = useState('');

  const numDescuento = parseFloat(descuento) || 0;
  const newTotal = currentTotal + currentDescuento - numDescuento;

  return (
    <View style={styles.card}>
      <Text style={styles.title}>Aplicar Descuento</Text>

      <View style={styles.field}>
        <Text style={styles.label}>Descuento ($)</Text>
        <TextInput
          style={styles.input}
          keyboardType="numeric"
          value={descuento}
          onChangeText={setDescuento}
          placeholder="0"
          placeholderTextColor={Semantic.textMuted}
        />
      </View>

      <View style={styles.field}>
        <Text style={styles.label}>Razón (opcional)</Text>
        <TextInput
          style={[styles.input, styles.textArea]}
          value={razon}
          onChangeText={setRazon}
          placeholder="Motivo del descuento..."
          placeholderTextColor={Semantic.textMuted}
          multiline
          numberOfLines={2}
        />
      </View>

      <View style={styles.previewRow}>
        <Text style={styles.previewLabel}>Nuevo total estimado</Text>
        <Text style={styles.previewValue}>{formatCurrency(Math.max(newTotal, 0))}</Text>
      </View>

      <Pressable
        style={({ pressed }) => [
          styles.applyBtn,
          pressed && styles.applyBtnPressed,
          isSubmitting && styles.applyBtnDisabled,
        ]}
        onPress={() => onApply(numDescuento, razon || undefined)}
        disabled={isSubmitting || numDescuento <= 0}
      >
        {isSubmitting ? (
          <ActivityIndicator color={Semantic.onPrimary} />
        ) : (
          <Text style={styles.applyBtnText}>Aplicar Descuento</Text>
        )}
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: Semantic.surface,
    borderRadius: Radius.lg,
    padding: Spacing.md,
    marginTop: Spacing.md,
    borderWidth: 1,
    borderColor: Semantic.border,
    ...Shadows.extruded,
  },
  title: {
    fontSize: TypeScale.subtitle,
    fontWeight: '700',
    color: Semantic.onSurface,
    marginBottom: Spacing.sm,
  },
  field: {
    marginBottom: Spacing.sm,
  },
  label: {
    fontSize: TypeScale.label,
    color: Semantic.secondary,
    marginBottom: Spacing.xs,
  },
  input: {
    backgroundColor: Semantic.surfaceElevated,
    borderWidth: 1,
    borderColor: Semantic.border,
    borderRadius: Radius.md,
    paddingHorizontal: Spacing.sm,
    paddingVertical: Spacing.sm,
    fontSize: TypeScale.body,
    color: Semantic.onSurface,
  },
  textArea: {
    minHeight: 60,
    textAlignVertical: 'top',
  },
  previewRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: Semantic.surfaceElevated,
    padding: Spacing.sm,
    borderRadius: Radius.md,
    marginBottom: Spacing.md,
  },
  previewLabel: {
    fontSize: TypeScale.label,
    color: Semantic.secondary,
  },
  previewValue: {
    fontSize: TypeScale.subtitle,
    fontWeight: '800',
    color: Semantic.primary,
  },
  applyBtn: {
    backgroundColor: Semantic.primary,
    paddingVertical: Spacing.md,
    borderRadius: Radius.pill,
    alignItems: 'center',
    ...Shadows.extruded,
  },
  applyBtnPressed: {
    ...Shadows.none,
    backgroundColor: Semantic.primaryDark,
    transform: [{ scale: 0.97 }],
  },
  applyBtnDisabled: { opacity: 0.5 },
  applyBtnText: {
    color: Semantic.onPrimary,
    fontSize: TypeScale.body,
    fontWeight: '700',
  },
});
