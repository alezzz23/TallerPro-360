import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

import { Radius, Semantic, Shadows, Spacing, StatusColors, TypeScale } from '@/constants/theme';
import type { DiagnosticFinding } from '@/types/api';

interface Props {
  finding: DiagnosticFinding;
  technicianName?: string;
}

export function FindingCard({ finding, technicianName }: Props) {
  const router = useRouter();

  return (
    <Pressable
      style={({ pressed }) => [
        styles.card,
        finding.es_critico_seguridad && styles.cardCritical,
        pressed && styles.pressed,
      ]}
      onPress={() =>
        router.push(`/(auth)/diagnosis/finding/${finding.id}?orderId=${finding.order_id}`)
      }
    >
      {/* Header row */}
      <View style={styles.header}>
        <Text style={styles.motivo} numberOfLines={1}>
          {finding.motivo_ingreso}
        </Text>
        <View style={styles.badges}>
          {finding.es_critico_seguridad && (
            <View style={styles.criticalBadge}>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
                <Ionicons name="warning" size={12} color={Semantic.danger} />
                <Text style={styles.criticalText}>Crítico</Text>
              </View>
            </View>
          )}
          {finding.es_hallazgo_adicional && (
            <View style={styles.additionalBadge}>
              <Text style={styles.additionalText}>Adicional</Text>
            </View>
          )}
        </View>
      </View>

      {/* Description */}
      {finding.descripcion ? (
        <Text style={styles.desc} numberOfLines={2}>
          {finding.descripcion}
        </Text>
      ) : null}

      {/* Footer stats */}
      <View style={styles.footer}>
        {finding.tiempo_estimado != null && (
          <View style={styles.statRow}>
            <Ionicons name="time-outline" size={12} color={Semantic.textMuted} />
            <Text style={styles.stat}>{finding.tiempo_estimado}h</Text>
          </View>
        )}
        <View style={styles.statRow}>
          <Ionicons name="camera-outline" size={12} color={Semantic.textMuted} />
          <Text style={styles.stat}>{finding.fotos.length}/10</Text>
        </View>
        <View style={styles.statRow}>
          <Ionicons name="build-outline" size={12} color={Semantic.textMuted} />
          <Text style={styles.stat}>{finding.parts.length} repuestos</Text>
        </View>
      </View>

      {technicianName ? (
        <Text style={styles.techLabel}>Técnico: {technicianName}</Text>
      ) : null}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: Semantic.surface,
    borderRadius: Radius.lg,
    borderLeftWidth: 4,
    borderLeftColor: StatusColors.DIAGNOSTICO,
    borderTopWidth: 1,
    borderTopColor: Semantic.borderLight,
    padding: Spacing.md,
    marginBottom: Spacing.sm,
    ...Shadows.extruded,
  },
  cardCritical: {
    borderLeftColor: Semantic.danger,
    borderWidth: 1,
    borderColor: Semantic.danger,
    backgroundColor: '#2A1215',
  },
  pressed: {
    ...Shadows.none,
    backgroundColor: '#111111',
    transform: [{ scale: 0.97 }],
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: Spacing.xs,
  },
  motivo: {
    fontSize: TypeScale.body,
    fontWeight: '700',
    color: Semantic.onSurface,
    flex: 1,
    marginRight: Spacing.sm,
  },
  badges: {
    flexDirection: 'row',
    gap: Spacing.xs,
  },
  criticalBadge: {
    backgroundColor: '#2A1215',
    paddingHorizontal: Spacing.sm,
    paddingVertical: 2,
    borderRadius: Radius.pill,
    borderWidth: 1,
    borderColor: Semantic.danger,
  },
  criticalText: {
    fontSize: TypeScale.caption,
    fontWeight: '700',
    color: Semantic.danger,
  },
  additionalBadge: {
    backgroundColor: '#0C1E3A',
    paddingHorizontal: Spacing.sm,
    paddingVertical: 2,
    borderRadius: Radius.pill,
    borderWidth: 1,
    borderColor: Semantic.info,
  },
  additionalText: {
    fontSize: TypeScale.caption,
    fontWeight: '600',
    color: Semantic.info,
  },
  desc: {
    fontSize: TypeScale.label,
    color: Semantic.secondary,
    marginBottom: Spacing.sm,
    lineHeight: 20,
  },
  footer: {
    flexDirection: 'row',
    gap: Spacing.md,
    marginTop: Spacing.xs,
  },
  statRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  stat: {
    fontSize: TypeScale.caption,
    color: Semantic.textMuted,
  },
  techLabel: {
    fontSize: TypeScale.caption,
    color: Semantic.primary,
    marginTop: Spacing.xs,
    fontWeight: '500',
  },
});
