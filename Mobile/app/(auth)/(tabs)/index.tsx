import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { Image } from 'expo-image';

import { useAuthStore } from '@/stores/auth-store';
import { useOrders } from '@/hooks/use-orders';
import { EditorialImages } from '@/constants/visuals';
import {
  Fonts,
  RoleColors,
  Spacing,
  TypeScale,
  Semantic,
  StatusColors,
  Shadows,
  Radius,
} from '@/constants/theme';
import { STATUS_LABELS, KANBAN_STATUSES } from '@/constants/status';
import type { UserRole, ServiceOrder } from '@/types/api';

const ROLE_LABELS: Record<UserRole, string> = {
  TECNICO: 'Técnico',
  ASESOR: 'Asesor',
  JEFE_TALLER: 'Jefe de Taller',
  ADMIN: 'Administrador',
};

interface SummaryCardProps {
  title: string;
  value: string;
}

function SummaryCard({ title, value }: SummaryCardProps) {
  return (
    <View style={styles.summaryCard}>
      <View style={styles.summaryAccent} />
      <Text style={styles.cardValue}>{value}</Text>
      <Text style={styles.cardTitle}>{title}</Text>
    </View>
  );
}

interface ActionCardProps {
  icon: React.ComponentProps<typeof Ionicons>['name'];
  title: string;
  subtitle: string;
  primary?: boolean;
  onPress: () => void;
}

function ActionCard({ icon, title, subtitle, primary = false, onPress }: ActionCardProps) {
  return (
    <Pressable
      style={({ pressed }) => [
        styles.actionCard,
        primary && styles.actionCardPrimary,
        pressed && styles.actionCardPressed,
      ]}
      onPress={onPress}
    >
      <View style={[styles.actionIconWrap, primary && styles.actionIconWrapPrimary]}>
        <Ionicons name={icon} size={20} color={primary ? Semantic.onPrimary : Semantic.primary} />
      </View>
      <View style={styles.actionCopy}>
        <Text style={[styles.actionTitle, primary && styles.actionTitlePrimary]}>{title}</Text>
        <Text style={[styles.actionSubtitle, primary && styles.actionSubtitlePrimary]}>{subtitle}</Text>
      </View>
      <Ionicons
        name="arrow-forward"
        size={18}
        color={primary ? Semantic.onPrimary : Semantic.onSurface}
      />
    </Pressable>
  );
}

function getRoleCards(role: UserRole, orders: ServiceOrder[]): SummaryCardProps[] {
  const cards: SummaryCardProps[] = [];
  const active = orders.filter((o) => o.estado !== 'CERRADA');

  if (role === 'TECNICO' || role === 'ADMIN') {
    const reparacion = orders.filter((o) => o.estado === 'REPARACION').length;
    cards.push({ title: 'Asignaciones pendientes', value: String(reparacion) });
  }
  if (role === 'ASESOR' || role === 'JEFE_TALLER' || role === 'ADMIN') {
    cards.push({ title: 'Órdenes activas', value: String(active.length) });
  }
  if (role === 'ASESOR' || role === 'ADMIN') {
    const recepcion = orders.filter((o) => o.estado === 'RECEPCION').length;
    cards.push({ title: 'En recepción', value: String(recepcion) });
  }
  if (role === 'JEFE_TALLER' || role === 'ADMIN') {
    const qc = orders.filter((o) => o.estado === 'QC').length;
    cards.push({ title: 'QC pendientes', value: String(qc) });
  }

  return cards;
}

export default function DashboardScreen() {
  const user = useAuthStore((s) => s.user);
  const role = user?.rol ?? 'ASESOR';
  const firstName = (user?.nombre ?? 'Usuario').trim().split(' ')[0] || 'Usuario';
  const { data } = useOrders({ limit: 200 });
  const orders = data?.items ?? [];
  const cards = getRoleCards(role, orders);
  const router = useRouter();

  // Status breakdown for mini pipeline
  const statusCounts = KANBAN_STATUSES.map((s) => ({
    status: s,
    label: STATUS_LABELS[s],
    color: StatusColors[s],
    count: orders.filter((o) => o.estado === s).length,
  }));

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.content}
      showsVerticalScrollIndicator={false}
    >
      <View style={styles.heroCard}>
        <Image
          source={EditorialImages.dashboard}
          style={styles.heroImage}
          contentFit="cover"
          transition={250}
        />
        <View style={styles.heroOverlay} />
        <View style={styles.heroTopRow}>
          <Text style={styles.heroEyebrow}>Centro de control</Text>
          <View style={[styles.roleBadge, { backgroundColor: RoleColors[role] }]}>
            <Text style={styles.roleBadgeText}>{ROLE_LABELS[role]}</Text>
          </View>
        </View>

        <Text style={styles.dashboardTitle}>Hola, {firstName}</Text>
        <Text style={styles.greeting}>
          Supervisa la operación con una lectura inspirada en tableros automotrices: clara, sobria y priorizada.
        </Text>

        <View style={styles.heroMetricsRow}>
          <View style={styles.heroMetric}>
            <Text style={styles.heroMetricValue}>{orders.length}</Text>
            <Text style={styles.heroMetricLabel}>Órdenes</Text>
          </View>
          <View style={styles.heroMetricDivider} />
          <View style={styles.heroMetric}>
            <Text style={styles.heroMetricValue}>
              {orders.filter((o) => o.estado !== 'CERRADA').length}
            </Text>
            <Text style={styles.heroMetricLabel}>Activas</Text>
          </View>
        </View>
      </View>

      <View style={styles.sectionRow}>
        <Text style={styles.sectionTitle}>Resumen del día</Text>
        <Text style={styles.sectionHint}>Lectura rápida</Text>
      </View>

      <View style={styles.summaryGrid}>
        {cards.map((card) => (
          <SummaryCard key={card.title} title={card.title} value={card.value} />
        ))}
      </View>

      <View style={styles.pipelineCard}>
        <View style={styles.sectionRowCompact}>
          <Text style={styles.pipelineTitle}>Pipeline</Text>
          <Text style={styles.pipelineSubtitle}>Estado actual</Text>
        </View>
        <View style={styles.pipelineRow}>
          {statusCounts.map((s) => (
            <View key={s.status} style={styles.pipelineItem}>
              <View style={[styles.pipelineDot, { backgroundColor: s.color }]}>
                <Text style={styles.pipelineCount}>{s.count}</Text>
              </View>
              <Text style={styles.pipelineLabel} numberOfLines={1}>
                {s.label}
              </Text>
            </View>
          ))}
        </View>
      </View>

      <View style={styles.actionsSection}>
        {(role === 'ASESOR' || role === 'JEFE_TALLER' || role === 'ADMIN') && (
          <ActionCard
            icon="add-circle-outline"
            title="Nueva recepción"
            subtitle="Inicia una orden con una entrada más guiada."
            primary
            onPress={() => router.push('/(auth)/reception/vehicle-search')}
          />
        )}

        <ActionCard
          icon="grid-outline"
          title="Ver Kanban"
          subtitle="Revisa toda la operación en columnas."
          onPress={() => router.push('/(auth)/(tabs)/orders')}
        />
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Semantic.background,
  },
  content: {
    padding: Spacing.lg,
    paddingTop: Spacing.xxl,
    paddingBottom: 120,
    gap: Spacing.lg,
  },
  heroCard: {
    minHeight: 260,
    borderRadius: Radius.xl,
    overflow: 'hidden',
    padding: Spacing.lg,
    justifyContent: 'space-between',
    ...Shadows.glow,
  },
  heroImage: {
    ...StyleSheet.absoluteFillObject,
  },
  heroOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(14,19,26,0.48)',
  },
  heroTopRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: Spacing.sm,
  },
  heroEyebrow: {
    fontSize: TypeScale.caption,
    color: '#FFF8F0',
    fontFamily: Fonts.bold,
    textTransform: 'uppercase',
    letterSpacing: 0.8,
  },
  dashboardTitle: {
    fontSize: TypeScale.headline,
    fontFamily: Fonts.display,
    color: '#FFF8F0',
    marginTop: Spacing.xl,
  },
  greeting: {
    fontSize: TypeScale.body,
    color: 'rgba(255,248,240,0.82)',
    fontFamily: Fonts.medium,
    lineHeight: 24,
    maxWidth: 300,
  },
  roleBadge: {
    paddingHorizontal: Spacing.md,
    paddingVertical: 6,
    borderRadius: Radius.pill,
  },
  roleBadgeText: {
    color: Semantic.onSurface,
    fontSize: TypeScale.caption,
    fontFamily: Fonts.bold,
  },
  heroMetricsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    backgroundColor: 'rgba(14,19,26,0.56)',
    borderRadius: Radius.pill,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    borderWidth: 1,
    borderColor: 'rgba(255,248,240,0.14)',
  },
  heroMetric: {
    minWidth: 82,
  },
  heroMetricDivider: {
    width: 1,
    alignSelf: 'stretch',
    backgroundColor: 'rgba(255,248,240,0.18)',
    marginHorizontal: Spacing.md,
  },
  heroMetricValue: {
    fontSize: TypeScale.title,
    color: '#FFF8F0',
    fontFamily: Fonts.display,
  },
  heroMetricLabel: {
    fontSize: TypeScale.caption,
    color: 'rgba(255,248,240,0.68)',
    fontFamily: Fonts.medium,
  },
  sectionRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: Spacing.sm,
  },
  sectionHint: {
    fontSize: TypeScale.caption,
    color: 'rgba(255,248,240,0.66)',
    fontFamily: Fonts.medium,
  },
  summaryGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Spacing.md,
  },
  summaryCard: {
    width: '47%',
    minWidth: 150,
    backgroundColor: Semantic.surface,
    borderRadius: Radius.lg,
    padding: Spacing.md,
    borderWidth: 1,
    borderColor: Semantic.borderLight,
    ...Shadows.elevated,
  },
  summaryAccent: {
    width: 42,
    height: 4,
    borderRadius: Radius.pill,
    backgroundColor: Semantic.primary,
    marginBottom: Spacing.md,
  },
  cardValue: {
    fontSize: TypeScale.title,
    fontFamily: Fonts.display,
    color: Semantic.primary,
    marginBottom: Spacing.xs,
  },
  cardTitle: {
    fontSize: TypeScale.body,
    color: Semantic.secondary,
    fontFamily: Fonts.medium,
  },
  sectionTitle: {
    fontSize: TypeScale.subtitle,
    fontFamily: Fonts.bold,
    color: '#FFF8F0',
  },
  pipelineCard: {
    backgroundColor: Semantic.surface,
    borderRadius: Radius.xl,
    padding: Spacing.lg,
    borderWidth: 1,
    borderColor: Semantic.borderLight,
    ...Shadows.elevated,
  },
  sectionRowCompact: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: Spacing.md,
  },
  pipelineTitle: {
    fontSize: TypeScale.subtitle,
    color: Semantic.onSurface,
    fontFamily: Fonts.bold,
  },
  pipelineSubtitle: {
    fontSize: TypeScale.caption,
    color: Semantic.textMuted,
    fontFamily: Fonts.medium,
  },
  pipelineRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Spacing.sm,
  },
  pipelineItem: {
    alignItems: 'center',
    width: 72,
  },
  pipelineDot: {
    width: 48,
    height: 48,
    borderRadius: 24,
    alignItems: 'center',
    justifyContent: 'center',
    ...Shadows.soft,
  },
  pipelineCount: {
    color: '#FFF8F0',
    fontSize: TypeScale.label,
    fontFamily: Fonts.bold,
  },
  pipelineLabel: {
    fontSize: TypeScale.caption,
    color: Semantic.secondary,
    fontFamily: Fonts.medium,
    marginTop: Spacing.xs,
    textAlign: 'center',
  },
  actionsSection: {
    gap: Spacing.md,
  },
  actionCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.md,
    borderRadius: Radius.xl,
    backgroundColor: Semantic.surface,
    padding: Spacing.md,
    borderWidth: 1,
    borderColor: Semantic.borderLight,
    ...Shadows.elevated,
  },
  actionCardPrimary: {
    backgroundColor: Semantic.primary,
    borderColor: Semantic.primary,
  },
  actionCardPressed: {
    ...Shadows.none,
    transform: [{ scale: 0.985 }],
  },
  actionIconWrap: {
    width: 46,
    height: 46,
    borderRadius: 23,
    backgroundColor: Semantic.primaryMuted,
    alignItems: 'center',
    justifyContent: 'center',
  },
  actionIconWrapPrimary: {
    backgroundColor: 'rgba(255,248,240,0.16)',
  },
  actionCopy: {
    flex: 1,
  },
  actionTitle: {
    fontSize: TypeScale.body,
    color: Semantic.onSurface,
    fontFamily: Fonts.bold,
  },
  actionTitlePrimary: {
    color: Semantic.onPrimary,
  },
  actionSubtitle: {
    fontSize: TypeScale.label,
    color: Semantic.textMuted,
    fontFamily: Fonts.medium,
    marginTop: 2,
  },
  actionSubtitlePrimary: {
    color: 'rgba(255,248,240,0.82)',
  },
});
