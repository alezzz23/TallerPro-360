import { ScrollView, StyleSheet, Text, View } from 'react-native';

import { OrderCard } from '@/components/kanban/order-card';
import { Spacing, TypeScale } from '@/constants/theme';
import type { ServiceOrder } from '@/types/api';

interface KanbanColumnProps {
  label: string;
  color: string;
  orders: ServiceOrder[];
}

export function KanbanColumn({ label, color, orders }: KanbanColumnProps) {
  return (
    <View style={styles.column}>
      {/* Colored accent bar */}
      <View style={[styles.accentBar, { backgroundColor: color }]} />

      <View style={styles.headerRow}>
        <Text style={styles.headerLabel}>{label}</Text>
        <View style={[styles.countBadge, { backgroundColor: color }]}>
          <Text style={styles.countText}>{orders.length}</Text>
        </View>
      </View>

      <ScrollView
        style={styles.cardList}
        contentContainerStyle={styles.cardListContent}
        showsVerticalScrollIndicator={false}
        nestedScrollEnabled
      >
        {orders.length === 0 ? (
          <View style={styles.emptyState}>
            <Text style={styles.emptyText}>Sin órdenes</Text>
          </View>
        ) : (
          orders.map((order) => <OrderCard key={order.id} order={order} />)
        )}
      </ScrollView>
    </View>
  );
}

const COLUMN_WIDTH = 280;

const styles = StyleSheet.create({
  column: {
    width: COLUMN_WIDTH,
    marginRight: Spacing.md,
    backgroundColor: '#0F0F0F',
    borderRadius: 12,
    overflow: 'hidden',
  },
  accentBar: {
    height: 4,
    width: '100%',
  },
  headerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
  },
  headerLabel: {
    fontSize: TypeScale.label,
    fontWeight: '700',
    color: '#F5F5F5',
  },
  countBadge: {
    minWidth: 24,
    height: 24,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: Spacing.xs,
  },
  countText: {
    fontSize: TypeScale.caption,
    fontWeight: '700',
    color: '#0A0A0A',
  },
  cardList: {
    flex: 1,
  },
  cardListContent: {
    padding: Spacing.sm,
    paddingTop: 0,
  },
  emptyState: {
    borderWidth: 1.5,
    borderColor: '#2A2A2A',
    borderStyle: 'dashed',
    borderRadius: 10,
    padding: Spacing.lg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  emptyText: {
    fontSize: TypeScale.label,
    color: '#525252',
  },
});
