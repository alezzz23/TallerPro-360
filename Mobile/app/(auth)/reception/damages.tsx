import { Alert, Pressable, ScrollView, StyleSheet, Text } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';

import { ThemedView } from '@/components/themed-view';
import { StepIndicator } from '@/components/reception/step-indicator';
import { DamageZoneGrid } from '@/components/reception/damage-zone-grid';
import { Semantic, Shadows, Radius, Spacing, StatusColors, TypeScale } from '@/constants/theme';
import { useAddDamage, useDamages } from '@/hooks/use-reception';

const STEP_LABELS = ['Vehículo', 'Checklist', 'Daños', 'Fotos', 'Firma'];

export default function DamagesScreen() {
  const { orderId } = useLocalSearchParams<{ orderId: string }>();
  const router = useRouter();
  const { data: damages = [] } = useDamages(orderId ?? '');
  const addDamage = useAddDamage();

  const handleAddDamage = async (ubicacion: string, descripcion: string) => {
    if (!orderId) return;
    try {
      await addDamage.mutateAsync({
        orderId,
        data: {
          ubicacion,
          descripcion: descripcion || undefined,
          reconocido_por_cliente: true,
        },
      });
    } catch (e: any) {
      Alert.alert(
        'Error',
        e?.response?.data?.detail ?? 'No se pudo registrar el daño',
      );
    }
  };

  const handleContinue = () => {
    router.push({
      pathname: '/(auth)/reception/photos',
      params: { orderId },
    });
  };

  return (
    <ThemedView style={styles.container}>
      <ScrollView
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator={false}
      >
        <StepIndicator current={3} total={5} labels={STEP_LABELS} />

        <DamageZoneGrid
          damages={damages}
          onAddDamage={handleAddDamage}
          isAdding={addDamage.isPending}
        />

        <Pressable
          style={({ pressed }) => [
            styles.continueBtn,
            pressed && styles.continueBtnPressed,
          ]}
          onPress={handleContinue}
        >
          <Text style={styles.continueText}>
            {damages.length === 0
              ? 'Sin daños — Continuar'
              : 'Continuar →'}
          </Text>
        </Pressable>
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
  continueBtn: {
    backgroundColor: Semantic.primary,
    paddingVertical: 16,
    borderRadius: Radius.pill,
    alignItems: 'center',
    marginTop: Spacing.lg,
    ...Shadows.extruded,
  },
  continueBtnPressed: { ...Shadows.none, backgroundColor: '#111111', transform: [{ scale: 0.97 }] },
  continueText: {
    color: Semantic.onPrimary,
    fontSize: TypeScale.body,
    fontWeight: '700',
  },
});
