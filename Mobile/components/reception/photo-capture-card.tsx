import { Image, Pressable, StyleSheet, Text, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

import { Radius, Semantic, Shadows, Spacing, TypeScale } from '@/constants/theme';
import type { AnguloFoto } from '@/types/api';

const ANGLE_LABELS: Record<AnguloFoto, string> = {
  FRONTAL: 'Frontal',
  TRASERO: 'Trasero',
  IZQUIERDO: 'Izquierdo',
  DERECHO: 'Derecho',
};

const ANGLE_ICONS: Record<AnguloFoto, keyof typeof Ionicons.glyphMap> = {
  FRONTAL: 'arrow-up',
  TRASERO: 'arrow-down',
  IZQUIERDO: 'arrow-back',
  DERECHO: 'arrow-forward',
};

interface Props {
  angulo: AnguloFoto;
  photoUri: string | null;
  onCapture: () => void;
  isUploading: boolean;
}

export function PhotoCaptureCard({ angulo, photoUri, onCapture, isUploading }: Props) {
  return (
    <View style={styles.container}>
      <Pressable
        style={({ pressed }) => [
          styles.card,
          photoUri ? styles.cardCaptured : styles.cardEmpty,
          pressed && styles.cardPressed,
        ]}
        onPress={onCapture}
        disabled={isUploading}
      >
        {photoUri ? (
          <Image source={{ uri: photoUri }} style={styles.image} resizeMode="cover" />
        ) : (
          <View style={styles.placeholder}>
            <Ionicons name={ANGLE_ICONS[angulo]} size={28} color={Semantic.textMuted} />
            <Text style={styles.placeholderText}>
              {isUploading ? 'Subiendo…' : 'Tomar foto'}
            </Text>
          </View>
        )}

        {photoUri && (
          <View style={styles.checkOverlay}>
            <Ionicons name="checkmark" size={16} color={Semantic.onPrimary} />
          </View>
        )}
      </Pressable>

      <Text style={[styles.label, photoUri ? styles.labelDone : null]}>
        {ANGLE_LABELS[angulo]}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { width: '47%', alignItems: 'center', marginBottom: Spacing.md },
  card: {
    width: '100%',
    aspectRatio: 4 / 3,
    borderRadius: Radius.lg,
    overflow: 'hidden',
    borderWidth: 2,
  },
  cardEmpty: {
    borderColor: Semantic.border,
    borderStyle: 'dashed',
    backgroundColor: Semantic.surfaceElevated,
  },
  cardCaptured: {
    borderColor: Semantic.primary,
    borderStyle: 'solid',
  },
  cardPressed: {
    opacity: 0.8,
    transform: [{ scale: 0.97 }],
  },
  image: { width: '100%', height: '100%' },
  placeholder: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: Spacing.xs,
  },
  icon: { fontSize: 28, color: Semantic.textMuted },
  placeholderText: {
    fontSize: TypeScale.caption,
    color: Semantic.secondary,
    fontWeight: '600',
  },
  checkOverlay: {
    position: 'absolute',
    top: 8,
    right: 8,
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: Semantic.primary,
    alignItems: 'center',
    justifyContent: 'center',
    ...Shadows.soft,
  },
  checkText: { color: Semantic.onPrimary, fontSize: 16, fontWeight: '700' },
  label: {
    marginTop: Spacing.xs,
    fontSize: TypeScale.label,
    fontWeight: '600',
    color: Semantic.onSurface,
  },
  labelDone: { color: Semantic.primary },
});
