import { Controller, useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Pressable, StyleSheet, Switch, Text, View } from 'react-native';

import { Semantic, Spacing, TypeScale, Radius, Shadows } from '@/constants/theme';
import { checklistSchema, type ChecklistFormData } from '@/schemas/reception';

const FLUID_LEVELS = ['BAJO', 'MEDIO', 'ALTO'] as const;
const FLUID_COLORS: Record<string, string> = {
  BAJO: Semantic.danger,
  MEDIO: Semantic.warning,
  ALTO: Semantic.success,
};

interface Props {
  onSubmit: (data: ChecklistFormData) => void;
  isLoading: boolean;
}

function FluidSelector({
  label,
  value,
  onChange,
}: {
  label: string;
  value: string | undefined;
  onChange: (v: string) => void;
}) {
  return (
    <View style={styles.fluidRow}>
      <Text style={styles.fluidLabel}>{label}</Text>
      <View style={styles.fluidOptions}>
        {FLUID_LEVELS.map((level) => {
          const active = value === level;
          return (
            <Pressable
              key={level}
              onPress={() => onChange(level)}
              style={[
                styles.fluidPill,
                active && { backgroundColor: FLUID_COLORS[level] },
              ]}
            >
              <Text
                style={[
                  styles.fluidPillText,
                  active && styles.fluidPillTextActive,
                ]}
              >
                {level}
              </Text>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

function ToggleRow({
  label,
  value,
  onChange,
}: {
  label: string;
  value: boolean;
  onChange: (v: boolean) => void;
}) {
  return (
    <View style={styles.toggleRow}>
      <Text style={styles.toggleLabel}>{label}</Text>
      <Switch
        value={value}
        onValueChange={onChange}
        trackColor={{ false: '#2A2A2A', true: Semantic.primaryMuted }}
        thumbColor={value ? Semantic.primary : '#525252'}
      />
    </View>
  );
}

export function ChecklistForm({ onSubmit, isLoading }: Props) {
  const { control, handleSubmit } = useForm<ChecklistFormData>({
    resolver: zodResolver(checklistSchema),
    defaultValues: {
      nivel_aceite: undefined,
      nivel_refrigerante: undefined,
      nivel_frenos: undefined,
      llanta_repuesto: false,
      kit_carretera: false,
      botiquin: false,
      extintor: false,
      documentos_recibidos: '',
    },
  });

  return (
    <View style={styles.container}>
      {/* Fluid Levels */}
      <Text style={styles.sectionTitle}>Niveles de fluidos</Text>
      <View style={styles.card}>
        <Controller
          control={control}
          name="nivel_aceite"
          render={({ field: { value, onChange } }) => (
            <FluidSelector label="Aceite" value={value} onChange={onChange} />
          )}
        />
        <Controller
          control={control}
          name="nivel_refrigerante"
          render={({ field: { value, onChange } }) => (
            <FluidSelector label="Refrigerante" value={value} onChange={onChange} />
          )}
        />
        <Controller
          control={control}
          name="nivel_frenos"
          render={({ field: { value, onChange } }) => (
            <FluidSelector label="Frenos" value={value} onChange={onChange} />
          )}
        />
      </View>

      {/* Accessories */}
      <Text style={styles.sectionTitle}>Accesorios</Text>
      <View style={styles.card}>
        <Controller
          control={control}
          name="llanta_repuesto"
          render={({ field: { value, onChange } }) => (
            <ToggleRow label="Llanta de repuesto" value={value} onChange={onChange} />
          )}
        />
        <Controller
          control={control}
          name="kit_carretera"
          render={({ field: { value, onChange } }) => (
            <ToggleRow label="Kit de carretera" value={value} onChange={onChange} />
          )}
        />
        <Controller
          control={control}
          name="botiquin"
          render={({ field: { value, onChange } }) => (
            <ToggleRow label="Botiquín" value={value} onChange={onChange} />
          )}
        />
        <Controller
          control={control}
          name="extintor"
          render={({ field: { value, onChange } }) => (
            <ToggleRow label="Extintor" value={value} onChange={onChange} />
          )}
        />
      </View>

      <Pressable
        style={({ pressed }) => [
          styles.submitBtn,
          pressed && styles.submitBtnPressed,
          isLoading && styles.submitBtnDisabled,
        ]}
        onPress={handleSubmit(onSubmit)}
        disabled={isLoading}
      >
        <Text style={styles.submitText}>
          {isLoading ? 'Guardando…' : 'Guardar y Continuar'}
        </Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { gap: Spacing.md },
  sectionTitle: {
    fontSize: TypeScale.subtitle,
    fontWeight: '700',
    color: Semantic.onSurface,
  },
  card: {
    backgroundColor: Semantic.surface,
    borderRadius: Radius.lg,
    padding: Spacing.md,
    borderTopWidth: 1,
    borderLeftWidth: 1,
    borderTopColor: Semantic.borderLight,
    borderLeftColor: Semantic.borderLight,
    ...Shadows.extruded,
    gap: Spacing.sm,
  },
  fluidRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: Spacing.xs,
  },
  fluidLabel: {
    fontSize: TypeScale.body,
    color: Semantic.onSurface,
    flex: 1,
  },
  fluidOptions: { flexDirection: 'row', gap: Spacing.xs },
  fluidPill: {
    paddingHorizontal: 14,
    paddingVertical: 6,
    borderRadius: Radius.pill,
    backgroundColor: Semantic.surfaceElevated,
    borderWidth: 1,
    borderColor: Semantic.border,
  },
  fluidPillText: {
    fontSize: TypeScale.caption,
    fontWeight: '600',
    color: Semantic.secondary,
  },
  fluidPillTextActive: { color: '#fff' },
  toggleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: Spacing.xs,
  },
  toggleLabel: { fontSize: TypeScale.body, color: Semantic.onSurface },
  submitBtn: {
    backgroundColor: Semantic.primary,
    paddingVertical: 16,
    borderRadius: Radius.pill,
    alignItems: 'center',
    marginTop: Spacing.sm,
    ...Shadows.extruded,
  },
  submitBtnPressed: {
    ...Shadows.none,
    backgroundColor: Semantic.primaryDark,
    transform: [{ scale: 0.97 }],
  },
  submitBtnDisabled: { opacity: 0.5 },
  submitText: {
    color: Semantic.onPrimary,
    fontSize: TypeScale.body,
    fontWeight: '700',
  },
});
