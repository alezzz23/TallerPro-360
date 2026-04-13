import { useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  FlatList,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

import { FindingForm } from '@/components/diagnosis/finding-form';
import { PhotoGallery } from '@/components/diagnosis/photo-gallery';
import { PartForm } from '@/components/diagnosis/part-form';
import {
  useOrderFindings,
  useUpdateFinding,
  useAddFindingPhoto,
  useAddPart,
} from '@/hooks/use-diagnosis';
import { Semantic, Shadows, Radius, Spacing, StatusColors, TypeScale } from '@/constants/theme';
import type { FindingFormData, PartFormData } from '@/schemas/diagnosis';
import type { DiagnosticFinding, Part } from '@/types/api';

export default function FindingDetailScreen() {
  const { findingId, orderId } = useLocalSearchParams<{
    findingId: string;
    orderId: string;
  }>();

  const { data: findings, isLoading } = useOrderFindings(orderId);
  const finding = findings?.find((f) => f.id === findingId);

  const updateFinding = useUpdateFinding(orderId);
  const addPhoto = useAddFindingPhoto(orderId);
  const addPartMutation = useAddPart(orderId);

  const [showPartForm, setShowPartForm] = useState(false);

  if (isLoading || !finding) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={Semantic.primary} />
      </View>
    );
  }

  const handleUpdate = (data: FindingFormData) => {
    updateFinding.mutate(
      {
        findingId: finding.id,
        data: {
          technician_id: data.technician_id,
          descripcion: data.descripcion || undefined,
          tiempo_estimado: data.tiempo_estimado,
          es_critico_seguridad: data.es_critico_seguridad,
        },
      },
      {
        onSuccess: () => Alert.alert('✓', 'Hallazgo actualizado'),
        onError: () => Alert.alert('Error', 'No se pudo actualizar'),
      },
    );
  };

  const handlePhotoAdded = (url: string) => {
    addPhoto.mutate({ findingId: finding.id, fotoUrl: url });
  };

  const handleAddPart = (data: PartFormData) => {
    addPartMutation.mutate(
      {
        findingId: finding.id,
        data: {
          nombre: data.nombre,
          origen: data.origen,
          costo: data.costo,
          margen: data.margen,
          proveedor: data.proveedor || undefined,
        },
      },
      {
        onSuccess: () => setShowPartForm(false),
        onError: () => Alert.alert('Error', 'No se pudo agregar el repuesto'),
      },
    );
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      {/* Safety warning banner */}
      {finding.es_critico_seguridad && (
        <View style={styles.warningBanner}>
          <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
            <Ionicons name="warning" size={16} color="#FFFFFF" />
            <Text style={styles.warningText}>
              {finding.safety_warning ?? 'Hallazgo crítico de seguridad'}
            </Text>
          </View>
        </View>
      )}

      {/* Edit Form */}
      <FindingForm
        defaultValues={{
          motivo_ingreso: finding.motivo_ingreso,
          descripcion: finding.descripcion ?? '',
          tiempo_estimado: finding.tiempo_estimado ?? undefined,
          technician_id: finding.technician_id,
          es_hallazgo_adicional: finding.es_hallazgo_adicional,
          es_critico_seguridad: finding.es_critico_seguridad,
        }}
        lockMotivo
        onSubmit={handleUpdate}
        isPending={updateFinding.isPending}
        submitLabel="Actualizar Hallazgo"
      />

      {/* Photo Gallery */}
      <PhotoGallery photos={finding.fotos} onPhotoAdded={handlePhotoAdded} />

      {/* Parts Section */}
      <View style={styles.partsSection}>
        <View style={styles.partsHeader}>
          <Text style={styles.sectionTitle}>
            Repuestos ({finding.parts.length})
          </Text>
          {!showPartForm && (
            <Pressable
              style={styles.addPartBtn}
              onPress={() => setShowPartForm(true)}
            >
              <Text style={styles.addPartText}>+ Agregar</Text>
            </Pressable>
          )}
        </View>

        {finding.parts.map((p) => (
          <PartRow key={p.id} part={p} />
        ))}

        {finding.parts.length === 0 && !showPartForm && (
          <Text style={styles.emptyParts}>Sin repuestos registrados</Text>
        )}

        {showPartForm && (
          <PartForm
            onSubmit={handleAddPart}
            isPending={addPartMutation.isPending}
            onCancel={() => setShowPartForm(false)}
          />
        )}
      </View>
    </ScrollView>
  );
}

function PartRow({ part }: { part: Part }) {
  return (
    <View style={styles.partRow}>
      <View style={{ flex: 1 }}>
        <Text style={styles.partName}>{part.nombre}</Text>
        {part.proveedor && (
          <Text style={styles.partProvider}>{part.proveedor}</Text>
        )}
      </View>
      <View style={[styles.origenBadge, part.origen === 'PEDIDO' && styles.origenPedido]}>
        <Text style={styles.origenBadgeText}>{part.origen}</Text>
      </View>
      <Text style={styles.partPrice}>${part.precio_venta.toFixed(2)}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Semantic.background,
  },
  content: {
    padding: Spacing.md,
    paddingBottom: Spacing.xxl * 2,
  },
  center: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: Semantic.background,
  },
  warningBanner: {
    backgroundColor: '#7F1D1D',
    borderWidth: 1,
    borderColor: Semantic.danger,
    borderRadius: Radius.lg,
    padding: Spacing.md,
    marginBottom: Spacing.md,
    ...Shadows.soft,
  },
  warningText: {
    color: '#FFFFFF',
    fontSize: TypeScale.body,
    fontWeight: '700',
    textAlign: 'center',
  },
  partsSection: {
    marginTop: Spacing.lg,
  },
  partsHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: Spacing.sm,
  },
  sectionTitle: {
    fontSize: TypeScale.subtitle,
    fontWeight: '700',
    color: Semantic.onSurface,
  },
  addPartBtn: {
    backgroundColor: Semantic.primary,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    borderRadius: Radius.pill,
    ...Shadows.extruded,
  },
  addPartText: {
    color: Semantic.onPrimary,
    fontWeight: '700',
    fontSize: TypeScale.label,
  },
  emptyParts: {
    fontSize: TypeScale.label,
    color: Semantic.textMuted,
    textAlign: 'center',
    paddingVertical: Spacing.lg,
  },
  partRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Semantic.surface,
    padding: Spacing.sm + 4,
    borderRadius: Radius.lg,
    marginBottom: Spacing.xs,
    gap: Spacing.sm,
    borderTopWidth: 1,
    borderLeftWidth: 1,
    borderTopColor: Semantic.borderLight,
    borderLeftColor: Semantic.borderLight,
    ...Shadows.extruded,
  },
  partName: {
    fontSize: TypeScale.body,
    fontWeight: '600',
    color: Semantic.onSurface,
  },
  partProvider: {
    fontSize: TypeScale.caption,
    color: Semantic.secondary,
    marginTop: 1,
  },
  origenBadge: {
    backgroundColor: Semantic.primaryMuted,
    paddingHorizontal: Spacing.sm,
    paddingVertical: 2,
    borderRadius: 6,
  },
  origenPedido: {
    backgroundColor: '#422006',
  },
  origenBadgeText: {
    fontSize: TypeScale.caption,
    fontWeight: '700',
    color: Semantic.onSurface,
  },
  partPrice: {
    fontSize: TypeScale.body,
    fontWeight: '700',
    color: Semantic.primary,
    minWidth: 70,
    textAlign: 'right',
  },
});
