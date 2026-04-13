import { StyleSheet, Text, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

import { Radius, Semantic, Shadows, Spacing, TypeScale } from '@/constants/theme';

interface DeliveryProgressProps {
  qcApproved: boolean;
  invoiceCreated: boolean;
  npsCompleted: boolean;
  orderClosed: boolean;
}

interface StepDef {
  label: string;
  done: boolean;
}

export function DeliveryProgress({
  qcApproved,
  invoiceCreated,
  npsCompleted,
  orderClosed,
}: DeliveryProgressProps) {
  const steps: StepDef[] = [
    { label: 'QC Aprobado', done: qcApproved },
    { label: 'Factura generada', done: invoiceCreated },
    { label: 'Encuesta NPS completada', done: npsCompleted },
    { label: 'Orden cerrada', done: orderClosed },
  ];

  return (
    <View style={styles.container}>
      <Text style={styles.sectionTitle}>Progreso de Entrega</Text>
      {steps.map((step, i) => (
        <View key={step.label} style={styles.stepRow}>
          {/* Vertical connector */}
          <View style={styles.stepIndicator}>
            <View
              style={[
                styles.circle,
                step.done ? styles.circleDone : styles.circlePending,
              ]}
            >
              {step.done && <Ionicons name="checkmark" size={16} color={Semantic.onPrimary} />}
            </View>
            {i < steps.length - 1 && (
              <View
                style={[
                  styles.line,
                  steps[i + 1].done || step.done
                    ? styles.lineDone
                    : styles.linePending,
                ]}
              />
            )}
          </View>
          <Text style={[styles.stepLabel, step.done && styles.stepLabelDone]}>
            {step.label}
          </Text>
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: Semantic.surface,
    borderRadius: Radius.lg,
    marginHorizontal: Spacing.md,
    marginTop: Spacing.md,
    padding: Spacing.md,
    borderTopWidth: 1,
    borderLeftWidth: 1,
    borderTopColor: Semantic.borderLight,
    borderLeftColor: Semantic.borderLight,
    ...Shadows.extruded,
  },
  sectionTitle: {
    fontSize: TypeScale.subtitle,
    fontWeight: '700',
    color: Semantic.onSurface,
    marginBottom: Spacing.md,
  },
  stepRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    minHeight: 48,
  },
  stepIndicator: {
    alignItems: 'center',
    width: 32,
    marginRight: Spacing.sm,
  },
  circle: {
    width: 28,
    height: 28,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
  },
  circleDone: {
    backgroundColor: Semantic.primary,
    borderColor: Semantic.primary,
  },
  circlePending: {
    backgroundColor: Semantic.surfaceElevated,
    borderColor: Semantic.border,
  },
  check: {
    color: Semantic.onPrimary,
    fontSize: 14,
    fontWeight: '700',
  },
  line: {
    width: 2,
    flex: 1,
    minHeight: 20,
  },
  lineDone: {
    backgroundColor: Semantic.primary,
  },
  linePending: {
    backgroundColor: Semantic.border,
  },
  stepLabel: {
    fontSize: TypeScale.body,
    color: Semantic.secondary,
    paddingTop: 4,
    flexShrink: 1,
  },
  stepLabelDone: {
    color: Semantic.onSurface,
    fontWeight: '600',
  },
});
