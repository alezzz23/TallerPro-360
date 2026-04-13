import { StyleSheet, Text, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

import { Radius, Semantic, Shadows, Spacing, TypeScale } from '@/constants/theme';
import { NPS_CATEGORIES } from '@/schemas/billing';
import type { NPSSurvey } from '@/types/api';

interface NPSSummaryProps {
  survey: NPSSurvey;
}

function npsColor(val: number): string {
  if (val >= 9) return Semantic.primary;
  if (val >= 7) return '#EAB308';
  return '#EF4444';
}

export function NPSSummary({ survey }: NPSSummaryProps) {
  const scores = NPS_CATEGORIES.map((c) => ({
    ...c,
    score: survey[c.key as keyof NPSSurvey] as number,
  }));
  const avg = scores.reduce((s, c) => s + c.score, 0) / scores.length;
  const fecha = new Date(survey.fecha).toLocaleDateString('es-CO', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  });

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.sectionTitle}>Encuesta NPS</Text>
        <View style={styles.badge}>
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
            <Ionicons name="checkmark" size={14} color={Semantic.primary} />
            <Text style={styles.badgeText}>Completada</Text>
          </View>
        </View>
      </View>

      {/* Average */}
      <View style={[styles.avgBox, { backgroundColor: npsColor(avg) + '18' }]}>
        <Text style={[styles.avgLabel, { color: npsColor(avg) }]}>Promedio</Text>
        <Text style={[styles.avgScore, { color: npsColor(avg) }]}>
          {avg.toFixed(1)}
        </Text>
      </View>

      {/* Category scores */}
      {scores.map((cat) => (
        <View key={cat.key} style={styles.row}>
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
            <Ionicons name={cat.icon as any} size={16} color={Semantic.secondary} />
            <Text style={styles.catLabel}>{cat.label}</Text>
          </View>
          <View style={[styles.scoreBadge, { backgroundColor: npsColor(cat.score) + '18' }]}>
            <Text style={[styles.scoreText, { color: npsColor(cat.score) }]}>
              {cat.score}
            </Text>
          </View>
        </View>
      ))}

      {/* Comentarios */}
      {survey.comentarios ? (
        <View style={styles.commentBox}>
          <Text style={styles.commentLabel}>Comentarios</Text>
          <Text style={styles.commentText}>{survey.comentarios}</Text>
        </View>
      ) : null}

      <Text style={styles.fecha}>{fecha}</Text>
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
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: Spacing.md,
  },
  sectionTitle: {
    fontSize: TypeScale.subtitle,
    fontWeight: '700',
    color: Semantic.onSurface,
  },
  badge: {
    backgroundColor: Semantic.primaryMuted,
    borderRadius: Radius.pill,
    paddingHorizontal: 12,
    paddingVertical: 4,
  },
  badgeText: {
    fontSize: TypeScale.caption,
    fontWeight: '700',
    color: Semantic.primary,
  },
  avgBox: {
    borderRadius: Radius.md,
    padding: Spacing.md,
    alignItems: 'center',
    marginBottom: Spacing.md,
  },
  avgLabel: {
    fontSize: TypeScale.label,
    fontWeight: '600',
  },
  avgScore: {
    fontSize: TypeScale.headline,
    fontWeight: '800',
    marginTop: Spacing.xs,
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Spacing.sm,
    borderTopWidth: 1,
    borderTopColor: Semantic.border,
  },
  catLabel: {
    fontSize: TypeScale.label,
    color: Semantic.onSurface,
    flexShrink: 1,
  },
  scoreBadge: {
    width: 36,
    height: 36,
    borderRadius: 18,
    alignItems: 'center',
    justifyContent: 'center',
  },
  scoreText: {
    fontSize: TypeScale.body,
    fontWeight: '700',
  },
  commentBox: {
    marginTop: Spacing.sm,
    padding: Spacing.sm,
    backgroundColor: Semantic.surfaceElevated,
    borderRadius: Radius.sm,
  },
  commentLabel: {
    fontSize: TypeScale.caption,
    fontWeight: '600',
    color: Semantic.secondary,
    marginBottom: Spacing.xs,
  },
  commentText: {
    fontSize: TypeScale.label,
    color: Semantic.onSurface,
  },
  fecha: {
    fontSize: TypeScale.caption,
    color: Semantic.textMuted,
    textAlign: 'right',
    marginTop: Spacing.sm,
  },
});
