import { Pressable, StyleSheet, Switch, Text, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

import { Radius, Semantic, Shadows, Spacing, StatusColors, TypeScale } from '@/constants/theme';
import type { QuotationItem } from '@/types/api';

interface QCChecklistProps {
  items: QuotationItem[];
  checked: Record<string, boolean>;
  onToggle: (key: string, value: boolean) => void;
  readOnly?: boolean;
}

export function QCChecklist({ items, checked, onToggle, readOnly }: QCChecklistProps) {
  const totalItems = items.length;
  const checkedCount = Object.values(checked).filter(Boolean).length;

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Checklist de Calidad</Text>
        <View style={styles.badge}>
          <Text style={styles.badgeText}>
            {checkedCount}/{totalItems}
          </Text>
        </View>
      </View>

      {items.map((item) => {
        const key = item.descripcion;
        const isChecked = checked[key] ?? false;

        return (
          <Pressable
            key={item.id}
            style={({ pressed }) => [
              styles.row,
              isChecked && styles.rowChecked,
              pressed && { opacity: 0.8 },
            ]}
            onPress={() => !readOnly && onToggle(key, !isChecked)}
            disabled={readOnly}
          >
            <View style={styles.rowContent}>
              <View
                style={[
                  styles.checkIcon,
                  isChecked ? styles.checkIconActive : styles.checkIconInactive,
                ]}
              >
                {isChecked && <Ionicons name="checkmark" size={16} color="#fff" />}
              </View>

              <View style={styles.itemInfo}>
                <Text
                  style={[styles.itemDesc, isChecked && styles.itemDescChecked]}
                  numberOfLines={2}
                >
                  {item.descripcion}
                </Text>
                {item.costo_repuesto > 0 && (
                  <Text style={styles.itemPart}>
                    Repuesto incluido · ${item.costo_repuesto.toFixed(2)}
                  </Text>
                )}
              </View>
            </View>

            <Switch
              value={isChecked}
              onValueChange={(val) => onToggle(key, val)}
              disabled={readOnly}
              trackColor={{ false: '#2A2A2A', true: Semantic.primaryMuted }}
              thumbColor={isChecked ? Semantic.primary : '#525252'}
            />
          </Pressable>
        );
      })}

      {items.length === 0 && (
        <View style={styles.empty}>
          <Text style={styles.emptyText}>Sin ítems aprobados para verificar</Text>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: Semantic.surface,
    borderRadius: Radius.lg,
    marginHorizontal: Spacing.md,
    marginTop: Spacing.md,
    overflow: 'hidden',
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
    padding: Spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: Semantic.border,
  },
  title: {
    fontSize: TypeScale.subtitle,
    fontWeight: '700',
    color: Semantic.onSurface,
  },
  badge: {
    backgroundColor: Semantic.primary,
    paddingHorizontal: Spacing.sm,
    paddingVertical: 2,
    borderRadius: Radius.pill,
  },
  badgeText: {
    color: Semantic.onPrimary,
    fontSize: TypeScale.caption,
    fontWeight: '700',
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: Spacing.sm + 2,
    paddingHorizontal: Spacing.md,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: Semantic.border,
  },
  rowChecked: {
    backgroundColor: Semantic.surfaceElevated,
  },
  rowContent: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
    marginRight: Spacing.sm,
  },
  checkIcon: {
    width: 28,
    height: 28,
    borderRadius: 14,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: Spacing.sm,
  },
  checkIconActive: {
    backgroundColor: Semantic.primary,
  },
  checkIconInactive: {
    backgroundColor: Semantic.surface,
    borderWidth: 1.5,
    borderColor: Semantic.border,
  },
  itemInfo: {
    flex: 1,
  },
  itemDesc: {
    fontSize: TypeScale.body,
    color: Semantic.onSurface,
    lineHeight: 22,
  },
  itemDescChecked: {
    color: Semantic.primary,
    fontWeight: '600',
  },
  itemPart: {
    fontSize: TypeScale.caption,
    color: Semantic.textMuted,
    marginTop: 2,
  },
  empty: {
    padding: Spacing.xl,
    alignItems: 'center',
  },
  emptyText: {
    fontSize: TypeScale.body,
    color: Semantic.textMuted,
  },
});
