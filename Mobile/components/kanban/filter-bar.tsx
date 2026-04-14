import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';

import { KANBAN_STATUSES, STATUS_LABELS } from '@/constants/status';
import { Fonts, Radius, Semantic, Shadows, Spacing, StatusColors, TypeScale } from '@/constants/theme';
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
    backgroundColor: Semantic.surface,
    borderWidth: 1,
    borderColor: Semantic.border,
    ...Shadows.soft,
  },
  chipActive: {
    backgroundColor: Semantic.primary,
    borderColor: 'transparent',
    ...Shadows.none,
  },
  chipActivePrimary: {
    backgroundColor: Semantic.primary,
    borderColor: 'transparent',
    ...Shadows.none,
  },
  chipText: {
    fontSize: TypeScale.caption,
    fontFamily: Fonts.medium,
    color: Semantic.secondary,
  },
  chipTextActive: {
    color: Semantic.onPrimary,
    fontFamily: Fonts.bold,
  },
});
