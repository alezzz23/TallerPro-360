import { useCallback, useMemo, useState } from 'react';
import { RefreshControl, StyleSheet, Text, View } from 'react-native';

import { KanbanBoard } from '@/components/kanban/kanban-board';
import { FilterBar } from '@/components/kanban/filter-bar';
import type { FilterState } from '@/components/kanban/filter-bar';
import { useOrders } from '@/hooks/use-orders';
import { Spacing, TypeScale } from '@/constants/theme';
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
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.title}>Órdenes</Text>
        <View style={styles.badge}>
          <Text style={styles.badgeText}>{data?.total ?? 0}</Text>
        </View>
      </View>

      {/* Filters */}
      <FilterBar filters={filters} onChange={setFilters} />

      {/* Kanban */}
      <View style={styles.boardWrapper}>
        <RefreshControl
          refreshing={isRefetching}
          onRefresh={onRefresh}
          tintColor="#22C55E"
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
    backgroundColor: '#0A0A0A',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: Spacing.lg,
    gap: Spacing.sm,
  },
  title: {
    fontSize: TypeScale.title,
    fontWeight: '700',
    color: '#F5F5F5',
  },
  badge: {
    backgroundColor: '#161616',
    minWidth: 28,
    height: 28,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: Spacing.sm,
  },
  badgeText: {
    color: '#22C55E',
    fontSize: TypeScale.caption,
    fontWeight: '700',
  },
  boardWrapper: {
    flex: 1,
  },
});
