import { Pressable, StyleSheet, Text, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

import { Radius, Semantic, Shadows, Spacing, StatusColors, TypeScale } from '@/constants/theme';
import type { QualityCheck } from '@/types/api';

interface QCSummaryCardProps {
  qc: QualityCheck | null | undefined;
  totalItems: number;
  onPress?: () => void;
}

export function QCSummaryCard({ qc, totalItems, onPress }: QCSummaryCardProps) {
  const checkedCount = qc
    ? Object.values(qc.items_verificados).filter(Boolean).length
    : 0;

  return (
    <Pressable
      style={({ pressed }) => [styles.card, pressed && styles.cardPressed]}
      onPress={onPress}
      disabled={!onPress}
    >
      <View style={styles.header}>
        <Text style={styles.title}>Control de Calidad</Text>
        <View
          style={[
            styles.statusBadge,
            qc?.aprobado ? styles.statusApproved : styles.statusPending,
          ]}
        >
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
            <Ionicons
              name={qc?.aprobado ? 'checkmark' : 'time-outline'}
              size={12}
              color={qc?.aprobado ? Semantic.primary : Semantic.secondary}
            />
            <Text style={[styles.statusText, qc?.aprobado && { color: Semantic.primary }]}>
              {qc?.aprobado ? 'Aprobado' : 'Pendiente'}
            </Text>
          </View>
        </View>
      </View>

      <View style={styles.metricsRow}>
        <View style={styles.metric}>
          <Text style={styles.metricValue}>
            {checkedCount}/{totalItems}
          </Text>
          <Text style={styles.metricLabel}>Verificados</Text>
        </View>

        {qc?.km_delta != null && (
          <View style={styles.metric}>
            <Text style={styles.metricValue}>+{qc.km_delta.toLocaleString()}</Text>
            <Text style={styles.metricLabel}>km delta</Text>
          </View>
        )}

        {qc?.fecha && (
          <View style={styles.metric}>
            <Text style={styles.metricValue}>
              {new Date(qc.fecha).toLocaleDateString('es-MX', {
                day: '2-digit',
                month: 'short',
              })}
            </Text>
            <Text style={styles.metricLabel}>Fecha</Text>
          </View>
        )}
      </View>

      {/* Progress bar */}
      <View style={styles.progressTrack}>
        <View
          style={[
            styles.progressFill,
            {
              width: totalItems > 0 ? `${(checkedCount / totalItems) * 100}%` : '0%',
              backgroundColor: qc?.aprobado ? Semantic.success : Semantic.primary,
            },
          ]}
        />
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: Semantic.surface,
    borderRadius: Radius.lg,
    padding: Spacing.md,
    marginBottom: Spacing.sm,
    borderLeftWidth: 4,
    borderLeftColor: Semantic.primary,
    borderTopWidth: 1,
    borderTopColor: Semantic.borderLight,
    ...Shadows.extruded,
  },
  cardPressed: {
    ...Shadows.none,
    backgroundColor: '#111111',
    transform: [{ scale: 0.97 }],
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: Spacing.sm,
  },
  title: {
    fontSize: TypeScale.body,
    fontWeight: '700',
    color: Semantic.onSurface,
  },
  statusBadge: {
    paddingHorizontal: Spacing.sm,
    paddingVertical: 3,
    borderRadius: Radius.pill,
  },
  statusApproved: {
    backgroundColor: '#052E16',
  },
  statusPending: {
    backgroundColor: Semantic.surfaceElevated,
  },
  statusText: {
    fontSize: TypeScale.caption,
    fontWeight: '700',
    color: Semantic.secondary,
  },
  metricsRow: {
    flexDirection: 'row',
    gap: Spacing.lg,
    marginBottom: Spacing.sm,
  },
  metric: {
    alignItems: 'center',
  },
  metricValue: {
    fontSize: TypeScale.subtitle,
    fontWeight: '800',
    color: Semantic.primary,
  },
  metricLabel: {
    fontSize: TypeScale.caption,
    color: Semantic.textMuted,
    marginTop: 2,
  },
  progressTrack: {
    height: 6,
    backgroundColor: Semantic.border,
    borderRadius: 3,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    borderRadius: 3,
  },
});
