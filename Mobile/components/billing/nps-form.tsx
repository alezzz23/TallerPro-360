import { useCallback, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';

import { Radius, Semantic, Shadows, Spacing, TypeScale } from '@/constants/theme';
import { NPS_CATEGORIES } from '@/schemas/billing';
import { useCreateNPS } from '@/hooks/use-billing';

interface NPSFormProps {
  orderId: string;
}

function npsColor(val: number): string {
  if (val >= 9) return Semantic.primary;
  if (val >= 7) return '#EAB308';
  return '#EF4444';
}

export function NPSForm({ orderId }: NPSFormProps) {
  const [ratings, setRatings] = useState<Record<string, number>>({});
  const [comentarios, setComentarios] = useState('');
  const createNPS = useCreateNPS();

  const setRating = useCallback((key: string, value: number) => {
    setRatings((prev) => ({ ...prev, [key]: value }));
  }, []);

  const allFilled = NPS_CATEGORIES.every((c) => ratings[c.key] != null);

  const handleSubmit = useCallback(() => {
    if (!allFilled) {
      Alert.alert('Encuesta incompleta', 'Seleccione una calificación para cada categoría.');
      return;
    }

    Alert.alert('Enviar Encuesta', '¿Confirma las calificaciones?', [
      { text: 'Cancelar', style: 'cancel' },
      {
        text: 'Enviar',
        onPress: async () => {
          try {
            await createNPS.mutateAsync({
              orderId,
              data: {
                atencion: ratings.atencion,
                instalaciones: ratings.instalaciones,
                tiempos: ratings.tiempos,
                precios: ratings.precios,
                recomendacion: ratings.recomendacion,
                comentarios: comentarios.trim() || undefined,
              },
            });
            Alert.alert('Encuesta enviada', 'Gracias por sus respuestas.');
          } catch (e: any) {
            Alert.alert('Error', e?.response?.data?.detail ?? 'No se pudo enviar la encuesta.');
          }
        },
      },
    ]);
  }, [allFilled, ratings, comentarios, orderId, createNPS]);

  return (
    <View style={styles.container}>
      <Text style={styles.sectionTitle}>Encuesta de Satisfacción (NPS)</Text>

      {NPS_CATEGORIES.map((cat) => {
        const selected = ratings[cat.key];
        return (
          <View key={cat.key} style={styles.categoryBlock}>
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
              <Ionicons name={cat.icon as any} size={16} color={Semantic.secondary} />
              <Text style={styles.catLabel}>{cat.label}</Text>
            </View>
            <View style={styles.ratingRow}>
              {Array.from({ length: 10 }, (_, i) => i + 1).map((n) => {
                const isActive = selected === n;
                const color = npsColor(n);
                return (
                  <Pressable
                    key={n}
                    style={[
                      styles.ratingCircle,
                      isActive && { backgroundColor: color, borderColor: color },
                    ]}
                    onPress={() => setRating(cat.key, n)}
                  >
                    <Text
                      style={[
                        styles.ratingNum,
                        isActive && styles.ratingNumActive,
                      ]}
                    >
                      {n}
                    </Text>
                  </Pressable>
                );
              })}
            </View>
          </View>
        );
      })}

      {/* Comentarios */}
      <Text style={styles.fieldLabel}>Comentarios (opcional)</Text>
      <TextInput
        style={styles.textArea}
        multiline
        numberOfLines={3}
        placeholder="¿Algún comentario adicional?"
        placeholderTextColor="#9E9E9E"
        value={comentarios}
        onChangeText={setComentarios}
      />

      {/* Submit */}
      <Pressable
        style={[styles.submitBtn, (!allFilled || createNPS.isPending) && styles.btnDisabled]}
        onPress={handleSubmit}
        disabled={!allFilled || createNPS.isPending}
      >
        {createNPS.isPending ? (
          <ActivityIndicator color="#fff" size="small" />
        ) : (
          <Text style={styles.submitText}>Enviar Encuesta</Text>
        )}
      </Pressable>
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
  categoryBlock: {
    marginBottom: Spacing.md,
  },
  catLabel: {
    fontSize: TypeScale.label,
    fontWeight: '600',
    color: Semantic.onSurface,
  },
  ratingRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: Spacing.sm,
  },
  ratingCircle: {
    width: 30,
    height: 30,
    borderRadius: 15,
    borderWidth: 2,
    borderColor: Semantic.border,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Semantic.surfaceElevated,
  },
  ratingNum: {
    fontSize: TypeScale.caption,
    fontWeight: '700',
    color: Semantic.secondary,
  },
  ratingNumActive: {
    color: '#fff',
  },
  fieldLabel: {
    fontSize: TypeScale.label,
    fontWeight: '600',
    color: Semantic.secondary,
    marginBottom: Spacing.sm,
  },
  textArea: {
    backgroundColor: Semantic.surfaceElevated,
    borderWidth: 1,
    borderColor: Semantic.border,
    borderRadius: Radius.md,
    padding: Spacing.sm,
    fontSize: TypeScale.body,
    color: Semantic.onSurface,
    minHeight: 80,
    textAlignVertical: 'top',
    marginBottom: Spacing.md,
  },
  submitBtn: {
    backgroundColor: Semantic.primary,
    borderRadius: Radius.pill,
    paddingVertical: 14,
    alignItems: 'center',
    ...Shadows.extruded,
  },
  btnDisabled: {
    opacity: 0.5,
  },
  submitText: {
    color: Semantic.onPrimary,
    fontSize: TypeScale.body,
    fontWeight: '700',
  },
});
