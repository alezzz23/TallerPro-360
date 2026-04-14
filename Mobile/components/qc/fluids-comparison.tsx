import { Pressable, StyleSheet, Text, TextInput, View } from 'react-native';

import { Radius, Semantic, Shadows, Spacing, TypeScale } from '@/constants/theme';
import { FLUID_LEVELS, type FluidLevel } from '@/schemas/qc';
import type { ReceptionChecklist } from '@/types/api';

interface FluidsComparisonProps {
  checklist: ReceptionChecklist | null | undefined;
  kmIngreso: number | null | undefined;
  kmSalida: number | null | undefined;
  nivelAceiteSalida: string | null | undefined;
  nivelRefrigeranteSalida: string | null | undefined;
  nivelFrenosSalida: string | null | undefined;
  onChangeKmSalida: (value: number | null) => void;
  onChangeAceite: (value: FluidLevel) => void;
  onChangeRefrigerante: (value: FluidLevel) => void;
  onChangeFrenos: (value: FluidLevel) => void;
  readOnly?: boolean;
}

const LEVEL_COLORS: Record<string, string> = {
  BAJO: Semantic.danger,
  MEDIO: Semantic.warning,
  ALTO: Semantic.success,
};

function LevelBadge({ level }: { level: string | null | undefined }) {
  if (!level) return <Text style={styles.naText}>—</Text>;
  return (
    <View style={[styles.levelBadge, { backgroundColor: LEVEL_COLORS[level] ?? Semantic.secondary }]}>
      <Text style={styles.levelBadgeText}>{level}</Text>
    </View>
  );
}

function LevelPicker({
  value,
  onChange,
  disabled,
}: {
  value: string | null | undefined;
  onChange: (v: FluidLevel) => void;
  disabled?: boolean;
}) {
  return (
    <View style={styles.pickerRow}>
      {FLUID_LEVELS.map((lvl) => {
        const active = value === lvl;
        return (
          <Pressable
            key={lvl}
            style={[
              styles.pickerOption,
              { borderColor: LEVEL_COLORS[lvl] },
              active && { backgroundColor: LEVEL_COLORS[lvl] },
            ]}
            onPress={() => !disabled && onChange(lvl)}
            disabled={disabled}
          >
            <Text
              style={[styles.pickerText, active && styles.pickerTextActive]}
            >
              {lvl}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

function DeltaArrow({ ingreso, salida }: { ingreso: string | null | undefined; salida: string | null | undefined }) {
  if (!ingreso || !salida) return null;
  const levels = ['BAJO', 'MEDIO', 'ALTO'];
  const inIdx = levels.indexOf(ingreso);
  const outIdx = levels.indexOf(salida);
  if (inIdx < 0 || outIdx < 0) return null;
  const isUp = outIdx >= inIdx;
  return (
    <Text style={[styles.arrow, { color: isUp ? Semantic.success : Semantic.danger }]}>
      {isUp ? '▲' : '▼'}
    </Text>
  );
}

export function FluidsComparison({
  checklist,
  kmIngreso,
  kmSalida,
  nivelAceiteSalida,
  nivelRefrigeranteSalida,
  nivelFrenosSalida,
  onChangeKmSalida,
  onChangeAceite,
  onChangeRefrigerante,
  onChangeFrenos,
  readOnly,
}: FluidsComparisonProps) {
  const kmDelta =
    kmIngreso != null && kmSalida != null ? kmSalida - kmIngreso : null;

  return (
    <View style={styles.container}>
      <Text style={styles.sectionTitle}>Comparación Ingreso vs Salida</Text>

      {/* Column headers */}
      <View style={styles.colHeaders}>
        <View style={styles.labelCol} />
        <View style={styles.valueCol}>
          <Text style={styles.colLabel}>INGRESO</Text>
        </View>
        <View style={styles.arrowCol} />
        <View style={styles.valueCol}>
          <Text style={[styles.colLabel, styles.colLabelSalida]}>SALIDA</Text>
        </View>
      </View>

      {/* Kilometraje */}
      <View style={styles.compRow}>
        <Text style={styles.rowLabel}>Km</Text>
        <View style={styles.valueCol}>
          <Text style={styles.valueText}>
            {kmIngreso != null ? kmIngreso.toLocaleString() : '—'}
          </Text>
        </View>
        <View style={styles.arrowCol}>
          {kmDelta != null && (
            <Text style={[styles.arrow, { color: kmDelta >= 0 ? Semantic.success : Semantic.danger }]}>
              {kmDelta >= 0 ? '▲' : '▼'}
            </Text>
          )}
        </View>
        <View style={styles.valueCol}>
          {readOnly ? (
            <Text style={styles.valueText}>
              {kmSalida != null ? kmSalida.toLocaleString() : '—'}
            </Text>
          ) : (
            <TextInput
              style={styles.input}
              value={kmSalida != null ? String(kmSalida) : ''}
              onChangeText={(t) => {
                const num = parseInt(t, 10);
                onChangeKmSalida(isNaN(num) ? null : num);
              }}
              keyboardType="numeric"
              placeholder="Km"
              placeholderTextColor={Semantic.textMuted}
            />
          )}
        </View>
      </View>

      {kmDelta != null && (
        <View style={styles.deltaRow}>
          <Text style={styles.deltaText}>+{kmDelta.toLocaleString()} km</Text>
        </View>
      )}

      {/* Aceite */}
      <View style={styles.compRow}>
        <Text style={styles.rowLabel}>Aceite</Text>
        <View style={styles.valueCol}>
          <LevelBadge level={checklist?.nivel_aceite} />
        </View>
        <View style={styles.arrowCol}>
          <DeltaArrow ingreso={checklist?.nivel_aceite} salida={nivelAceiteSalida} />
        </View>
        <View style={styles.valueCol}>
          {readOnly ? (
            <LevelBadge level={nivelAceiteSalida} />
          ) : (
            <LevelPicker value={nivelAceiteSalida} onChange={onChangeAceite} disabled={readOnly} />
          )}
        </View>
      </View>

      {/* Refrigerante */}
      <View style={styles.compRow}>
        <Text style={styles.rowLabel}>Refrigerante</Text>
        <View style={styles.valueCol}>
          <LevelBadge level={checklist?.nivel_refrigerante} />
        </View>
        <View style={styles.arrowCol}>
          <DeltaArrow ingreso={checklist?.nivel_refrigerante} salida={nivelRefrigeranteSalida} />
        </View>
        <View style={styles.valueCol}>
          {readOnly ? (
            <LevelBadge level={nivelRefrigeranteSalida} />
          ) : (
            <LevelPicker value={nivelRefrigeranteSalida} onChange={onChangeRefrigerante} disabled={readOnly} />
          )}
        </View>
      </View>

      {/* Frenos */}
      <View style={styles.compRow}>
        <Text style={styles.rowLabel}>Frenos</Text>
        <View style={styles.valueCol}>
          <LevelBadge level={checklist?.nivel_frenos} />
        </View>
        <View style={styles.arrowCol}>
          <DeltaArrow ingreso={checklist?.nivel_frenos} salida={nivelFrenosSalida} />
        </View>
        <View style={styles.valueCol}>
          {readOnly ? (
            <LevelBadge level={nivelFrenosSalida} />
          ) : (
            <LevelPicker value={nivelFrenosSalida} onChange={onChangeFrenos} disabled={readOnly} />
          )}
        </View>
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
  sectionTitle: {
    fontSize: TypeScale.subtitle,
    fontWeight: '700',
    color: Semantic.onSurface,
    marginBottom: Spacing.md,
  },
  colHeaders: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: Spacing.sm,
    paddingBottom: Spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: Semantic.border,
  },
  labelCol: {
    width: 90,
  },
  valueCol: {
    flex: 1,
    alignItems: 'center',
  },
  arrowCol: {
    width: 28,
    alignItems: 'center',
  },
  colLabel: {
    fontSize: TypeScale.caption,
    fontWeight: '700',
    color: Semantic.secondary,
    letterSpacing: 1,
  },
  colLabelSalida: {
    color: Semantic.primary,
  },
  compRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: Spacing.sm,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: Semantic.border,
  },
  rowLabel: {
    width: 90,
    fontSize: TypeScale.label,
    fontWeight: '600',
    color: Semantic.onSurface,
  },
  valueText: {
    fontSize: TypeScale.body,
    fontWeight: '600',
    color: Semantic.onSurface,
  },
  naText: {
    fontSize: TypeScale.body,
    color: Semantic.textMuted,
  },
  input: {
    backgroundColor: Semantic.surfaceElevated,
    borderWidth: 1,
    borderColor: Semantic.border,
    borderRadius: Radius.sm,
    paddingHorizontal: Spacing.sm,
    paddingVertical: 6,
    fontSize: TypeScale.label,
    color: Semantic.onSurface,
    textAlign: 'center',
    minWidth: 80,
  },
  deltaRow: {
    alignItems: 'center',
    paddingVertical: 4,
  },
  deltaText: {
    fontSize: TypeScale.caption,
    fontWeight: '700',
    color: Semantic.primary,
    backgroundColor: Semantic.primaryMuted,
    paddingHorizontal: Spacing.sm,
    paddingVertical: 2,
    borderRadius: Radius.sm,
    overflow: 'hidden',
  },
  arrow: {
    fontSize: 14,
    fontWeight: '700',
  },
  levelBadge: {
    paddingHorizontal: Spacing.sm,
    paddingVertical: 3,
    borderRadius: Radius.pill,
  },
  levelBadgeText: {
    color: '#fff',
    fontSize: TypeScale.caption,
    fontWeight: '700',
  },
  pickerRow: {
    flexDirection: 'row',
    gap: 4,
  },
  pickerOption: {
    borderWidth: 1.5,
    borderRadius: Radius.sm,
    paddingHorizontal: 6,
    paddingVertical: 3,
  },
  pickerText: {
    fontSize: 10,
    fontWeight: '700',
    color: Semantic.secondary,
  },
  pickerTextActive: {
    color: '#fff',
  },
});
