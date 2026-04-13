import { useState } from 'react';
import {
  Alert,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { useRouter } from 'expo-router';
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';

import { ThemedView } from '@/components/themed-view';
import { StepIndicator } from '@/components/reception/step-indicator';
import { VehicleSearchInput } from '@/components/reception/vehicle-search-input';
import { Semantic, Shadows, Radius, Spacing, StatusColors, TypeScale } from '@/constants/theme';
import { vehicleSearchSchema, type VehicleSearchFormData } from '@/schemas/reception';
import { useAuthStore } from '@/stores/auth-store';
import { useCreateOrder } from '@/hooks/use-reception';
import type { Vehicle } from '@/types/api';

const STEP_LABELS = ['Vehículo', 'Checklist', 'Daños', 'Fotos', 'Firma'];

export default function VehicleSearchScreen() {
  const router = useRouter();
  const user = useAuthStore((s) => s.user);
  const createOrder = useCreateOrder();
  const [selectedVehicle, setSelectedVehicle] = useState<Vehicle | null>(null);

  const {
    control,
    handleSubmit,
    setValue,
    formState: { errors },
  } = useForm<VehicleSearchFormData>({
    resolver: zodResolver(vehicleSearchSchema),
    defaultValues: {
      vehicle_id: '',
      kilometraje_ingreso: undefined,
      motivo_ingreso: '',
    },
  });

  const handleVehicleSelect = (vehicle: Vehicle) => {
    setSelectedVehicle(vehicle);
    setValue('vehicle_id', vehicle?.id ?? '', { shouldValidate: true });
  };

  const onSubmit = async (data: VehicleSearchFormData) => {
    if (!user) return;
    try {
      const order = await createOrder.mutateAsync({
        vehicle_id: data.vehicle_id,
        advisor_id: user.id,
        kilometraje_ingreso: data.kilometraje_ingreso,
        motivo_ingreso: data.motivo_ingreso,
      });
      router.push({
        pathname: '/(auth)/reception/checklist',
        params: { orderId: order.id },
      });
    } catch (e: any) {
      Alert.alert(
        'Error',
        e?.response?.data?.detail ?? 'No se pudo crear la orden',
      );
    }
  };

  return (
    <ThemedView style={styles.container}>
      <KeyboardAvoidingView
        style={styles.flex}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <ScrollView
          style={styles.flex}
          contentContainerStyle={styles.content}
          keyboardShouldPersistTaps="handled"
        >
          <StepIndicator current={1} total={5} labels={STEP_LABELS} />

          <VehicleSearchInput
            onSelect={handleVehicleSelect}
            selectedVehicle={selectedVehicle}
          />

          {errors.vehicle_id && (
            <Text style={styles.error}>{errors.vehicle_id.message}</Text>
          )}

          {/* Kilometraje */}
          <View style={styles.field}>
            <Text style={styles.label}>Kilometraje de ingreso</Text>
            <Controller
              control={control}
              name="kilometraje_ingreso"
              render={({ field: { onChange, value } }) => (
                <TextInput
                  style={styles.input}
                  placeholder="Ej: 45000"
                  placeholderTextColor={Semantic.textMuted}
                  keyboardType="numeric"
                  value={value != null ? String(value) : ''}
                  onChangeText={(t) => {
                    const n = parseInt(t, 10);
                    onChange(isNaN(n) ? undefined : n);
                  }}
                />
              )}
            />
            {errors.kilometraje_ingreso && (
              <Text style={styles.error}>{errors.kilometraje_ingreso.message}</Text>
            )}
          </View>

          {/* Motivo de ingreso */}
          <View style={styles.field}>
            <Text style={styles.label}>Motivo de ingreso</Text>
            <Controller
              control={control}
              name="motivo_ingreso"
              render={({ field: { onChange, onBlur, value } }) => (
                <TextInput
                  style={[styles.input, styles.textArea]}
                  placeholder="Describa el motivo del ingreso…"
                  placeholderTextColor={Semantic.textMuted}
                  multiline
                  numberOfLines={3}
                  textAlignVertical="top"
                  value={value}
                  onBlur={onBlur}
                  onChangeText={onChange}
                />
              )}
            />
            {errors.motivo_ingreso && (
              <Text style={styles.error}>{errors.motivo_ingreso.message}</Text>
            )}
          </View>

          <Pressable
            style={({ pressed }) => [
              styles.submitBtn,
              pressed && styles.submitBtnPressed,
              createOrder.isPending && styles.submitBtnDisabled,
            ]}
            onPress={handleSubmit(onSubmit)}
            disabled={createOrder.isPending}
          >
            <Text style={styles.submitText}>
              {createOrder.isPending ? 'Creando orden…' : 'Crear Orden y Continuar'}
            </Text>
          </Pressable>
        </ScrollView>
      </KeyboardAvoidingView>
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  flex: { flex: 1 },
  content: {
    padding: Spacing.lg,
    paddingBottom: Spacing.xxl,
  },
  field: { marginBottom: Spacing.md },
  label: {
    fontSize: TypeScale.label,
    fontWeight: '600',
    color: Semantic.onSurface,
    marginBottom: Spacing.sm,
  },
  input: {
    borderWidth: 1,
    borderColor: Semantic.border,
    borderRadius: Radius.md,
    paddingHorizontal: Spacing.md,
    paddingVertical: 14,
    fontSize: TypeScale.body,
    backgroundColor: Semantic.surface,
    color: Semantic.onSurface,
  },
  textArea: { minHeight: 80 },
  error: {
    color: Semantic.danger,
    fontSize: TypeScale.caption,
    marginTop: Spacing.xs,
  },
  submitBtn: {
    backgroundColor: Semantic.primary,
    paddingVertical: 16,
    borderRadius: Radius.pill,
    alignItems: 'center',
    marginTop: Spacing.lg,
    ...Shadows.extruded,
  },
  submitBtnPressed: { ...Shadows.none, backgroundColor: '#111111', transform: [{ scale: 0.97 }] },
  submitBtnDisabled: { opacity: 0.5 },
  submitText: {
    color: Semantic.onPrimary,
    fontSize: TypeScale.body,
    fontWeight: '700',
  },
});
