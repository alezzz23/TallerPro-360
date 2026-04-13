import { useState } from 'react';
import { Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

import { Radius, Semantic, Shadows, Spacing, TypeScale } from '@/constants/theme';
import type { DamageRecord } from '@/types/api';

const ZONES = [
  'Frontal',
  'Trasero',
  'Lateral Izq.',
  'Lateral Der.',
  'Techo',
  'Capó',
  'Puerta FL',
  'Puerta FR',
  'Puerta RL',
  'Puerta RR',
] as const;

interface Props {
  damages: DamageRecord[];
  onAddDamage: (ubicacion: string, descripcion: string) => void;
  isAdding: boolean;
}

export function DamageZoneGrid({ damages, onAddDamage, isAdding }: Props) {
  const [selectedZone, setSelectedZone] = useState<string | null>(null);
  const [descripcion, setDescripcion] = useState('');

  const zoneHasDamage = (zone: string) =>
    damages.some((d) => d.ubicacion === zone);

  const handleSubmit = () => {
    if (!selectedZone) return;
    onAddDamage(selectedZone, descripcion);
    setSelectedZone(null);
    setDescripcion('');
  };

  return (
    <View style={styles.container}>
      <Text style={styles.sectionTitle}>Zonas del vehículo</Text>
      <Text style={styles.hint}>Toque una zona para registrar un daño</Text>

      <View style={styles.grid}>
        {ZONES.map((zone) => {
          const hasDamage = zoneHasDamage(zone);
          const isSelected = selectedZone === zone;
          return (
            <Pressable
              key={zone}
              style={[
                styles.zoneCell,
                hasDamage && styles.zoneCellDamaged,
                isSelected && styles.zoneCellSelected,
              ]}
              onPress={() => setSelectedZone(isSelected ? null : zone)}
            >
              <Text
                style={[
                  styles.zoneText,
                  hasDamage && styles.zoneTextDamaged,
                  isSelected && styles.zoneTextSelected,
                ]}
              >
                {zone}
              </Text>
              {hasDamage && <Ionicons name="warning" size={14} color={Semantic.danger} />}
            </Pressable>
          );
        })}
      </View>

      {selectedZone && (
        <View style={styles.inputCard}>
          <Text style={styles.inputLabel}>
            Daño en: <Text style={styles.inputZone}>{selectedZone}</Text>
          </Text>
          <TextInput
            style={styles.textInput}
            placeholder="Descripción del daño (opcional)"
            placeholderTextColor={Semantic.textMuted}
            value={descripcion}
            onChangeText={setDescripcion}
            multiline
          />
          <Pressable
            style={[styles.addBtn, isAdding && styles.addBtnDisabled]}
            onPress={handleSubmit}
            disabled={isAdding}
          >
            <Text style={styles.addBtnText}>
              {isAdding ? 'Registrando…' : 'Registrar Daño'}
            </Text>
          </Pressable>
        </View>
      )}

      {damages.length > 0 && (
        <View style={styles.damageList}>
          <Text style={styles.damageListTitle}>
            Daños registrados ({damages.length})
          </Text>
          {damages.map((d) => (
            <View key={d.id} style={styles.damageItem}>
              <Text style={styles.damageZone}>{d.ubicacion}</Text>
              {d.descripcion && (
                <Text style={styles.damageDesc}>{d.descripcion}</Text>
              )}
            </View>
          ))}
        </View>
      )}
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
  hint: { fontSize: TypeScale.label, color: Semantic.secondary },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Spacing.sm,
  },
  zoneCell: {
    width: '47%',
    backgroundColor: Semantic.surface,
    borderRadius: Radius.md,
    paddingVertical: 16,
    paddingHorizontal: Spacing.md,
    alignItems: 'center',
    borderWidth: 1.5,
    borderColor: Semantic.border,
    flexDirection: 'row',
    justifyContent: 'center',
    gap: Spacing.xs,
  },
  zoneCellDamaged: {
    borderColor: Semantic.danger,
    backgroundColor: '#2A1215',
  },
  zoneCellSelected: {
    borderColor: Semantic.primary,
    backgroundColor: Semantic.primaryMuted,
  },
  zoneText: {
    fontSize: TypeScale.label,
    color: Semantic.onSurface,
    fontWeight: '600',
  },
  zoneTextDamaged: { color: Semantic.danger },
  zoneTextSelected: { color: Semantic.primary },
  damageDot: { fontSize: 14 },
  inputCard: {
    backgroundColor: Semantic.primaryMuted,
    borderRadius: Radius.lg,
    padding: Spacing.md,
    borderLeftWidth: 4,
    borderLeftColor: Semantic.primary,
    gap: Spacing.sm,
  },
  inputLabel: {
    fontSize: TypeScale.body,
    color: Semantic.onSurface,
  },
  inputZone: { fontWeight: '700', color: Semantic.primary },
  textInput: {
    backgroundColor: Semantic.surfaceElevated,
    borderWidth: 1,
    borderColor: Semantic.border,
    borderRadius: Radius.md,
    padding: Spacing.md,
    fontSize: TypeScale.body,
    color: Semantic.onSurface,
    minHeight: 60,
    textAlignVertical: 'top',
  },
  addBtn: {
    backgroundColor: Semantic.primary,
    paddingVertical: 12,
    borderRadius: Radius.pill,
    alignItems: 'center',
    ...Shadows.extruded,
  },
  addBtnDisabled: { opacity: 0.5 },
  addBtnText: {
    color: Semantic.onPrimary,
    fontSize: TypeScale.label,
    fontWeight: '700',
  },
  damageList: {
    backgroundColor: Semantic.surface,
    borderRadius: Radius.lg,
    padding: Spacing.md,
    gap: Spacing.sm,
    borderTopWidth: 1,
    borderLeftWidth: 1,
    borderTopColor: Semantic.borderLight,
    borderLeftColor: Semantic.borderLight,
    ...Shadows.extruded,
  },
  damageListTitle: {
    fontSize: TypeScale.label,
    fontWeight: '700',
    color: Semantic.onSurface,
  },
  damageItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.sm,
    paddingVertical: Spacing.xs,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: Semantic.border,
  },
  damageZone: {
    fontSize: TypeScale.label,
    fontWeight: '600',
    color: Semantic.danger,
    minWidth: 90,
  },
  damageDesc: {
    fontSize: TypeScale.label,
    color: Semantic.secondary,
    flex: 1,
  },
});
