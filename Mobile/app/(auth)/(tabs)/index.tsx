import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useRouter } from 'expo-router';

import { useAuthStore } from '@/stores/auth-store';
import { useOrders } from '@/hooks/use-orders';
import { RoleColors, Spacing, TypeScale, Semantic, StatusColors, Shadows, Radius } from '@/constants/theme';
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
      <Text style={styles.cardValue}>{value}</Text>
      <Text style={styles.cardTitle}>{title}</Text>
    </View>
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
    <View style={styles.container}>
      <Text style={styles.dashboardTitle}>Dashboard</Text>

      <View style={styles.greetingRow}>
        <Text style={styles.greeting}>
          Hola, {user?.nombre ?? 'Usuario'}
        </Text>
        <View style={[styles.roleBadge, { backgroundColor: RoleColors[role] }]}>
          <Text style={styles.roleBadgeText}>{ROLE_LABELS[role]}</Text>
        </View>
      </View>

      <ScrollView style={styles.cardsContainer} showsVerticalScrollIndicator={false}>
        {cards.map((card) => (
          <SummaryCard key={card.title} title={card.title} value={card.value} />
        ))}

        {/* Pipeline overview */}
        <Text style={styles.sectionTitle}>Pipeline</Text>
        <View style={styles.pipelineRow}>
          {statusCounts.map((s) => (
            <View key={s.status} style={styles.pipelineItem}>
              <View style={[styles.pipelineDot, { backgroundColor: s.color }, Shadows.soft]}>
                <Text style={styles.pipelineCount}>{s.count}</Text>
              </View>
              <Text style={styles.pipelineLabel} numberOfLines={1}>
                {s.label}
              </Text>
            </View>
          ))}
        </View>

        {/* Nueva Recepción — visible to ASESOR, JEFE_TALLER, ADMIN */}
        {(role === 'ASESOR' || role === 'JEFE_TALLER' || role === 'ADMIN') && (
          <Pressable
            style={({ pressed }) => [
              styles.receptionButton,
              pressed && styles.buttonPressed,
            ]}
            onPress={() => router.push('/(auth)/reception/vehicle-search')}
          >
            <Text style={styles.receptionButtonText}>+ Nueva Recepción</Text>
          </Pressable>
        )}

        {/* Quick-access Kanban */}
        <Pressable
          style={({ pressed }) => [
            styles.kanbanButton,
            pressed && styles.buttonPressed,
          ]}
          onPress={() => router.push('/(auth)/(tabs)/orders')}
        >
          <Text style={styles.kanbanButtonText}>Ver Kanban</Text>
        </Pressable>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: Spacing.lg,
    paddingTop: 60,
    backgroundColor: '#0A0A0A',
  },
  dashboardTitle: {
    fontSize: TypeScale.headline,
    fontWeight: '700',
    color: '#F5F5F5',
  },
  greetingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: Spacing.sm,
    marginBottom: Spacing.lg,
    flexWrap: 'wrap',
    gap: Spacing.sm,
  },
  greeting: {
    fontSize: TypeScale.subtitle,
    color: '#A3A3A3',
  },
  roleBadge: {
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.xs,
    borderRadius: Radius.pill,
  },
  roleBadgeText: {
    color: '#0A0A0A',
    fontSize: TypeScale.caption,
    fontWeight: '600',
  },
  cardsContainer: {
    flex: 1,
  },
  summaryCard: {
    backgroundColor: '#161616',
    borderRadius: Radius.lg,
    padding: Spacing.md,
    marginBottom: Spacing.md,
    ...Shadows.extruded,
    borderTopWidth: 1,
    borderLeftWidth: 1,
    borderTopColor: 'rgba(255,255,255,0.06)',
    borderLeftColor: 'rgba(255,255,255,0.06)',
  },
  cardValue: {
    fontSize: TypeScale.title,
    fontWeight: '700',
    color: '#22C55E',
    marginBottom: Spacing.xs,
  },
  cardTitle: {
    fontSize: TypeScale.body,
    color: '#A3A3A3',
  },
  sectionTitle: {
    fontSize: TypeScale.subtitle,
    fontWeight: '700',
    color: '#F5F5F5',
    marginTop: Spacing.lg,
    marginBottom: Spacing.md,
  },
  pipelineRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Spacing.sm,
    marginBottom: Spacing.lg,
  },
  pipelineItem: {
    alignItems: 'center',
    width: 52,
  },
  pipelineDot: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  pipelineCount: {
    color: '#F5F5F5',
    fontSize: TypeScale.label,
    fontWeight: '700',
  },
  pipelineLabel: {
    fontSize: 10,
    color: '#A3A3A3',
    marginTop: 4,
    textAlign: 'center',
  },
  receptionButton: {
    backgroundColor: '#22C55E',
    borderRadius: Radius.pill,
    paddingVertical: Spacing.md,
    alignItems: 'center',
    marginBottom: Spacing.md,
    ...Shadows.extruded,
  },
  receptionButtonText: {
    color: '#0A0A0A',
    fontSize: TypeScale.body,
    fontWeight: '700',
  },
  kanbanButton: {
    backgroundColor: '#161616',
    borderRadius: Radius.pill,
    borderWidth: 1,
    borderColor: '#2A2A2A',
    paddingVertical: Spacing.md,
    alignItems: 'center',
    marginBottom: Spacing.xl,
    ...Shadows.soft,
  },
  kanbanButtonText: {
    color: '#F5F5F5',
    fontSize: TypeScale.body,
    fontWeight: '700',
  },
  buttonPressed: {
    ...Shadows.none,
    backgroundColor: '#111111',
    transform: [{ scale: 0.97 }],
  },
});
