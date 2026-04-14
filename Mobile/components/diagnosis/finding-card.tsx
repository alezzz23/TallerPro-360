import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { Image } from 'expo-image';

import { Fonts, Radius, Semantic, Shadows, Spacing, StatusColors, TypeScale } from '@/constants/theme';
import type { DiagnosticFinding } from '@/types/api';

interface Props {
  finding: DiagnosticFinding;
  technicianName?: string;
}

export function FindingCard({ finding, technicianName }: Props) {
  const router = useRouter();
  const previewPhoto = finding.fotos[0];
  const helperText = finding.safety_warning ?? finding.descripcion;

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
      <View
        style={[
          styles.accentStripe,
          finding.es_critico_seguridad && styles.accentStripeCritical,
        ]}
      />

      <View style={styles.header}>
        <View style={styles.headerCopy}>
          <Text style={styles.motivo} numberOfLines={2}>
            {finding.motivo_ingreso}
          </Text>
          {helperText ? (
            <Text style={styles.desc} numberOfLines={3}>
              {helperText}
            </Text>
          ) : null}
        </View>

        {previewPhoto ? (
          <Image
            source={previewPhoto}
            style={styles.previewImage}
            contentFit="cover"
            transition={150}
          />
        ) : (
          <View style={styles.previewFallback}>
            <Ionicons name="construct-outline" size={18} color={Semantic.primary} />
          </View>
        )}
      </View>

      <View style={styles.badges}>
          {finding.es_critico_seguridad && (
            <View style={styles.criticalBadge}>
              <Ionicons name="warning" size={12} color={Semantic.danger} />
              <Text style={styles.criticalText}>Seguridad</Text>
            </View>
          )}
          {finding.es_hallazgo_adicional && (
            <View style={styles.additionalBadge}>
              <Text style={styles.additionalText}>Adicional</Text>
            </View>
          )}
        {finding.tiempo_estimado != null && (
          <View style={styles.timeBadge}>
            <Ionicons name="time-outline" size={12} color={Semantic.primary} />
            <Text style={styles.timeBadgeText}>{finding.tiempo_estimado} h</Text>
          </View>
        )}
      </View>

      <View style={styles.footer}>
        <View style={styles.statRow}>
          <Ionicons name="camera-outline" size={14} color={Semantic.primary} />
          <Text style={styles.stat}>{finding.fotos.length} fotos</Text>
        </View>
        <View style={styles.statRow}>
          <Ionicons name="build-outline" size={14} color={Semantic.primary} />
          <Text style={styles.stat}>{finding.parts.length} repuestos</Text>
        </View>
      </View>

      {technicianName ? (
        <View style={styles.techRow}>
          <Ionicons name="person-circle-outline" size={16} color={Semantic.secondary} />
          <Text style={styles.techLabel}>{technicianName}</Text>
        </View>
      ) : null}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: Semantic.surface,
    borderRadius: Radius.xl,
    borderWidth: 1,
    borderColor: Semantic.borderLight,
    padding: Spacing.md,
    ...Shadows.elevated,
  },
  cardCritical: {
    borderWidth: 1,
    borderColor: 'rgba(198,90,90,0.22)',
    backgroundColor: '#2B1E21',
  },
  pressed: {
    ...Shadows.none,
    backgroundColor: Semantic.surfacePress,
    transform: [{ scale: 0.985 }],
  },
  header: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    gap: Spacing.md,
  },
  headerCopy: {
    flex: 1,
  },
  motivo: {
    fontSize: TypeScale.subtitle,
    fontFamily: Fonts.bold,
    color: Semantic.onSurface,
    lineHeight: 24,
  },
  badges: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Spacing.xs,
    marginTop: Spacing.md,
    marginBottom: Spacing.md,
  },
  criticalBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: 'rgba(198,90,90,0.16)',
    paddingHorizontal: Spacing.sm,
    paddingVertical: 6,
    borderRadius: Radius.pill,
    borderWidth: 1,
    borderColor: 'rgba(199,81,81,0.28)',
  },
  criticalText: {
    fontSize: TypeScale.caption,
    fontFamily: Fonts.bold,
    color: Semantic.danger,
  },
  additionalBadge: {
    backgroundColor: Semantic.primaryMuted,
    paddingHorizontal: Spacing.sm,
    paddingVertical: 6,
    borderRadius: Radius.pill,
    borderWidth: 1,
    borderColor: 'rgba(196,122,58,0.2)',
  },
  additionalText: {
    fontSize: TypeScale.caption,
    fontFamily: Fonts.bold,
    color: Semantic.primaryLight,
  },
  timeBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: Semantic.surfaceElevated,
    paddingHorizontal: Spacing.sm,
    paddingVertical: 6,
    borderRadius: Radius.pill,
  },
  timeBadgeText: {
    fontSize: TypeScale.caption,
    color: Semantic.onSurface,
    fontFamily: Fonts.bold,
  },
  desc: {
    fontSize: TypeScale.label,
    color: Semantic.secondary,
    marginTop: Spacing.sm,
    lineHeight: 22,
    fontFamily: Fonts.medium,
  },
  footer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Spacing.sm,
  },
  statRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: Spacing.sm,
    paddingVertical: Spacing.sm,
    borderRadius: Radius.pill,
    backgroundColor: Semantic.surfaceElevated,
  },
  stat: {
    fontSize: TypeScale.caption,
    color: Semantic.onSurface,
    fontFamily: Fonts.medium,
  },
  techRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.xs,
    marginTop: Spacing.md,
  },
  techLabel: {
    fontSize: TypeScale.label,
    color: Semantic.secondary,
    fontFamily: Fonts.medium,
  },
  previewImage: {
    width: 92,
    height: 92,
    borderRadius: Radius.lg,
    backgroundColor: Semantic.surfaceElevated,
  },
  previewFallback: {
    width: 92,
    height: 92,
    borderRadius: Radius.lg,
    backgroundColor: Semantic.primaryMuted,
    alignItems: 'center',
    justifyContent: 'center',
  },
  accentStripe: {
    width: 48,
    height: 4,
    borderRadius: Radius.pill,
    backgroundColor: StatusColors.DIAGNOSTICO,
    marginBottom: Spacing.md,
  },
  accentStripeCritical: {
    backgroundColor: Semantic.danger,
  },
});
