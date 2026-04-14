import { ActivityIndicator, ScrollView, StyleSheet, Text, View } from 'react-native';

import { KanbanColumn } from '@/components/kanban/kanban-column';
import { KANBAN_STATUSES, STATUS_LABELS } from '@/constants/status';
import { Semantic, Spacing, StatusColors, TypeScale } from '@/constants/theme';
import type { ServiceOrder } from '@/types/api';

interface KanbanBoardProps {
  orders: ServiceOrder[];
  isLoading: boolean;
  isError: boolean;
}

export function KanbanBoard({ orders, isLoading, isError }: KanbanBoardProps) {
  if (isLoading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={Semantic.primary} />
      </View>
    );
  }

  if (isError) {
    return (
      <View style={styles.center}>
        <Text style={styles.errorText}>Error al cargar órdenes</Text>
      </View>
    );
  }

  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      style={styles.board}
      contentContainerStyle={styles.boardContent}
    >
      {KANBAN_STATUSES.map((status) => {
        const columnOrders = orders.filter((o) => o.estado === status);
        return (
          <KanbanColumn
            key={status}
            label={STATUS_LABELS[status]}
            color={StatusColors[status]}
            orders={columnOrders}
          />
        );
      })}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  board: {
    flex: 1,
  },
  boardContent: {
    paddingHorizontal: Spacing.md,
    paddingBottom: Spacing.lg,
  },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  errorText: {
    fontSize: TypeScale.body,
    color: Semantic.danger,
  },
});
