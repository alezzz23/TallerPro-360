import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';

import { KANBAN_STATUSES, STATUS_LABELS } from '@/constants/status';
import { StatusColors, Spacing, TypeScale, Shadows, Radius } from '@/constants/theme';
import type { ServiceOrderStatus } from '@/types/api';

type DateFilter = 'all' | 'today' | 'week' | 'month';

const DATE_LABELS: Record<DateFilter, string> = {
  all: 'Todos',
  today: 'Hoy',
  week: 'Semana',
  month: 'Mes',
};

export interface FilterState {
  status: ServiceOrderStatus | null;
  dateRange: DateFilter;
}

interface FilterBarProps {
  filters: FilterState;
  onChange: (filters: FilterState) => void;
}

export function FilterBar({ filters, onChange }: FilterBarProps) {
  return (
    <View style={styles.container}>
      {/* Status filter chips */}
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.row}
      >
        {/* "Todos" chip for status */}
        <Pressable
          style={[
            styles.chip,
            !filters.status && styles.chipActive,
          ]}
          onPress={() => onChange({ ...filters, status: null })}
        >
          <Text
            style={[
              styles.chipText,
              !filters.status && styles.chipTextActive,
            ]}
          >
            Todos
          </Text>
        </Pressable>

        {KANBAN_STATUSES.map((s) => {
          const active = filters.status === s;
          return (
            <Pressable
              key={s}
              style={[
                styles.chip,
                active && { backgroundColor: StatusColors[s] },
              ]}
              onPress={() =>
                onChange({ ...filters, status: active ? null : s })
              }
            >
              <Text
                style={[styles.chipText, active && styles.chipTextActive]}
              >
                {STATUS_LABELS[s]}
              </Text>
            </Pressable>
          );
        })}
      </ScrollView>

      {/* Date range chips */}
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.row}
      >
        {(Object.keys(DATE_LABELS) as DateFilter[]).map((d) => {
          const active = filters.dateRange === d;
          return (
            <Pressable
              key={d}
              style={[styles.chip, active && styles.chipActivePrimary]}
              onPress={() => onChange({ ...filters, dateRange: d })}
            >
              <Text
                style={[styles.chipText, active && styles.chipTextActive]}
              >
                {DATE_LABELS[d]}
              </Text>
            </Pressable>
          );
        })}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingTop: Spacing.sm,
    paddingBottom: Spacing.sm,
    gap: Spacing.xs,
  },
  row: {
    paddingHorizontal: Spacing.md,
    gap: Spacing.sm,
    flexDirection: 'row',
    alignItems: 'center',
  },
  chip: {
    paddingHorizontal: Spacing.md,
    paddingVertical: 6,
    borderRadius: Radius.pill,
    backgroundColor: '#161616',
    borderWidth: 1,
    borderColor: '#2A2A2A',
    ...Shadows.soft,
  },
  chipActive: {
    backgroundColor: '#22C55E',
    borderColor: 'transparent',
    ...Shadows.none,
  },
  chipActivePrimary: {
    backgroundColor: '#22C55E',
    borderColor: 'transparent',
    ...Shadows.none,
  },
  chipText: {
    fontSize: TypeScale.caption,
    fontWeight: '600',
    color: '#A3A3A3',
  },
  chipTextActive: {
    color: '#0A0A0A',
  },
});
