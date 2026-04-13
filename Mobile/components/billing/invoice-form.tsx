import { useCallback, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';

import { Radius, Semantic, Shadows, Spacing, TypeScale } from '@/constants/theme';
import { METODO_PAGO_OPTIONS } from '@/schemas/billing';
import { useCreateInvoice } from '@/hooks/use-billing';
import { formatCurrency } from '@/utils/currency';
import type { MetodoPago } from '@/types/api';

interface InvoiceFormProps {
  orderId: string;
  montoTotal: number;
}

export function InvoiceForm({ orderId, montoTotal }: InvoiceFormProps) {
  const [metodoPago, setMetodoPago] = useState<MetodoPago | null>(null);
  const [saldoPendiente, setSaldoPendiente] = useState('');
  const createInvoice = useCreateInvoice();

  const esCred = metodoPago === 'CREDITO';

  const handleSubmit = useCallback(() => {
    if (!metodoPago) {
      Alert.alert('Error', 'Seleccione un método de pago.');
      return;
    }
    if (esCred && (!saldoPendiente || Number(saldoPendiente) <= 0)) {
      Alert.alert('Error', 'Ingrese el saldo pendiente para crédito.');
      return;
    }

    Alert.alert(
      'Generar Factura',
      `¿Confirma la factura por ${formatCurrency(montoTotal)} con ${metodoPago}?`,
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Confirmar',
          onPress: async () => {
            try {
              await createInvoice.mutateAsync({
                orderId,
                data: {
                  metodo_pago: metodoPago,
                  es_credito: esCred,
                  saldo_pendiente: esCred ? Number(saldoPendiente) : 0,
                },
              });
              Alert.alert('Factura generada', 'La factura fue creada exitosamente.');
            } catch (e: any) {
              Alert.alert(
                'Error',
                e?.response?.data?.detail ?? 'No se pudo generar la factura.',
              );
            }
          },
        },
      ],
    );
  }, [metodoPago, saldoPendiente, esCred, montoTotal, orderId, createInvoice]);

  return (
    <View style={styles.container}>
      <Text style={styles.sectionTitle}>Facturación</Text>

      {/* Total */}
      <View style={styles.totalBox}>
        <Text style={styles.totalLabel}>Total a facturar</Text>
        <Text style={styles.totalAmount}>{formatCurrency(montoTotal)}</Text>
      </View>

      {/* Payment method cards */}
      <Text style={styles.fieldLabel}>Método de pago</Text>
      <View style={styles.methodGrid}>
        {METODO_PAGO_OPTIONS.map((opt) => {
          const selected = metodoPago === opt.value;
          return (
            <Pressable
              key={opt.value}
              style={({ pressed }) => [
                styles.methodCard,
                selected && styles.methodCardSelected,
                pressed && { opacity: 0.8, transform: [{ scale: 0.97 }] },
              ]}
              onPress={() => setMetodoPago(opt.value as MetodoPago)}
            >
              <Ionicons
                name={opt.icon as any}
                size={28}
                color={selected ? Semantic.primary : Semantic.secondary}
                style={{ marginBottom: Spacing.xs }}
              />
              <Text
                style={[styles.methodLabel, selected && styles.methodLabelSelected]}
              >
                {opt.label}
              </Text>
            </Pressable>
          );
        })}
      </View>

      {/* Saldo pendiente for crédito */}
      {esCred && (
        <View style={styles.creditField}>
          <Text style={styles.fieldLabel}>Saldo pendiente</Text>
          <TextInput
            style={styles.input}
            keyboardType="numeric"
            placeholder="0"
            placeholderTextColor={Semantic.textMuted}
            value={saldoPendiente}
            onChangeText={setSaldoPendiente}
          />
        </View>
      )}

      {/* Submit */}
      <Pressable
        style={[
          styles.submitBtn,
          (!metodoPago || createInvoice.isPending) && styles.btnDisabled,
        ]}
        onPress={handleSubmit}
        disabled={!metodoPago || createInvoice.isPending}
      >
        {createInvoice.isPending ? (
          <ActivityIndicator color={Semantic.onPrimary} size="small" />
        ) : (
          <Text style={styles.submitText}>Generar Factura</Text>
        )}
      </Pressable>
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
  sectionTitle: {
    fontSize: TypeScale.subtitle,
    fontWeight: '700',
    color: Semantic.onSurface,
    marginBottom: Spacing.md,
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
  fieldLabel: {
    fontSize: TypeScale.label,
    fontWeight: '600',
    color: Semantic.secondary,
    marginBottom: Spacing.sm,
  },
  methodGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Spacing.sm,
    marginBottom: Spacing.md,
  },
  methodCard: {
    flex: 1,
    minWidth: '45%',
    borderWidth: 2,
    borderColor: Semantic.border,
    borderRadius: Radius.lg,
    paddingVertical: Spacing.md,
    alignItems: 'center',
    backgroundColor: Semantic.surfaceElevated,
  },
  methodCardSelected: {
    borderColor: Semantic.primary,
    backgroundColor: Semantic.primaryMuted,
  },
  methodLabel: {
    fontSize: TypeScale.label,
    fontWeight: '600',
    color: Semantic.secondary,
  },
  methodLabelSelected: {
    color: Semantic.primary,
  },
  creditField: {
    marginBottom: Spacing.md,
  },
  input: {
    backgroundColor: Semantic.surfaceElevated,
    borderWidth: 1,
    borderColor: Semantic.border,
    borderRadius: Radius.md,
    padding: Spacing.sm,
    fontSize: TypeScale.body,
    color: Semantic.onSurface,
  },
  submitBtn: {
    backgroundColor: Semantic.primary,
    borderRadius: Radius.pill,
    paddingVertical: 14,
    alignItems: 'center',
    ...Shadows.extruded,
  },
  btnDisabled: {
    opacity: 0.5,
  },
  submitText: {
    color: Semantic.onPrimary,
    fontSize: TypeScale.body,
    fontWeight: '700',
  },
});
