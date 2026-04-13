import { Alert, ScrollView, StyleSheet } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';

import { ThemedView } from '@/components/themed-view';
import { StepIndicator } from '@/components/reception/step-indicator';
import { ChecklistForm } from '@/components/reception/checklist-form';
import { Spacing } from '@/constants/theme';
import { useSaveChecklist } from '@/hooks/use-reception';
import type { ChecklistFormData } from '@/schemas/reception';

const STEP_LABELS = ['Vehículo', 'Checklist', 'Daños', 'Fotos', 'Firma'];

export default function ChecklistScreen() {
  const { orderId } = useLocalSearchParams<{ orderId: string }>();
  const router = useRouter();
  const saveChecklist = useSaveChecklist();

  const handleSubmit = async (data: ChecklistFormData) => {
    if (!orderId) return;
    try {
      await saveChecklist.mutateAsync({
        orderId,
        data: {
          nivel_aceite: data.nivel_aceite,
          nivel_refrigerante: data.nivel_refrigerante,
          nivel_frenos: data.nivel_frenos,
          llanta_repuesto: data.llanta_repuesto,
          kit_carretera: data.kit_carretera,
          botiquin: data.botiquin,
          extintor: data.extintor,
          documentos_recibidos: data.documentos_recibidos,
        },
      });
      router.push({
        pathname: '/(auth)/reception/damages',
        params: { orderId },
      });
    } catch (e: any) {
      Alert.alert(
        'Error',
        e?.response?.data?.detail ?? 'No se pudo guardar el checklist',
      );
    }
  };

  return (
    <ThemedView style={styles.container}>
      <ScrollView
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator={false}
      >
        <StepIndicator current={2} total={5} labels={STEP_LABELS} />
        <ChecklistForm
          onSubmit={handleSubmit}
          isLoading={saveChecklist.isPending}
        />
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
});
