import { useCallback, useMemo, useState } from 'react';
import { RefreshControl, StyleSheet, Text, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

import { KanbanBoard } from '@/components/kanban/kanban-board';
import { FilterBar } from '@/components/kanban/filter-bar';
import type { FilterState } from '@/components/kanban/filter-bar';
import { useOrders } from '@/hooks/use-orders';
import { Fonts, Radius, Semantic, Shadows, Spacing, TypeScale } from '@/constants/theme';
import type { OrderFilters } from '@/services/orders';

function buildApiFilters(filters: FilterState): OrderFilters {
  const params: OrderFilters = { limit: 200 };
  if (filters.status) {
    params.estado = filters.status;
  }
  return params;
}

function filterByDate<T extends { fecha_ingreso: string }>(
  items: T[],
  range: FilterState['dateRange'],
): T[] {
  if (range === 'all') return items;

  const now = new Date();
  const start = new Date(now);
  if (range === 'today') {
    start.setHours(0, 0, 0, 0);
  } else if (range === 'week') {
    start.setDate(now.getDate() - 7);
  } else if (range === 'month') {
    start.setMonth(now.getMonth() - 1);
  }

  return items.filter((o) => new Date(o.fecha_ingreso) >= start);
}

export default function OrdersScreen() {
  const [filters, setFilters] = useState<FilterState>({
    status: null,
    dateRange: 'all',
  });

  const apiFilters = useMemo(() => buildApiFilters(filters), [filters]);
  const { data, isLoading, isError, refetch, isRefetching } =
    useOrders(apiFilters);

  const orders = useMemo(
    () => filterByDate(data?.items ?? [], filters.dateRange),
    [data?.items, filters.dateRange],
  );

  const onRefresh = useCallback(() => {
    refetch();
  }, [refetch]);

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <View style={styles.headerCopy}>
          <Text style={styles.title}>Órdenes</Text>
          <Text style={styles.subtitle}>Vista operativa del taller en tiempo real</Text>
        </View>
        <View style={styles.badge}>
          <Ionicons name="layers-outline" size={14} color={Semantic.primary} />
          <Text style={styles.badgeText}>{data?.total ?? 0}</Text>
        </View>
      </View>

      <FilterBar filters={filters} onChange={setFilters} />

      <View style={styles.boardWrapper}>
        <RefreshControl
          refreshing={isRefetching}
          onRefresh={onRefresh}
          tintColor={Semantic.primary}
        />
        <KanbanBoard
          orders={orders}
          isLoading={isLoading}
          isError={isError}
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: 60,
    backgroundColor: Semantic.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    paddingHorizontal: Spacing.lg,
    gap: Spacing.sm,
    paddingBottom: Spacing.md,
  },
  headerCopy: {
    flex: 1,
  },
  title: {
    fontSize: TypeScale.title,
    fontFamily: Fonts.display,
    color: Semantic.onSurface,
  },
  subtitle: {
    marginTop: Spacing.xs,
    fontSize: TypeScale.label,
    color: Semantic.textMuted,
    fontFamily: Fonts.medium,
  },
  badge: {
    backgroundColor: Semantic.surface,
    minWidth: 56,
    height: 34,
    borderRadius: Radius.pill,
    alignItems: 'center',
    justifyContent: 'center',
    flexDirection: 'row',
    gap: Spacing.xs,
    paddingHorizontal: Spacing.sm,
    borderWidth: 1,
    borderColor: Semantic.borderLight,
    ...Shadows.soft,
  },
  badgeText: {
    color: Semantic.primary,
    fontSize: TypeScale.caption,
    fontFamily: Fonts.bold,
  },
  boardWrapper: {
    flex: 1,
    paddingTop: Spacing.xs,
  },
});
