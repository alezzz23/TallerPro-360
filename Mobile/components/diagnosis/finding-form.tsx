import { useEffect } from 'react';
import {
  ActivityIndicator,
  Pressable,
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  TextInput,
  View,
} from 'react-native';
import { Controller, useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Ionicons } from '@expo/vector-icons';

import { findingFormSchema, type FindingFormData } from '@/schemas/diagnosis';
import { useTechnicians } from '@/hooks/use-diagnosis';
import { Radius, Semantic, Shadows, Spacing, StatusColors, TypeScale } from '@/constants/theme';

interface Props {
  defaultValues?: Partial<FindingFormData>;
  /** Lock motivo_ingreso for edits */
  lockMotivo?: boolean;
  onSubmit: (data: FindingFormData) => void;
  isPending?: boolean;
  submitLabel?: string;
}

export function FindingForm({
  defaultValues,
  lockMotivo,
  onSubmit,
  isPending,
  submitLabel = 'Guardar Hallazgo',
}: Props) {
  const { data: technicians, isLoading: loadingTechs } = useTechnicians();

  const {
    control,
    handleSubmit,
    formState: { errors },
    setValue,
  } = useForm<FindingFormData>({
    resolver: zodResolver(findingFormSchema),
    defaultValues: {
      motivo_ingreso: '',
      descripcion: '',
      tiempo_estimado: undefined,
      technician_id: '',
      es_hallazgo_adicional: false,
      es_critico_seguridad: false,
      ...defaultValues,
    },
  });

  // Pre-select first technician if no default
  useEffect(() => {
    if (technicians?.length && !defaultValues?.technician_id) {
      setValue('technician_id', technicians[0].id);
    }
  }, [technicians, defaultValues?.technician_id, setValue]);

  return (
    <ScrollView style={styles.container} keyboardShouldPersistTaps="handled">
      {/* Motivo de Ingreso */}
      <Text style={styles.label}>Motivo de Ingreso *</Text>
      <Controller
        control={control}
        name="motivo_ingreso"
        render={({ field: { onChange, onBlur, value } }) => (
          <TextInput
            style={[styles.input, lockMotivo && styles.inputDisabled]}
            value={value}
            onChangeText={onChange}
            onBlur={onBlur}
            placeholder="Ej: Revisión de frenos"
            placeholderTextColor={Semantic.textMuted}
            editable={!lockMotivo}
          />
        )}
      />
      {errors.motivo_ingreso && (
        <Text style={styles.error}>{errors.motivo_ingreso.message}</Text>
      )}

      {/* Descripción */}
      <Text style={styles.label}>Descripción</Text>
      <Controller
        control={control}
        name="descripcion"
        render={({ field: { onChange, onBlur, value } }) => (
          <TextInput
            style={[styles.input, styles.multiline]}
            value={value}
            onChangeText={onChange}
            onBlur={onBlur}
            placeholder="Detalle del hallazgo..."
            placeholderTextColor={Semantic.textMuted}
            multiline
            numberOfLines={4}
            textAlignVertical="top"
          />
        )}
      />

      {/* Tiempo estimado */}
      <Text style={styles.label}>Tiempo Estimado (horas)</Text>
      <Controller
        control={control}
        name="tiempo_estimado"
        render={({ field: { onChange, onBlur, value } }) => (
          <TextInput
            style={styles.input}
            value={value != null ? String(value) : ''}
            onChangeText={(t) => {
              const n = parseFloat(t);
              onChange(isNaN(n) ? undefined : n);
            }}
            onBlur={onBlur}
            placeholder="Ej: 1.5"
            placeholderTextColor={Semantic.textMuted}
            keyboardType="decimal-pad"
          />
        )}
      />
      {errors.tiempo_estimado && (
        <Text style={styles.error}>{errors.tiempo_estimado.message}</Text>
      )}

      {/* Technician Picker */}
      <Text style={styles.label}>Técnico Asignado *</Text>
      {loadingTechs ? (
        <ActivityIndicator color={Semantic.primary} />
      ) : (
        <Controller
          control={control}
          name="technician_id"
          render={({ field: { onChange, value } }) => (
            <View style={styles.pickerRow}>
              {technicians?.map((t) => (
                <Pressable
                  key={t.id}
                  style={({ pressed }) => [
                    styles.pickerChip,
                    value === t.id && styles.pickerChipActive,
                    pressed && { opacity: 0.8, transform: [{ scale: 0.97 }] },
                  ]}
                  onPress={() => onChange(t.id)}
                >
                  <Text
                    style={[
                      styles.pickerChipText,
                      value === t.id && styles.pickerChipTextActive,
                    ]}
                  >
                    {t.nombre}
                  </Text>
                </Pressable>
              ))}
            </View>
          )}
        />
      )}
      {errors.technician_id && (
        <Text style={styles.error}>{errors.technician_id.message}</Text>
      )}

      {/* Safety-critical toggle */}
      <View style={styles.switchRow}>
        <View style={{ flex: 1 }}>
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
            <Ionicons name="warning-outline" size={16} color={Semantic.danger} />
            <Text style={styles.label}>Crítico de Seguridad</Text>
          </View>
          <Text style={styles.hint}>
            Se mostrará alerta visual y se notificará al asesor
          </Text>
        </View>
        <Controller
          control={control}
          name="es_critico_seguridad"
          render={({ field: { onChange, value } }) => (
            <Switch
              value={value}
              onValueChange={onChange}
              trackColor={{ false: '#2A2A2A', true: '#7F1D1D' }}
              thumbColor={value ? Semantic.danger : '#525252'}
            />
          )}
        />
      </View>

      {/* Submit */}
      <Pressable
        style={({ pressed }) => [
          styles.submitBtn,
          isPending && styles.submitBtnDisabled,
          pressed && styles.submitBtnPressed,
        ]}
        onPress={handleSubmit(onSubmit)}
        disabled={isPending}
      >
        {isPending ? (
          <ActivityIndicator color={Semantic.onPrimary} />
        ) : (
          <Text style={styles.submitText}>{submitLabel}</Text>
        )}
      </Pressable>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  label: {
    fontSize: TypeScale.label,
    fontWeight: '600',
    color: Semantic.onSurface,
    marginTop: Spacing.md,
    marginBottom: Spacing.xs,
  },
  hint: {
    fontSize: TypeScale.caption,
    color: Semantic.textMuted,
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
  inputDisabled: {
    backgroundColor: '#121212',
    color: Semantic.textMuted,
  },
  multiline: {
    minHeight: 100,
  },
  error: {
    color: Semantic.danger,
    fontSize: TypeScale.caption,
    marginTop: 2,
  },
  pickerRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Spacing.sm,
  },
  pickerChip: {
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    borderRadius: Radius.pill,
    backgroundColor: Semantic.surface,
    borderWidth: 1,
    borderColor: Semantic.border,
  },
  pickerChipActive: {
    backgroundColor: Semantic.primary,
    borderColor: Semantic.primary,
  },
  pickerChipText: {
    fontSize: TypeScale.label,
    color: Semantic.secondary,
  },
  pickerChipTextActive: {
    color: Semantic.onPrimary,
    fontWeight: '700',
  },
  switchRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: Spacing.lg,
    paddingVertical: Spacing.sm,
    gap: Spacing.md,
  },
  submitBtn: {
    backgroundColor: Semantic.primary,
    paddingVertical: Spacing.md,
    borderRadius: Radius.pill,
    alignItems: 'center',
    marginTop: Spacing.xl,
    marginBottom: Spacing.xxl,
    ...Shadows.extruded,
  },
  submitBtnPressed: {
    ...Shadows.none,
    backgroundColor: Semantic.primaryDark,
    transform: [{ scale: 0.97 }],
  },
  submitBtnDisabled: {
    opacity: 0.6,
  },
  submitText: {
    color: Semantic.onPrimary,
    fontSize: TypeScale.body,
    fontWeight: '700',
  },
});
