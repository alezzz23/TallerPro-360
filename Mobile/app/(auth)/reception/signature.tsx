import { useState } from 'react';
import { Alert, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';

import { ThemedView } from '@/components/themed-view';
import { StepIndicator } from '@/components/reception/step-indicator';
import { SignaturePad } from '@/components/reception/signature-pad';
import { Semantic, Shadows, Radius, Spacing, TypeScale } from '@/constants/theme';
import { useSubmitSignature, useAdvanceOrder } from '@/hooks/use-reception';

const STEP_LABELS = ['Vehículo', 'Checklist', 'Daños', 'Fotos', 'Firma'];

export default function SignatureScreen() {
  const { orderId } = useLocalSearchParams<{ orderId: string }>();
  const router = useRouter();
  const submitSignature = useSubmitSignature();
  const advanceOrder = useAdvanceOrder();
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleConfirm = async (signed: boolean) => {
    if (!orderId || !signed) return;
    setIsSubmitting(true);

    try {
      // Submit a placeholder signature URL (in production, this would be an uploaded image)
      await submitSignature.mutateAsync({
        orderId,
        firmaUrl: `signatures/${orderId}_firma.png`,
      });

      // Advance order from RECEPCION to DIAGNOSTICO
      await advanceOrder.mutateAsync(orderId);

      Alert.alert(
        'Recepción completada',
        'La orden ha avanzado a Diagnóstico.',
        [
          {
            text: 'Ir al Dashboard',
            onPress: () => router.replace('/(auth)/(tabs)'),
          },
        ],
      );
    } catch (e: any) {
      Alert.alert(
        'Error',
        e?.response?.data?.detail ?? 'No se pudo completar la recepción',
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <ThemedView style={styles.container}>
      <ScrollView
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator={false}
      >
        <StepIndicator current={5} total={5} labels={STEP_LABELS} />

        <View style={styles.infoCard}>
          <Text style={styles.infoTitle}>Último paso</Text>
          <Text style={styles.infoText}>
            El cliente confirma que los datos registrados son correctos y
            autoriza el ingreso del vehículo al taller.
          </Text>
        </View>

        <SignaturePad onConfirm={handleConfirm} isSubmitting={isSubmitting} />
      </ScrollView>
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  content: {
    padding: Spacing.lg,
    paddingBottom: Spacing.xxl,
  },
  infoCard: {
    backgroundColor: Semantic.surface,
    borderRadius: Radius.lg,
    padding: Spacing.md,
    marginBottom: Spacing.lg,
    borderLeftWidth: 4,
    borderLeftColor: Semantic.info,
    borderTopWidth: 1,
    borderTopColor: Semantic.borderLight,
    ...Shadows.soft,
  },
  infoTitle: {
    fontSize: TypeScale.body,
    fontWeight: '700',
    color: Semantic.onSurface,
    marginBottom: Spacing.xs,
  },
  infoText: {
    fontSize: TypeScale.label,
    color: Semantic.secondary,
    lineHeight: 20,
  },
});
