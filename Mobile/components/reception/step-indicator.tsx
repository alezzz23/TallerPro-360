import { StyleSheet, Text, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

import { Radius, Semantic, Shadows, Spacing, TypeScale } from '@/constants/theme';

interface Props {
  current: number;
  total: number;
  labels?: string[];
}

export function StepIndicator({ current, total, labels }: Props) {
  return (
    <View style={styles.container}>
      <View style={styles.row}>
        {Array.from({ length: total }, (_, i) => {
          const step = i + 1;
          const isDone = step < current;
          const isActive = step === current;
          return (
            <View key={step} style={styles.stepGroup}>
              <View
                style={[
                  styles.circle,
                  isDone && styles.circleDone,
                  isActive && styles.circleActive,
                ]}
              >
                <Text
                  style={[
                    styles.circleText,
                    (isDone || isActive) && styles.circleTextActive,
                  ]}
                >
                  {isDone ? <Ionicons name="checkmark" size={16} color={Semantic.onPrimary} /> : step}
                </Text>
              </View>
              {i < total - 1 && (
                <View
                  style={[styles.line, isDone && styles.lineDone]}
                />
              )}
            </View>
          );
        })}
      </View>
      {labels && labels[current - 1] && (
        <Text style={styles.label}>{labels[current - 1]}</Text>
      )}
      <Text style={styles.counter}>
        Paso {current} de {total}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { alignItems: 'center', marginBottom: Spacing.lg },
  row: { flexDirection: 'row', alignItems: 'center' },
  stepGroup: { flexDirection: 'row', alignItems: 'center' },
  circle: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: Semantic.surfaceElevated,
    alignItems: 'center',
    justifyContent: 'center',
  },
  circleDone: { backgroundColor: Semantic.primary },
  circleActive: { backgroundColor: Semantic.primaryDark },
  circleText: {
    fontSize: TypeScale.label,
    fontWeight: '700',
    color: Semantic.textMuted,
  },
  circleTextActive: { color: Semantic.onPrimary },
  line: {
    width: 24,
    height: 3,
    backgroundColor: Semantic.border,
    borderRadius: 1.5,
  },
  lineDone: { backgroundColor: Semantic.primary },
  label: {
    marginTop: Spacing.sm,
    fontSize: TypeScale.label,
    fontWeight: '600',
    color: Semantic.primary,
  },
  counter: {
    marginTop: 4,
    fontSize: TypeScale.caption,
    color: Semantic.secondary,
  },
});
