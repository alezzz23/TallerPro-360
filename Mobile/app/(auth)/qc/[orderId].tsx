import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

import { useOrder, useVehicle } from '@/hooks/use-orders';
import { useOrderQuotation } from '@/hooks/use-quotations';
import { useQC, useReceptionChecklist, useCreateQC, useApproveQC } from '@/hooks/use-qc';
import { useAuthStore } from '@/stores/auth-store';
import { QCChecklist } from '@/components/qc/qc-checklist';
import { FluidsComparison } from '@/components/qc/fluids-comparison';
import { Semantic, Shadows, Radius, Spacing, StatusColors, TypeScale } from '@/constants/theme';
import type { FluidLevel } from '@/schemas/qc';

export default function QCFormScreen() {
  const { orderId } = useLocalSearchParams<{ orderId: string }>();
  const router = useRouter();
  const user = useAuthStore((s) => s.user);

  const { data: order } = useOrder(orderId);
  const { data: vehicle } = useVehicle(order?.vehicle_id ?? '');
  const { data: quotation } = useOrderQuotation(orderId);
  const { data: existingQC, isLoading: qcLoading } = useQC(orderId);
  const { data: checklist } = useReceptionChecklist(orderId);

  const createQC = useCreateQC();
  const approveQCMut = useApproveQC();

  const approvedItems = useMemo(
    () => quotation?.items ?? [],
    [quotation],
  );

  // ── Form state ─────────────────────────────────────────
  const [itemsVerificados, setItemsVerificados] = useState<Record<string, boolean>>({});
  const [kmSalida, setKmSalida] = useState<number | null>(null);
  const [nivelAceiteSalida, setNivelAceiteSalida] = useState<string | null>(null);
  const [nivelRefrigeranteSalida, setNivelRefrigeranteSalida] = useState<string | null>(null);
  const [nivelFrenosSalida, setNivelFrenosSalida] = useState<string | null>(null);

  // Seed form from existing QC
  useEffect(() => {
    if (existingQC) {
      setItemsVerificados(existingQC.items_verificados);
      setKmSalida(existingQC.kilometraje_salida);
      setNivelAceiteSalida(existingQC.nivel_aceite_salida);
      setNivelRefrigeranteSalida(existingQC.nivel_refrigerante_salida);
      setNivelFrenosSalida(existingQC.nivel_frenos_salida);
    }
  }, [existingQC]);

  const isApproved = existingQC?.aprobado === true;
  const isJefe = user?.rol === 'JEFE_TALLER' || user?.rol === 'ADMIN';
  const readOnly = isApproved;

  const handleToggle = useCallback((key: string, value: boolean) => {
    setItemsVerificados((prev) => ({ ...prev, [key]: value }));
  }, []);

  const handleSave = useCallback(async () => {
    if (!user) return;
    try {
      await createQC.mutateAsync({
        orderId,
        data: {
          inspector_id: user.id,
          items_verificados: itemsVerificados,
          kilometraje_salida: kmSalida,
          nivel_aceite_salida: nivelAceiteSalida,
          nivel_refrigerante_salida: nivelRefrigeranteSalida,
          nivel_frenos_salida: nivelFrenosSalida,
          aprobado: false,
        },
      });
      Alert.alert('QC guardado', 'El control de calidad fue guardado exitosamente.');
    } catch (e: any) {
      Alert.alert('Error', e?.response?.data?.detail ?? 'No se pudo guardar el QC.');
    }
  }, [orderId, user, itemsVerificados, kmSalida, nivelAceiteSalida, nivelRefrigeranteSalida, nivelFrenosSalida, createQC]);

  const handleApprove = useCallback(() => {
    Alert.alert(
      'Aprobar QC',
      '¿Confirma la aprobación del control de calidad? La orden pasará a estado ENTREGA.',
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Aprobar',
          style: 'default',
          onPress: async () => {
            try {
              // Save first, then approve
              if (user) {
                await createQC.mutateAsync({
                  orderId,
                  data: {
                    inspector_id: user.id,
                    items_verificados: itemsVerificados,
                    kilometraje_salida: kmSalida,
                    nivel_aceite_salida: nivelAceiteSalida,
                    nivel_refrigerante_salida: nivelRefrigeranteSalida,
                    nivel_frenos_salida: nivelFrenosSalida,
                    aprobado: false,
                  },
                });
              }
              await approveQCMut.mutateAsync(orderId);
              Alert.alert('Aprobado', 'La orden fue aprobada y pasó a ENTREGA.');
              router.back();
            } catch (e: any) {
              Alert.alert('Error', e?.response?.data?.detail ?? 'No se pudo aprobar.');
            }
          },
        },
      ],
    );
  }, [orderId, user, itemsVerificados, kmSalida, nivelAceiteSalida, nivelRefrigeranteSalida, nivelFrenosSalida, createQC, approveQCMut, router]);

  if (qcLoading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={Semantic.primary} />
      </View>
    );
  }

  const isBusy = createQC.isPending || approveQCMut.isPending;

  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.scroll}>
        {/* Vehicle header */}
        {vehicle && (
          <View style={styles.vehicleHeader}>
            <Text style={styles.placa}>{vehicle.placa}</Text>
            <Text style={styles.vehicleInfo}>
              {vehicle.marca} {vehicle.modelo}
              {vehicle.color ? ` · ${vehicle.color}` : ''}
            </Text>
            {order?.motivo_ingreso ? (
              <Text style={styles.motivo}>{order.motivo_ingreso}</Text>
            ) : null}
          </View>
        )}

        {/* Approved badge */}
        {isApproved && (
          <View style={styles.approvedBanner}>
            <Ionicons name="checkmark-circle" size={24} color="#FFFFFF" />
            <Text style={styles.approvedBannerText}>QC Aprobado</Text>
          </View>
        )}

        {/* QC Checklist */}
        <QCChecklist
          items={approvedItems}
          checked={itemsVerificados}
          onToggle={handleToggle}
          readOnly={readOnly}
        />

        {/* Fluids comparison */}
        <FluidsComparison
          checklist={checklist}
          kmIngreso={order?.kilometraje_ingreso}
          kmSalida={kmSalida}
          nivelAceiteSalida={nivelAceiteSalida}
          nivelRefrigeranteSalida={nivelRefrigeranteSalida}
          nivelFrenosSalida={nivelFrenosSalida}
          onChangeKmSalida={setKmSalida}
          onChangeAceite={(v: FluidLevel) => setNivelAceiteSalida(v)}
          onChangeRefrigerante={(v: FluidLevel) => setNivelRefrigeranteSalida(v)}
          onChangeFrenos={(v: FluidLevel) => setNivelFrenosSalida(v)}
          readOnly={readOnly}
        />

        {/* Spacer for buttons */}
        <View style={{ height: 120 }} />
      </ScrollView>

      {/* Action buttons */}
      {!readOnly && (
        <View style={styles.buttonRow}>
          <Pressable
            style={[styles.btn, styles.btnSave, isBusy && styles.btnDisabled]}
            onPress={handleSave}
            disabled={isBusy}
          >
            {createQC.isPending ? (
              <ActivityIndicator color={Semantic.onSurface} size="small" />
            ) : (
              <Text style={[styles.btnText, { color: Semantic.onSurface }]}>Guardar QC</Text>
            )}
          </Pressable>

          {isJefe && (
            <Pressable
              style={[styles.btn, styles.btnApprove, isBusy && styles.btnDisabled]}
              onPress={handleApprove}
              disabled={isBusy}
            >
              {approveQCMut.isPending ? (
                <ActivityIndicator color="#fff" size="small" />
              ) : (
                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
                <Ionicons name="checkmark" size={18} color={Semantic.onPrimary} />
                <Text style={styles.btnText}>Aprobar QC</Text>
              </View>
              )}
            </Pressable>
          )}
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Semantic.background,
  },
  scroll: {
    paddingBottom: Spacing.xxl,
  },
  center: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: Semantic.background,
  },
  vehicleHeader: {
    backgroundColor: Semantic.surface,
    padding: Spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: Semantic.borderLight,
    borderTopWidth: 1,
    borderTopColor: Semantic.borderLight,
    borderLeftWidth: 1,
    borderLeftColor: Semantic.borderLight,
    ...Shadows.extruded,
  },
  placa: {
    fontSize: TypeScale.title,
    fontWeight: '800',
    color: Semantic.onSurface,
  },
  vehicleInfo: {
    fontSize: TypeScale.label,
    color: Semantic.secondary,
    marginTop: 2,
  },
  motivo: {
    fontSize: TypeScale.label,
    color: Semantic.textMuted,
    marginTop: Spacing.xs,
    fontWeight: '500',
  },
  approvedBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#052E16',
    paddingVertical: Spacing.sm,
    marginHorizontal: Spacing.md,
    marginTop: Spacing.md,
    borderRadius: Radius.lg,
    borderWidth: 1,
    borderColor: Semantic.primary,
    gap: Spacing.sm,
    ...Shadows.soft,
  },
  approvedBannerText: {
    fontSize: TypeScale.subtitle,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  buttonRow: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    padding: Spacing.md,
    paddingBottom: Spacing.lg,
    backgroundColor: Semantic.surface,
    borderTopWidth: 1,
    borderTopColor: Semantic.borderLight,
    gap: Spacing.sm,
  },
  btn: {
    paddingVertical: Spacing.md,
    borderRadius: Radius.pill,
    alignItems: 'center',
    ...Shadows.extruded,
  },
  btnSave: {
    backgroundColor: Semantic.surface,
    borderWidth: 1,
    borderColor: Semantic.border,
    ...Shadows.soft,
  },
  btnApprove: {
    backgroundColor: Semantic.primary,
  },
  btnDisabled: {
    opacity: 0.6,
  },
  btnText: {
    color: Semantic.onPrimary,
    fontSize: TypeScale.body,
    fontWeight: '700',
  },
});
