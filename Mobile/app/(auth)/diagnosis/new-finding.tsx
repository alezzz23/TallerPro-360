import { Alert } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';

import { FindingForm } from '@/components/diagnosis/finding-form';
import { useCreateFinding } from '@/hooks/use-diagnosis';
import { useAuthStore } from '@/stores/auth-store';
import { Semantic, Spacing } from '@/constants/theme';
import type { FindingFormData } from '@/schemas/diagnosis';
import { View, StyleSheet } from 'react-native';

export default function NewFindingScreen() {
  const { orderId, additional } = useLocalSearchParams<{
    orderId: string;
    additional: string;
  }>();
  const router = useRouter();
  const user = useAuthStore((s) => s.user);
  const createFinding = useCreateFinding();
  const isAdditional = additional === 'true';

  const handleSubmit = (data: FindingFormData) => {
    createFinding.mutate(
      {
        orderId,
        data: {
          technician_id: data.technician_id,
          motivo_ingreso: data.motivo_ingreso,
          descripcion: data.descripcion || undefined,
          tiempo_estimado: data.tiempo_estimado,
          es_hallazgo_adicional: data.es_hallazgo_adicional,
          es_critico_seguridad: data.es_critico_seguridad,
        },
      },
      {
        onSuccess: () => router.back(),
        onError: () => Alert.alert('Error', 'No se pudo crear el hallazgo'),
      },
    );
  };

  return (
    <View style={styles.container}>
      <FindingForm
        defaultValues={{
          technician_id: user?.id ?? '',
          es_hallazgo_adicional: isAdditional,
          es_critico_seguridad: false,
        }}
        onSubmit={handleSubmit}
        isPending={createFinding.isPending}
        submitLabel={isAdditional ? 'Reportar Hallazgo Adicional' : 'Crear Hallazgo'}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: Spacing.md,
    backgroundColor: Semantic.background,
  },
});
