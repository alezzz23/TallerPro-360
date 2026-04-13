import { useState } from 'react';
import {
  ActivityIndicator,
  Pressable,
  StyleSheet,
  Switch,
  Text,
  TextInput,
  View,
} from 'react-native';
import { Controller, useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';

import { partFormSchema, type PartFormData } from '@/schemas/diagnosis';
import { Radius, Semantic, Shadows, Spacing, TypeScale } from '@/constants/theme';

interface Props {
  onSubmit: (data: PartFormData) => void;
  isPending?: boolean;
  onCancel?: () => void;
}

export function PartForm({ onSubmit, isPending, onCancel }: Props) {
  const {
    control,
    handleSubmit,
    watch,
    formState: { errors },
  } = useForm<PartFormData>({
    resolver: zodResolver(partFormSchema),
    defaultValues: {
      nombre: '',
      origen: 'STOCK',
      costo: undefined as unknown as number,
      margen: 0.3,
      proveedor: '',
    },
  });

  const costo = watch('costo');
  const margen = watch('margen');
  const precioPreview =
    costo > 0 && margen >= 0 && margen < 1
      ? (costo / (1 - margen)).toFixed(2)
      : '—';

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Agregar Repuesto</Text>

      {/* Nombre */}
      <Text style={styles.label}>Nombre del repuesto *</Text>
      <Controller
        control={control}
        name="nombre"
        render={({ field: { onChange, onBlur, value } }) => (
          <TextInput
            style={styles.input}
            value={value}
            onChangeText={onChange}
            onBlur={onBlur}
            placeholder="Ej: Pastilla de freno"
            placeholderTextColor={Semantic.textMuted}
          />
        )}
      />
      {errors.nombre && <Text style={styles.error}>{errors.nombre.message}</Text>}

      {/* Origen */}
      <Text style={styles.label}>Origen</Text>
      <Controller
        control={control}
        name="origen"
        render={({ field: { onChange, value } }) => (
          <View style={styles.origenRow}>
            {(['STOCK', 'PEDIDO'] as const).map((o) => (
              <Pressable
                key={o}
                style={({ pressed }) => [
                  styles.origenBtn,
                  value === o && styles.origenBtnActive,
                  pressed && { opacity: 0.8, transform: [{ scale: 0.97 }] },
                ]}
                onPress={() => onChange(o)}
              >
                <Text
                  style={[
                    styles.origenText,
                    value === o && styles.origenTextActive,
                  ]}
                >
                  {o}
                </Text>
              </Pressable>
            ))}
          </View>
        )}
      />

      {/* Costo & Margen row */}
      <View style={styles.row}>
        <View style={{ flex: 1 }}>
          <Text style={styles.label}>Costo *</Text>
          <Controller
            control={control}
            name="costo"
            render={({ field: { onChange, onBlur, value } }) => (
              <TextInput
                style={styles.input}
                value={value != null && value !== (undefined as unknown as number) ? String(value) : ''}
                onChangeText={(t) => {
                  const n = parseFloat(t);
                  onChange(isNaN(n) ? undefined : n);
                }}
                onBlur={onBlur}
                placeholder="0.00"
                placeholderTextColor={Semantic.textMuted}
                keyboardType="decimal-pad"
              />
            )}
          />
          {errors.costo && (
            <Text style={styles.error}>{errors.costo.message}</Text>
          )}
        </View>
        <View style={{ width: Spacing.md }} />
        <View style={{ flex: 1 }}>
          <Text style={styles.label}>Margen (0-99%)</Text>
          <Controller
            control={control}
            name="margen"
            render={({ field: { onChange, onBlur, value } }) => (
              <TextInput
                style={styles.input}
                value={value != null ? String(Math.round(value * 100)) : ''}
                onChangeText={(t) => {
                  const n = parseInt(t, 10);
                  onChange(isNaN(n) ? undefined : n / 100);
                }}
                onBlur={onBlur}
                placeholder="30"
                placeholderTextColor={Semantic.textMuted}
                keyboardType="number-pad"
              />
            )}
          />
          {errors.margen && (
            <Text style={styles.error}>{errors.margen.message}</Text>
          )}
        </View>
      </View>

      {/* Precio preview */}
      <View style={styles.previewRow}>
        <Text style={styles.previewLabel}>Precio de venta:</Text>
        <Text style={styles.previewValue}>${precioPreview}</Text>
      </View>

      {/* Proveedor */}
      <Text style={styles.label}>Proveedor (opcional)</Text>
      <Controller
        control={control}
        name="proveedor"
        render={({ field: { onChange, onBlur, value } }) => (
          <TextInput
            style={styles.input}
            value={value}
            onChangeText={onChange}
            onBlur={onBlur}
            placeholder="Nombre del proveedor"
            placeholderTextColor={Semantic.textMuted}
          />
        )}
      />

      {/* Actions */}
      <View style={styles.actions}>
        {onCancel && (
          <Pressable
            style={({ pressed }) => [
              styles.cancelBtn,
              pressed && { opacity: 0.8, transform: [{ scale: 0.97 }] },
            ]}
            onPress={onCancel}
          >
            <Text style={styles.cancelText}>Cancelar</Text>
          </Pressable>
        )}
        <Pressable
          style={({ pressed }) => [
            styles.submitBtn,
            isPending && { opacity: 0.6 },
            pressed && styles.submitBtnPressed,
          ]}
          onPress={handleSubmit(onSubmit)}
          disabled={isPending}
        >
          {isPending ? (
            <ActivityIndicator color={Semantic.onPrimary} />
          ) : (
            <Text style={styles.submitText}>Agregar</Text>
          )}
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: Semantic.surface,
    borderRadius: Radius.lg,
    padding: Spacing.md,
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
  label: {
    fontSize: TypeScale.label,
    fontWeight: '600',
    color: Semantic.onSurface,
    marginTop: Spacing.sm,
    marginBottom: Spacing.xs,
  },
  input: {
    backgroundColor: Semantic.surfaceElevated,
    borderWidth: 1,
    borderColor: Semantic.border,
    borderRadius: Radius.md,
    padding: Spacing.sm + 4,
    fontSize: TypeScale.body,
    color: Semantic.onSurface,
  },
  error: {
    color: Semantic.danger,
    fontSize: TypeScale.caption,
    marginTop: 2,
  },
  origenRow: {
    flexDirection: 'row',
    gap: Spacing.sm,
  },
  origenBtn: {
    flex: 1,
    paddingVertical: Spacing.sm,
    borderRadius: Radius.pill,
    backgroundColor: Semantic.surface,
    borderWidth: 1,
    borderColor: Semantic.border,
    alignItems: 'center',
  },
  origenBtnActive: {
    backgroundColor: Semantic.primary,
    borderColor: Semantic.primary,
  },
  origenText: {
    fontSize: TypeScale.label,
    fontWeight: '600',
    color: Semantic.secondary,
  },
  origenTextActive: {
    color: Semantic.onPrimary,
  },
  row: {
    flexDirection: 'row',
  },
  previewRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: Semantic.surfaceElevated,
    padding: Spacing.sm + 4,
    borderRadius: Radius.md,
    marginTop: Spacing.sm,
    borderWidth: 1,
    borderColor: Semantic.primaryMuted,
  },
  previewLabel: {
    fontSize: TypeScale.label,
    color: Semantic.secondary,
  },
  previewValue: {
    fontSize: TypeScale.subtitle,
    fontWeight: '700',
    color: Semantic.success,
  },
  actions: {
    flexDirection: 'row',
    gap: Spacing.sm,
    marginTop: Spacing.lg,
  },
  cancelBtn: {
    flex: 1,
    paddingVertical: Spacing.sm + 4,
    borderRadius: Radius.pill,
    borderWidth: 1,
    borderColor: Semantic.border,
    alignItems: 'center',
  },
  cancelText: {
    fontSize: TypeScale.label,
    color: Semantic.secondary,
    fontWeight: '600',
  },
  submitBtn: {
    flex: 1,
    paddingVertical: Spacing.sm + 4,
    borderRadius: Radius.pill,
    backgroundColor: Semantic.primary,
    alignItems: 'center',
    ...Shadows.extruded,
  },
  submitBtnPressed: {
    ...Shadows.none,
    backgroundColor: Semantic.primaryDark,
    transform: [{ scale: 0.97 }],
  },
  submitText: {
    fontSize: TypeScale.label,
    fontWeight: '700',
    color: Semantic.onPrimary,
  },
});
